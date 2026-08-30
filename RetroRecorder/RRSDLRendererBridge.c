#include "RRSDLRendererBridge.h"

#include <SDL3/SDL.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

enum {
    RR_AUDIO_TEXTURE_WIDTH = 512,
    RR_AUDIO_TEXTURE_HEIGHT = 2,
    RR_AUDIO_TEXTURE_BYTE_COUNT = RR_AUDIO_TEXTURE_WIDTH * RR_AUDIO_TEXTURE_HEIGHT
};

typedef struct RRFrameUniforms {
    float resolution[2];
    float time;
    float energy;
} RRFrameUniforms;

struct RRSDLRenderer {
    SDL_GPUDevice *device;
    SDL_GPUGraphicsPipeline *pipeline;
    SDL_GPUTexture *texture;
    SDL_GPUTexture *audio_texture;
    SDL_GPUSampler *audio_sampler;
    SDL_GPUTransferBuffer *audio_upload_buffer;
    SDL_GPUTransferBuffer *download_buffer;
    uint32_t width;
    uint32_t height;
    char last_error[256];
};

static const char rr_sdl_shader_source[] =
    "#include <metal_stdlib>\n"
    "using namespace metal;\n"
    "struct VertexOut { float4 position [[position]]; };\n"
    "struct FrameUniforms { float2 resolution; float time; float energy; };\n"
    "vertex VertexOut soundCircleVertex(uint vertexID [[vertex_id]]) {\n"
    "  const float2 positions[3] = {float2(-1.0,-1.0),float2(3.0,-1.0),float2(-1.0,3.0)};\n"
    "  VertexOut out; out.position=float4(positions[vertexID],0.0,1.0); return out;\n"
    "}\n"
    "inline float hash11(float value) { value=fract(value*0.1031); value*=value+33.33; value*=value+value; return fract(value); }\n"
    "inline float spectrumAt(texture2d<float> audio, sampler audioSampler, float progress) { return audio.sample(audioSampler,float2(clamp(progress,0.001,0.999),0.25)).r; }\n"
    "inline float waveformAt(texture2d<float> audio, sampler audioSampler, float progress) { return audio.sample(audioSampler,float2(clamp(progress,0.001,0.999),0.75)).r*2.0-1.0; }\n"
    "fragment float4 soundCircleFragment(VertexOut input [[stage_in]], constant FrameUniforms &u [[buffer(0)]], texture2d<float> audio [[texture(0)]], sampler audioSampler [[sampler(0)]]) {\n"
    "  constexpr float tau=6.28318530718; float2 resolution=max(u.resolution,float2(1.0));\n"
    "  float2 uv=(2.0*input.position.xy-resolution)/min(resolution.x,resolution.y);\n"
    "  float radius=length(uv); float angle=atan2(uv.y,uv.x); float around=fract(angle/tau+0.5);\n"
    "  float mirrored=abs(around*2.0-1.0); float frequency=pow(clamp(mirrored,0.0,1.0),2.05)*0.72;\n"
    "  float fft=spectrumAt(audio,audioSampler,frequency); float neighbour=max(spectrumAt(audio,audioSampler,frequency+0.004),spectrumAt(audio,audioSampler,frequency-0.004)); fft=max(fft,neighbour*0.88);\n"
    "  float wave=waveformAt(audio,audioSampler,around); float ripple=sin(angle*96.0+u.time*1.8)*fft*0.008;\n"
    "  float targetRadius=0.39+fft*0.25+wave*(0.012+fft*0.025)+ripple; float distanceToRing=abs(radius-targetRadius);\n"
    "  float pixel=1.0/min(resolution.x,resolution.y); float core=1.0-smoothstep(pixel*0.7,pixel*2.0,distanceToRing);\n"
    "  float halo=0.005/(distanceToRing+0.005); halo*=halo;\n"
    "  float3 phase=float3(0.0,0.34,0.67); float3 ringColor=0.55+0.45*cos(tau*(around+phase));\n"
    "  ringColor=mix(float3(0.12,0.72,1.0),ringColor,0.62); ringColor*=0.48+fft*1.75;\n"
    "  float guideDistance=abs(radius-0.39); float guide=1.0-smoothstep(pixel*0.5,pixel*1.5,guideDistance);\n"
    "  float innerPulseDistance=abs(radius-(0.33+u.energy*0.025)); float innerPulse=0.0025/(innerPulseDistance+0.0025); innerPulse*=innerPulse;\n"
    "  float vignette=1.0-smoothstep(0.75,1.45,radius); float3 color=float3(0.001,0.003,0.008);\n"
    "  color+=ringColor*(core*1.45+halo*(0.14+fft*0.78)); color+=float3(0.18,0.42,0.56)*guide*0.34; color+=ringColor*innerPulse*u.energy*0.12; color*=vignette;\n"
    "  float grainSeed=input.position.x+input.position.y*resolution.x+floor(u.time*60.0); color+=(hash11(grainSeed)-0.5)*0.006;\n"
    "  return float4(max(color,float3(0.0)),1.0);\n"
    "}\n";

static void rr_set_error(RRSDLRenderer *renderer, const char *operation) {
    if (renderer == NULL) {
        return;
    }
    const char *detail = SDL_GetError();
    snprintf(renderer->last_error, sizeof(renderer->last_error), "%s: %s", operation, detail != NULL ? detail : "unknown error");
}

static SDL_GPUShader *rr_create_shader(
    RRSDLRenderer *renderer,
    const char *entrypoint,
    SDL_GPUShaderStage stage,
    uint32_t uniform_count
) {
    SDL_GPUShaderCreateInfo info;
    SDL_zero(info);
    info.code_size = sizeof(rr_sdl_shader_source);
    info.code = (const Uint8 *)rr_sdl_shader_source;
    info.entrypoint = entrypoint;
    info.format = SDL_GPU_SHADERFORMAT_MSL;
    info.stage = stage;
    info.num_samplers = stage == SDL_GPU_SHADERSTAGE_FRAGMENT ? 1 : 0;
    info.num_uniform_buffers = uniform_count;
    SDL_GPUShader *shader = SDL_CreateGPUShader(renderer->device, &info);
    if (shader == NULL) {
        rr_set_error(renderer, "SDL_CreateGPUShader");
    }
    return shader;
}

RRSDLRenderer *RRSDLRendererCreate(uint32_t width, uint32_t height) {
    if (width == 0 || height == 0) {
        return NULL;
    }

    RRSDLRenderer *renderer = calloc(1, sizeof(RRSDLRenderer));
    if (renderer == NULL) {
        return NULL;
    }
    renderer->width = width;
    renderer->height = height;

    renderer->device = SDL_CreateGPUDevice(SDL_GPU_SHADERFORMAT_MSL, false, "metal");
    if (renderer->device == NULL) {
        rr_set_error(renderer, "SDL_CreateGPUDevice");
        RRSDLRendererDestroy(renderer);
        return NULL;
    }

    SDL_GPUShader *vertex_shader = rr_create_shader(renderer, "soundCircleVertex", SDL_GPU_SHADERSTAGE_VERTEX, 0);
    SDL_GPUShader *fragment_shader = rr_create_shader(renderer, "soundCircleFragment", SDL_GPU_SHADERSTAGE_FRAGMENT, 1);
    if (vertex_shader == NULL || fragment_shader == NULL) {
        if (vertex_shader != NULL) SDL_ReleaseGPUShader(renderer->device, vertex_shader);
        if (fragment_shader != NULL) SDL_ReleaseGPUShader(renderer->device, fragment_shader);
        RRSDLRendererDestroy(renderer);
        return NULL;
    }

    SDL_GPUColorTargetDescription color_target;
    SDL_zero(color_target);
    color_target.format = SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;

    SDL_GPUGraphicsPipelineCreateInfo pipeline_info;
    SDL_zero(pipeline_info);
    pipeline_info.vertex_shader = vertex_shader;
    pipeline_info.fragment_shader = fragment_shader;
    pipeline_info.primitive_type = SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;
    pipeline_info.rasterizer_state.fill_mode = SDL_GPU_FILLMODE_FILL;
    pipeline_info.rasterizer_state.cull_mode = SDL_GPU_CULLMODE_NONE;
    pipeline_info.multisample_state.sample_count = SDL_GPU_SAMPLECOUNT_1;
    pipeline_info.target_info.color_target_descriptions = &color_target;
    pipeline_info.target_info.num_color_targets = 1;
    pipeline_info.target_info.has_depth_stencil_target = false;

    renderer->pipeline = SDL_CreateGPUGraphicsPipeline(renderer->device, &pipeline_info);
    SDL_ReleaseGPUShader(renderer->device, vertex_shader);
    SDL_ReleaseGPUShader(renderer->device, fragment_shader);
    if (renderer->pipeline == NULL) {
        rr_set_error(renderer, "SDL_CreateGPUGraphicsPipeline");
        RRSDLRendererDestroy(renderer);
        return NULL;
    }

    SDL_GPUTextureCreateInfo texture_info;
    SDL_zero(texture_info);
    texture_info.type = SDL_GPU_TEXTURETYPE_2D;
    texture_info.format = SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
    texture_info.usage = SDL_GPU_TEXTUREUSAGE_COLOR_TARGET;
    texture_info.width = width;
    texture_info.height = height;
    texture_info.layer_count_or_depth = 1;
    texture_info.num_levels = 1;
    texture_info.sample_count = SDL_GPU_SAMPLECOUNT_1;
    renderer->texture = SDL_CreateGPUTexture(renderer->device, &texture_info);
    if (renderer->texture == NULL) {
        rr_set_error(renderer, "SDL_CreateGPUTexture");
        RRSDLRendererDestroy(renderer);
        return NULL;
    }

    SDL_GPUTextureCreateInfo audio_texture_info;
    SDL_zero(audio_texture_info);
    audio_texture_info.type = SDL_GPU_TEXTURETYPE_2D;
    audio_texture_info.format = SDL_GPU_TEXTUREFORMAT_R8_UNORM;
    audio_texture_info.usage = SDL_GPU_TEXTUREUSAGE_SAMPLER;
    audio_texture_info.width = RR_AUDIO_TEXTURE_WIDTH;
    audio_texture_info.height = RR_AUDIO_TEXTURE_HEIGHT;
    audio_texture_info.layer_count_or_depth = 1;
    audio_texture_info.num_levels = 1;
    audio_texture_info.sample_count = SDL_GPU_SAMPLECOUNT_1;
    renderer->audio_texture = SDL_CreateGPUTexture(renderer->device, &audio_texture_info);
    if (renderer->audio_texture == NULL) {
        rr_set_error(renderer, "SDL_CreateGPUTexture(audio)");
        RRSDLRendererDestroy(renderer);
        return NULL;
    }

    SDL_GPUSamplerCreateInfo sampler_info;
    SDL_zero(sampler_info);
    sampler_info.min_filter = SDL_GPU_FILTER_LINEAR;
    sampler_info.mag_filter = SDL_GPU_FILTER_LINEAR;
    sampler_info.mipmap_mode = SDL_GPU_SAMPLERMIPMAPMODE_NEAREST;
    sampler_info.address_mode_u = SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE;
    sampler_info.address_mode_v = SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE;
    sampler_info.address_mode_w = SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE;
    renderer->audio_sampler = SDL_CreateGPUSampler(renderer->device, &sampler_info);
    if (renderer->audio_sampler == NULL) {
        rr_set_error(renderer, "SDL_CreateGPUSampler(audio)");
        RRSDLRendererDestroy(renderer);
        return NULL;
    }

    SDL_GPUTransferBufferCreateInfo audio_transfer_info;
    SDL_zero(audio_transfer_info);
    audio_transfer_info.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
    audio_transfer_info.size = RR_AUDIO_TEXTURE_BYTE_COUNT;
    renderer->audio_upload_buffer = SDL_CreateGPUTransferBuffer(renderer->device, &audio_transfer_info);
    if (renderer->audio_upload_buffer == NULL) {
        rr_set_error(renderer, "SDL_CreateGPUTransferBuffer(audio)");
        RRSDLRendererDestroy(renderer);
        return NULL;
    }

    SDL_GPUTransferBufferCreateInfo transfer_info;
    SDL_zero(transfer_info);
    transfer_info.usage = SDL_GPU_TRANSFERBUFFERUSAGE_DOWNLOAD;
    transfer_info.size = width * height * 4;
    renderer->download_buffer = SDL_CreateGPUTransferBuffer(renderer->device, &transfer_info);
    if (renderer->download_buffer == NULL) {
        rr_set_error(renderer, "SDL_CreateGPUTransferBuffer");
        RRSDLRendererDestroy(renderer);
        return NULL;
    }

    return renderer;
}

void RRSDLRendererDestroy(RRSDLRenderer *renderer) {
    if (renderer == NULL) {
        return;
    }
    if (renderer->device != NULL) {
        SDL_WaitForGPUIdle(renderer->device);
        if (renderer->download_buffer != NULL) SDL_ReleaseGPUTransferBuffer(renderer->device, renderer->download_buffer);
        if (renderer->audio_upload_buffer != NULL) SDL_ReleaseGPUTransferBuffer(renderer->device, renderer->audio_upload_buffer);
        if (renderer->audio_sampler != NULL) SDL_ReleaseGPUSampler(renderer->device, renderer->audio_sampler);
        if (renderer->audio_texture != NULL) SDL_ReleaseGPUTexture(renderer->device, renderer->audio_texture);
        if (renderer->texture != NULL) SDL_ReleaseGPUTexture(renderer->device, renderer->texture);
        if (renderer->pipeline != NULL) SDL_ReleaseGPUGraphicsPipeline(renderer->device, renderer->pipeline);
        SDL_DestroyGPUDevice(renderer->device);
    }
    free(renderer);
}

bool RRSDLRendererRender(
    RRSDLRenderer *renderer,
    const uint8_t *audio_bytes,
    uint32_t audio_byte_count,
    float time,
    uint8_t *rgba_bytes,
    size_t rgba_length
) {
    if (renderer == NULL || rgba_bytes == NULL || rgba_length < (size_t)renderer->width * renderer->height * 4) {
        return false;
    }

    uint8_t *uploaded_audio = SDL_MapGPUTransferBuffer(renderer->device, renderer->audio_upload_buffer, true);
    if (uploaded_audio == NULL) {
        rr_set_error(renderer, "SDL_MapGPUTransferBuffer(audio)");
        return false;
    }
    memset(uploaded_audio, 0, RR_AUDIO_TEXTURE_BYTE_COUNT);
    uint32_t copy_count = audio_byte_count < RR_AUDIO_TEXTURE_BYTE_COUNT ? audio_byte_count : RR_AUDIO_TEXTURE_BYTE_COUNT;
    if (audio_bytes != NULL && copy_count > 0) memcpy(uploaded_audio, audio_bytes, copy_count);
    SDL_UnmapGPUTransferBuffer(renderer->device, renderer->audio_upload_buffer);

    float peak = 0;
    float sum = 0;
    const uint32_t energy_bin_count = 192;
    for (uint32_t index = 0; index < energy_bin_count; ++index) {
        float value = audio_bytes != NULL && index < audio_byte_count ? audio_bytes[index] / 255.0f : 0;
        peak = fmaxf(peak, value);
        sum += value;
    }
    RRFrameUniforms frame = {
        .resolution = {(float)renderer->width, (float)renderer->height},
        .time = time,
        .energy = fminf(1, fmaxf(peak, (sum / energy_bin_count) * 1.9f))
    };

    SDL_GPUCommandBuffer *command_buffer = SDL_AcquireGPUCommandBuffer(renderer->device);
    if (command_buffer == NULL) {
        rr_set_error(renderer, "SDL_AcquireGPUCommandBuffer");
        return false;
    }

    SDL_PushGPUFragmentUniformData(command_buffer, 0, &frame, sizeof(frame));

    SDL_GPUCopyPass *upload_pass = SDL_BeginGPUCopyPass(command_buffer);
    if (upload_pass == NULL) {
        rr_set_error(renderer, "SDL_BeginGPUCopyPass(audio)");
        SDL_CancelGPUCommandBuffer(command_buffer);
        return false;
    }
    SDL_GPUTextureTransferInfo audio_source = {
        .transfer_buffer = renderer->audio_upload_buffer,
        .offset = 0,
        .pixels_per_row = RR_AUDIO_TEXTURE_WIDTH,
        .rows_per_layer = RR_AUDIO_TEXTURE_HEIGHT
    };
    SDL_GPUTextureRegion audio_destination = {
        .texture = renderer->audio_texture,
        .mip_level = 0,
        .layer = 0,
        .x = 0,
        .y = 0,
        .z = 0,
        .w = RR_AUDIO_TEXTURE_WIDTH,
        .h = RR_AUDIO_TEXTURE_HEIGHT,
        .d = 1
    };
    SDL_UploadToGPUTexture(upload_pass, &audio_source, &audio_destination, true);
    SDL_EndGPUCopyPass(upload_pass);

    SDL_GPUColorTargetInfo target;
    SDL_zero(target);
    target.texture = renderer->texture;
    target.clear_color = (SDL_FColor){0.002f, 0.004f, 0.009f, 1.0f};
    target.load_op = SDL_GPU_LOADOP_CLEAR;
    target.store_op = SDL_GPU_STOREOP_STORE;

    SDL_GPURenderPass *render_pass = SDL_BeginGPURenderPass(command_buffer, &target, 1, NULL);
    if (render_pass == NULL) {
        rr_set_error(renderer, "SDL_BeginGPURenderPass");
        SDL_CancelGPUCommandBuffer(command_buffer);
        return false;
    }
    SDL_BindGPUGraphicsPipeline(render_pass, renderer->pipeline);
    SDL_GPUTextureSamplerBinding audio_binding = {
        .texture = renderer->audio_texture,
        .sampler = renderer->audio_sampler
    };
    SDL_BindGPUFragmentSamplers(render_pass, 0, &audio_binding, 1);
    SDL_DrawGPUPrimitives(render_pass, 3, 1, 0, 0);
    SDL_EndGPURenderPass(render_pass);

    SDL_GPUCopyPass *copy_pass = SDL_BeginGPUCopyPass(command_buffer);
    if (copy_pass == NULL) {
        rr_set_error(renderer, "SDL_BeginGPUCopyPass");
        SDL_CancelGPUCommandBuffer(command_buffer);
        return false;
    }
    SDL_GPUTextureRegion source = {
        .texture = renderer->texture,
        .mip_level = 0,
        .layer = 0,
        .x = 0,
        .y = 0,
        .z = 0,
        .w = renderer->width,
        .h = renderer->height,
        .d = 1
    };
    SDL_GPUTextureTransferInfo destination = {
        .transfer_buffer = renderer->download_buffer,
        .offset = 0,
        .pixels_per_row = renderer->width,
        .rows_per_layer = renderer->height
    };
    SDL_DownloadFromGPUTexture(copy_pass, &source, &destination);
    SDL_EndGPUCopyPass(copy_pass);

    SDL_GPUFence *fence = SDL_SubmitGPUCommandBufferAndAcquireFence(command_buffer);
    if (fence == NULL) {
        rr_set_error(renderer, "SDL_SubmitGPUCommandBufferAndAcquireFence");
        return false;
    }
    SDL_GPUFence *fences[] = {fence};
    bool completed = SDL_WaitForGPUFences(renderer->device, true, fences, 1);
    if (!completed) {
        rr_set_error(renderer, "SDL_WaitForGPUFences");
        SDL_ReleaseGPUFence(renderer->device, fence);
        return false;
    }

    void *downloaded = SDL_MapGPUTransferBuffer(renderer->device, renderer->download_buffer, false);
    if (downloaded == NULL) {
        rr_set_error(renderer, "SDL_MapGPUTransferBuffer");
        SDL_ReleaseGPUFence(renderer->device, fence);
        return false;
    }
    memcpy(rgba_bytes, downloaded, (size_t)renderer->width * renderer->height * 4);
    SDL_UnmapGPUTransferBuffer(renderer->device, renderer->download_buffer);
    SDL_ReleaseGPUFence(renderer->device, fence);
    return true;
}

const char *RRSDLRendererLastError(const RRSDLRenderer *renderer) {
    if (renderer == NULL) {
        return "SDL renderer is unavailable";
    }
    return renderer->last_error;
}
