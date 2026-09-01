#include <metal_stdlib>
using namespace metal;

// Metal ports/adaptations of the audio-reactive references selected in Retro REC.
// The 512-value spectrum and waveform buffers mirror Shadertoy's audio texture rows.

constant uint kAudioSampleCount = 512;

struct AudioVertexOut {
    float4 position [[position]];
};

struct AudioFrameUniforms {
    float2 resolution;
    float time;
    float energy;
    uint historyHead;
    uint historyRowCount;
    float isActive;
    float padding;
    float2 viewRotation;
    float4 themeBackground;
};

vertex AudioVertexOut shadertoyAudioVertex(uint vertexID [[vertex_id]]) {
    const float2 positions[3] = {
        float2(-1.0, -1.0),
        float2(3.0, -1.0),
        float2(-1.0, 3.0)
    };

    AudioVertexOut output;
    output.position = float4(positions[vertexID], 0.0, 1.0);
    return output;
}

inline float sampleAudio(device const float *values, float progress) {
    float position = clamp(progress, 0.0, 1.0) * float(kAudioSampleCount - 1);
    uint lower = min(uint(floor(position)), kAudioSampleCount - 1);
    uint upper = min(lower + 1, kAudioSampleCount - 1);
    return mix(values[lower], values[upper], fract(position));
}

inline float3 themedBackground(constant AudioFrameUniforms &frame) {
    return clamp(frame.themeBackground.rgb, 0.0, 1.0);
}

inline float3 spectrumPalette(float progress) {
    float3 phase = float3(0.0, 0.34, 0.67);
    return 0.54 + 0.46 * cos(6.28318530718 * (progress + phase));
}

inline float hash11(float value) {
    value = fract(value * 0.1031);
    value *= value + 33.33;
    value *= value + value;
    return fract(value);
}

inline float hash21(float2 value) {
    float3 p3 = fract(float3(value.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

inline float sdSegment(float2 point, float2 start, float2 end) {
    float2 pa = point - start;
    float2 ba = end - start;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1.0e-6), 0.0, 1.0);
    return length(pa - ba * h);
}

// Reference: https://www.shadertoy.com/view/stSGDK
fragment float4 circleReactiveFragment(
    AudioVertexOut input [[stage_in]],
    constant AudioFrameUniforms &frame [[buffer(0)]],
    device const float *spectrum [[buffer(1)]],
    device const float *waveform [[buffer(2)]],
    device const float *history [[buffer(3)]]
) {
    float2 resolution = max(frame.resolution, float2(1.0));
    float2 point = (2.0 * input.position.xy - resolution) / min(resolution.x, resolution.y);
    float radius = length(point);
    float angle = atan2(point.y, point.x);
    float around = fract(angle / 6.28318530718 + 0.5);

    constexpr float segmentCount = 112.0;
    float segment = floor(around * segmentCount);
    float segmentProgress = (segment + 0.5) / segmentCount;
    float folded = abs(segmentProgress * 2.0 - 1.0);
    float frequency = pow(folded, 2.15) * 0.72;
    float fft = max(
        sampleAudio(spectrum, frequency),
        sampleAudio(spectrum, frequency + 0.004) * 0.88
    );
    fft = pow(clamp(fft, 0.0, 1.0), 0.58);
    float wave = sampleAudio(waveform, segmentProgress);
    float innerRadius = 0.245 + 0.008 * sin(frame.time * 1.3 + angle * 3.0);
    float outerRadius = innerRadius + 0.035 + fft * 0.34 + abs(wave) * 0.04;
    float localSegment = fract(around * segmentCount);
    float angularMask = smoothstep(0.08, 0.2, localSegment)
        * (1.0 - smoothstep(0.8, 0.92, localSegment));
    float radialMask = smoothstep(innerRadius - 0.006, innerRadius + 0.006, radius)
        * (1.0 - smoothstep(outerRadius - 0.008, outerRadius + 0.008, radius));
    float bar = angularMask * radialMask;

    float tipDistance = abs(radius - outerRadius);
    float tipGlow = angularMask * 0.0035 / (tipDistance + 0.0035);
    float coreDistance = abs(radius - innerRadius);
    float coreRing = 1.0 - smoothstep(0.002, 0.008, coreDistance);
    float pulseDistance = abs(radius - (0.175 + frame.energy * 0.035));
    float pulse = 0.002 / (pulseDistance + 0.002);

    float3 background = themedBackground(frame);
    float3 color = background;
    float3 barColor = spectrumPalette(segmentProgress + frame.time * 0.018);
    color += barColor * bar * (0.45 + fft * 1.65);
    color += barColor * tipGlow * tipGlow * (0.08 + fft * 0.48);
    color += float3(0.16, 0.78, 1.0) * coreRing * 0.72;
    color += float3(1.0, 0.28, 0.64) * pulse * pulse * frame.energy * 0.08;
    color = mix(background, color, 1.0 - smoothstep(0.72, 1.35, radius));
    return float4(max(color, float3(0.0)), 1.0);
}

// Reference: https://www.shadertoy.com/view/4dcBD7
fragment float4 waveLeneerFragment(
    AudioVertexOut input [[stage_in]],
    constant AudioFrameUniforms &frame [[buffer(0)]],
    device const float *spectrum [[buffer(1)]],
    device const float *waveform [[buffer(2)]],
    device const float *history [[buffer(3)]]
) {
    float2 resolution = max(frame.resolution, float2(1.0));
    float2 uv = input.position.xy / resolution;
    float y = (uv.y - 0.5) * 2.0;
    float wave = tanh(sampleAudio(waveform, uv.x) * 4.2);
    float previous = tanh(sampleAudio(waveform, uv.x - 0.003) * 4.2);
    float next = tanh(sampleAudio(waveform, uv.x + 0.003) * 4.2);
    wave = (previous + wave * 2.0 + next) * 0.25;
    float envelope = 0.28 + 0.72 * pow(sampleAudio(spectrum, pow(uv.x, 1.8) * 0.55), 0.48);
    float primaryY = wave * (0.16 + envelope * 0.38);
    float echoY = -wave * 0.22 + sin(uv.x * 31.0 - frame.time * 1.7) * frame.energy * 0.035;

    float primaryDistance = abs(y - primaryY);
    float echoDistance = abs(y - echoY);
    float core = 1.0 - smoothstep(0.005, 0.017, primaryDistance);
    float glow = 0.004 / (primaryDistance + 0.004);
    float echo = 1.0 - smoothstep(0.004, 0.013, echoDistance);
    float baseline = 1.0 - smoothstep(0.001, 0.006, abs(y));
    float3 lineColor = mix(
        float3(0.1, 0.95, 1.0),
        float3(1.0, 0.18, 0.68),
        smoothstep(0.1, 0.9, uv.x)
    );
    float3 echoColor = mix(float3(1.0, 0.72, 0.12), float3(0.4, 0.22, 1.0), uv.x);

    float3 background = themedBackground(frame);
    float3 color = background;
    color += lineColor * (core * 1.5 + glow * glow * 0.18);
    color += echoColor * echo * 0.72;
    color += float3(0.16, 0.3, 0.38) * baseline * 0.35;
    color = background + (color - background) * (0.82 + 0.18 * cos((uv.y - 0.5) * 3.14159265));
    return float4(color, 1.0);
}

// Reference: https://www.shadertoy.com/view/lsVfzd
fragment float4 colorFFTFragment(
    AudioVertexOut input [[stage_in]],
    constant AudioFrameUniforms &frame [[buffer(0)]],
    device const float *spectrum [[buffer(1)]],
    device const float *waveform [[buffer(2)]],
    device const float *history [[buffer(3)]]
) {
    float2 resolution = max(frame.resolution, float2(1.0));
    float2 uv = input.position.xy / resolution;
    constexpr float binCount = 128.0;
    float bin = floor(uv.x * binCount);
    float binProgress = (bin + 0.5) / binCount;
    float fft = sampleAudio(spectrum, pow(binProgress, 2.05) * 0.78);
    fft = pow(clamp(fft, 0.0, 1.0), 0.52);
    float height = 0.015 + fft * 0.47;
    float vertical = abs(uv.y - 0.5);
    float inside = 1.0 - smoothstep(height - 0.008, height + 0.006, vertical);
    float topLine = 1.0 - smoothstep(0.002, 0.009, abs(vertical - height));
    float gap = smoothstep(0.08, 0.22, fract(uv.x * binCount))
        * (1.0 - smoothstep(0.78, 0.92, fract(uv.x * binCount)));
    float rowPattern = 0.62 + 0.38 * step(0.24, fract(vertical * resolution.y * 0.24));
    float3 rainbow = spectrumPalette(binProgress * 0.92 - 0.08 + frame.time * 0.012);
    float centerGlow = 0.003 / (vertical + 0.003);

    float3 background = themedBackground(frame);
    float3 color = background;
    color += rainbow * inside * gap * rowPattern * (0.28 + fft * 1.3);
    color += rainbow * topLine * gap * 1.4;
    color += rainbow * centerGlow * centerGlow * frame.energy * 0.08;
    color = background + (color - background) * (0.88 + 0.12 * cos((uv.y - 0.5) * 6.2831853));
    return float4(color, 1.0);
}

// Source port: https://www.shadertoy.com/view/DdsXW2
// Triangle distance portion Copyright (c) 2014 Inigo Quilez, MIT License.
inline float triangleGalaxyField(float3 point, float sound, float time, int iterations) {
    float strength = 7.0 + 0.03 * log(1.0e-6 + fract(sin(time) * 4373.11));
    float accumulator = sound / 4.0;
    float previous = 0.0;
    float totalWeight = 0.0;

    for (int index = 0; index < iterations; ++index) {
        float magnitude = max(dot(point, point), 1.0e-5);
        point = abs(point) / magnitude + float3(-0.5, -0.4, -1.5);
        float weight = exp(-float(index) / 7.0);
        accumulator += weight * exp(-strength * pow(abs(magnitude - previous), 2.2));
        totalWeight += weight;
        previous = magnitude;
    }
    return max(0.0, 5.0 * accumulator / totalWeight - 0.7);
}

inline float3 triangleGalaxyRandom(float2 coordinate) {
    float3 a = fract(cos(coordinate.x * 8.3e-3 + coordinate.y) * float3(1.3e5, 4.7e5, 2.9e5));
    float3 b = fract(sin(coordinate.x * 0.3e-3 + coordinate.y) * float3(8.1e5, 1.0e5, 0.1e5));
    return mix(a, b, 0.5);
}

inline float signedTriangleDistance(float2 point, float2 p0, float2 p1, float2 p2) {
    float2 e0 = p1 - p0;
    float2 e1 = p2 - p1;
    float2 e2 = p0 - p2;
    float2 v0 = point - p0;
    float2 v1 = point - p1;
    float2 v2 = point - p2;
    float2 pq0 = v0 - e0 * clamp(dot(v0, e0) / dot(e0, e0), 0.0, 1.0);
    float2 pq1 = v1 - e1 * clamp(dot(v1, e1) / dot(e1, e1), 0.0, 1.0);
    float2 pq2 = v2 - e2 * clamp(dot(v2, e2) / dot(e2, e2), 0.0, 1.0);
    float side = e0.x * e2.y - e0.y * e2.x;
    float2 distance = min(
        min(
            float2(dot(pq0, pq0), side * (v0.x * e0.y - v0.y * e0.x)),
            float2(dot(pq1, pq1), side * (v1.x * e1.y - v1.y * e1.x))
        ),
        float2(dot(pq2, pq2), side * (v2.x * e2.y - v2.y * e2.x))
    );
    return -sqrt(distance.x) * sign(distance.y);
}

fragment float4 triangleGalaxyFragment(
    AudioVertexOut input [[stage_in]],
    constant AudioFrameUniforms &frame [[buffer(0)]],
    device const float *spectrum [[buffer(1)]],
    device const float *waveform [[buffer(2)]],
    device const float *history [[buffer(3)]]
) {
    float2 resolution = max(frame.resolution, float2(1.0));
    float2 fragmentCoordinate = input.position.xy;
    float2 pp = (2.0 * fragmentCoordinate - resolution) / resolution.y * 1.5;
    float2 uv = 2.0 * fragmentCoordinate / resolution - 1.0;
    float2 uvs = uv * resolution / max(resolution.x, resolution.y);
    float3 point = float3(uvs / 4.0, 0.0) + float3(1.0, -1.3, 0.0);
    point += 0.2 * float3(
        sin(frame.time / 16.0),
        sin(frame.time / 12.0),
        sin(frame.time / 128.0)
    );

    float frequencies[6];
    frequencies[0] = sampleAudio(spectrum, 0.01);
    frequencies[1] = sampleAudio(spectrum, 0.03);
    frequencies[2] = sampleAudio(spectrum, 0.05);
    frequencies[3] = sampleAudio(spectrum, 0.07);
    frequencies[4] = sampleAudio(spectrum, 0.15);
    frequencies[5] = sampleAudio(spectrum, 0.30);

    float field = triangleGalaxyField(point, frequencies[4], frame.time, 26);
    float vignette = (1.0 - exp((abs(uv.x) - 1.0) * 6.0))
        * (1.0 - exp((abs(uv.y) - 1.0) * 6.0));
    float denominator = 4.6 + sin(frame.time * 0.11) * 0.2 + sin(frame.time * 0.15) * 0.3;
    float3 secondPoint = float3(uvs / denominator, 1.5) + float3(2.0, -1.3, -1.0);
    secondPoint += 0.25 * float3(
        sin(frame.time / 16.0),
        sin(frame.time / 12.0),
        sin(frame.time / 128.0)
    );
    float secondField = triangleGalaxyField(secondPoint, frequencies[5], frame.time, 18);
    float4 secondColor = mix(0.4, 1.0, vignette) * float4(
        1.3 * secondField * secondField * secondField,
        1.8 * secondField * secondField,
        secondField * frequencies[0],
        secondField
    );
    float3 randomOne = triangleGalaxyRandom(floor(point.xy * 2.0 * resolution.x));
    float3 randomTwo = triangleGalaxyRandom(floor(secondPoint.xy * 2.0 * resolution.x));
    float stars = pow(randomOne.y, 40.0) + pow(randomTwo.y, 40.0);
    float4 fieldColor = float4(0.2) + 1.3 * (
        mix(frequencies[5] - 0.3, 1.0, vignette)
            * float4(
                1.5 * frequencies[4] * field * field * field,
                1.2 * frequencies[3] * field * field,
                frequencies[5] * field,
                1.0
            )
        + secondColor
    ) + 1.5 * stars;

    float beat = 0.25 * frequencies[0] * frequencies[0]
        + 0.25 * frequencies[1] * frequencies[1]
        + 0.25 * frequencies[2] * frequencies[2]
        + 0.25 * frequencies[3] * frequencies[3];
    beat = sqrt(beat) * 3.7;

    float scale = 2.3;
    float2 v1 = float2(0.0, 0.477) * scale;
    float2 v2 = float2(-0.5, -0.389) * scale;
    float2 v3 = float2(0.5, -0.389) * scale;
    float distance = signedTriangleDistance(pp, v1, v2, v3);
    float3 color = beat - sign(distance) * float3(0.1, 0.4, 0.7);
    if (distance > 0.0) {
        color += fieldColor.xyz - beat;
    } else {
        color *= float3(1.0, 0.0, 0.0);
    }
    color *= 1.0 - exp(-2.0 * abs(distance));
    color *= 0.8 + 0.2 * cos(120.0 * distance);
    color = mix(color, float3(1.0), 1.0 - smoothstep(0.0, 0.02, abs(distance)));
    return float4(color, 1.0);
}

// Reference: https://www.shadertoy.com/view/WfV3zh
fragment float4 microphoneGradientFragment(
    AudioVertexOut input [[stage_in]],
    constant AudioFrameUniforms &frame [[buffer(0)]],
    device const float *spectrum [[buffer(1)]],
    device const float *waveform [[buffer(2)]],
    device const float *history [[buffer(3)]]
) {
    float2 resolution = max(frame.resolution, float2(1.0));
    float2 uv = input.position.xy / resolution;
    float2 point = float2(uv.x, (uv.y - 0.5) * 2.0);
    float rawWave = sampleAudio(waveform, uv.x);
    float smoothWave = (
        sampleAudio(waveform, uv.x - 0.004)
        + rawWave * 2.0
        + sampleAudio(waveform, uv.x + 0.004)
    ) * 0.25;
    float edgeEnvelope = pow(max(0.0, sin(uv.x * 3.14159265)), 0.35);
    float audioWave = tanh(smoothWave * 4.8) * edgeEnvelope;
    float frequencyLift = pow(sampleAudio(spectrum, pow(uv.x, 1.7) * 0.62), 0.56);
    float target = audioWave * (0.16 + frequencyLift * 0.39);
    target += sin(uv.x * 18.0 - frame.time * 2.1) * frame.energy * 0.025 * edgeEnvelope;
    float distance = abs(point.y - target);
    float reflectedDistance = abs(point.y + target * 0.38);
    float core = 1.0 - smoothstep(0.004, 0.014, distance);
    float glow = 0.0045 / (distance + 0.0045);
    float reflection = 1.0 - smoothstep(0.003, 0.012, reflectedDistance);
    float3 gradient = mix(
        mix(float3(0.1, 0.92, 1.0), float3(0.46, 0.26, 1.0), smoothstep(0.0, 0.48, uv.x)),
        mix(float3(1.0, 0.12, 0.68), float3(1.0, 0.72, 0.12), smoothstep(0.55, 1.0, uv.x)),
        smoothstep(0.42, 0.62, uv.x)
    );
    float3 background = themedBackground(frame);
    background += gradient * (0.018 + frequencyLift * 0.035) * (1.0 - abs(point.y));
    float3 color = background;
    color += gradient * (core * 1.55 + glow * glow * 0.2);
    color += gradient.zxy * reflection * 0.36;
    return float4(color, 1.0);
}

inline float sampleHistory(
    device const float *history,
    constant AudioFrameUniforms &frame,
    float frequency,
    float age
) {
    uint rowCount = max(frame.historyRowCount, 1u);
    float rowPosition = clamp(age, 0.0, 1.0) * float(rowCount - 1);
    uint ageLower = uint(floor(rowPosition));
    uint ageUpper = min(ageLower + 1, rowCount - 1);
    uint newest = (frame.historyHead + rowCount - 1) % rowCount;
    uint lowerRow = (newest + rowCount - ageLower) % rowCount;
    uint upperRow = (newest + rowCount - ageUpper) % rowCount;
    float xPosition = clamp(frequency, 0.0, 1.0) * float(kAudioSampleCount - 1);
    uint xLower = min(uint(floor(xPosition)), kAudioSampleCount - 1);
    uint xUpper = min(xLower + 1, kAudioSampleCount - 1);
    float xBlend = fract(xPosition);
    float lowerValue = mix(
        history[lowerRow * kAudioSampleCount + xLower],
        history[lowerRow * kAudioSampleCount + xUpper],
        xBlend
    );
    float upperValue = mix(
        history[upperRow * kAudioSampleCount + xLower],
        history[upperRow * kAudioSampleCount + xUpper],
        xBlend
    );
    return mix(lowerValue, upperValue, fract(rowPosition));
}

inline float plasticHeight(
    device const float *history,
    constant AudioFrameUniforms &frame,
    float2 position
) {
    float frequency = pow(clamp(position.x * 0.5 + 0.5, 0.0, 1.0), 1.7) * 0.76;
    float age = clamp(position.y * 0.5 + 0.5, 0.0, 1.0);
    float height = pow(sampleHistory(history, frame, frequency, age), 0.62);
    float ripple = sin(position.x * 8.0 + position.y * 5.0 - frame.time * 0.7) * 0.025;
    return -0.56 + height * 0.9 + ripple * frame.energy;
}

// Source structure: https://www.shadertoy.com/view/3lXXD8
// The original Common pass is not public in indexed mirrors. This port reconstructs
// its height gradient and feeds the surface with a native rolling spectrogram.
fragment float4 plasticSurfaceFragment(
    AudioVertexOut input [[stage_in]],
    constant AudioFrameUniforms &frame [[buffer(0)]],
    device const float *spectrum [[buffer(1)]],
    device const float *waveform [[buffer(2)]],
    device const float *history [[buffer(3)]]
) {
    float2 resolution = max(frame.resolution, float2(1.0));
    float2 uv = (2.0 * input.position.xy - resolution) / resolution.y;
    float3 target = float3(0.0, -0.18, 0.0);
    float yaw = frame.viewRotation.x;
    float pitch = frame.viewRotation.y;
    constexpr float cameraRadius = 2.72;
    float3 rayOrigin = target + float3(
        sin(yaw) * cos(pitch) * cameraRadius,
        sin(pitch) * cameraRadius,
        -cos(yaw) * cos(pitch) * cameraRadius
    );
    float3 forward = normalize(target - rayOrigin);
    float3 right = normalize(cross(float3(0.0, 1.0, 0.0), forward));
    float3 up = cross(forward, right);
    float3 rayDirection = normalize(forward * 1.75 + right * uv.x + up * uv.y);

    float distanceAlongRay = 0.0;
    float3 position = rayOrigin;
    bool hit = false;
    for (int step = 0; step < 104; ++step) {
        position = rayOrigin + rayDirection * distanceAlongRay;
        if (distanceAlongRay > 5.2) {
            break;
        }
        if (abs(position.x) <= 1.16 && abs(position.z) <= 1.16) {
            float height = plasticHeight(history, frame, position.xz / 1.16);
            float signedHeight = position.y - height;
            if (signedHeight < 0.012) {
                hit = true;
                break;
            }
            distanceAlongRay += max(0.012, signedHeight * 0.24);
        } else {
            distanceAlongRay += 0.045;
        }
    }

    float3 color = themedBackground(frame);
    if (hit) {
        constexpr float epsilon = 0.014;
        float left = plasticHeight(history, frame, (position.xz + float2(-epsilon, 0.0)) / 1.16);
        float rightHeight = plasticHeight(history, frame, (position.xz + float2(epsilon, 0.0)) / 1.16);
        float back = plasticHeight(history, frame, (position.xz + float2(0.0, -epsilon)) / 1.16);
        float front = plasticHeight(history, frame, (position.xz + float2(0.0, epsilon)) / 1.16);
        float3 normal = normalize(float3(left - rightHeight, epsilon * 2.0, back - front));
        float3 lightDirection = normalize(float3(-0.45, 0.85, -0.3));
        float diffuse = max(dot(normal, lightDirection), 0.0);
        float3 halfVector = normalize(lightDirection - rayDirection);
        float specular = pow(max(dot(normal, halfVector), 0.0), 44.0);
        float heightValue = clamp((position.y + 0.58) / 0.92, 0.0, 1.0);
        float3 lowColor = float3(0.05, 0.18, 0.42);
        float3 middleColor = float3(0.2, 0.82, 0.92);
        float3 highColor = float3(1.0, 0.18, 0.62);
        float3 surfaceColor = mix(lowColor, middleColor, smoothstep(0.0, 0.58, heightValue));
        surfaceColor = mix(surfaceColor, highColor, smoothstep(0.56, 1.0, heightValue));
        float gridX = 1.0 - smoothstep(0.0, 0.035, abs(fract((position.x + 1.16) * 16.0) - 0.5));
        float gridZ = 1.0 - smoothstep(0.0, 0.035, abs(fract((position.z + 1.16) * 12.0) - 0.5));
        float grid = max(gridX, gridZ);
        color = surfaceColor * (0.18 + diffuse * 0.9);
        color += float3(1.0, 0.92, 1.0) * specular * (0.8 + frame.energy * 1.4);
        color += surfaceColor * grid * 0.12;
        color *= exp(-distanceAlongRay * 0.12);
    }
    return float4(color, 1.0);
}

inline float3 movingSpectrumPalette(float amplitude, float age) {
    float3 cold = float3(0.012, 0.035, 0.12);
    float3 cyan = float3(0.02, 0.82, 1.0);
    float3 yellow = float3(1.0, 0.88, 0.14);
    float3 hot = float3(1.0, 0.08, 0.28);
    float3 color = mix(cold, cyan, smoothstep(0.04, 0.34, amplitude));
    color = mix(color, yellow, smoothstep(0.30, 0.68, amplitude));
    color = mix(color, hot, smoothstep(0.66, 1.0, amplitude));
    return color * mix(1.0, 0.42, age);
}

// Metal reconstruction based on https://www.shadertoy.com/view/tfB3z3.
// A native rolling FFT history supplies the moving spectrum texture.
fragment float4 movingFrequencySpectrumFragment(
    AudioVertexOut input [[stage_in]],
    constant AudioFrameUniforms &frame [[buffer(0)]],
    device const float *spectrum [[buffer(1)]],
    device const float *waveform [[buffer(2)]],
    device const float *history [[buffer(3)]]
) {
    float2 resolution = max(frame.resolution, float2(1.0));
    float2 uv = input.position.xy / resolution;
    float frequency = pow(clamp(uv.x, 0.0, 1.0), 1.78) * 0.78;
    float age = clamp(1.0 - uv.y, 0.0, 1.0);
    float amplitude = pow(sampleHistory(history, frame, frequency, age), 0.56);
    float previousAmplitude = pow(sampleHistory(history, frame, frequency, min(age + 0.018, 1.0)), 0.56);

    float3 background = themedBackground(frame);
    float3 color = background;
    float energyBand = smoothstep(0.025, 0.70, amplitude);
    color += movingSpectrumPalette(amplitude, age) * energyBand * (0.22 + amplitude * 1.28);

    float contour = 1.0 - smoothstep(0.035, 0.13, abs(fract(amplitude * 5.0 - age * 4.0) - 0.5));
    color += movingSpectrumPalette(min(amplitude + 0.2, 1.0), age) * contour * energyBand * 0.16;
    float motionEdge = smoothstep(0.025, 0.16, abs(amplitude - previousAmplitude));
    color += float3(0.34, 0.75, 1.0) * motionEdge * amplitude * 0.24;

    float currentAmplitude = pow(sampleAudio(spectrum, frequency), 0.54);
    float currentLineY = 0.92 - currentAmplitude * 0.40;
    float lineDistance = abs(uv.y - currentLineY);
    float lineCore = 1.0 - smoothstep(0.003, 0.012, lineDistance);
    float lineGlow = 0.004 / (lineDistance + 0.004);
    float3 lineColor = mix(float3(0.15, 0.95, 1.0), float3(1.0, 0.2, 0.48), currentAmplitude);
    color += lineColor * (lineCore * 1.35 + lineGlow * lineGlow * 0.11);

    float gridX = 1.0 - smoothstep(0.0, 0.035, abs(fract(uv.x * 12.0) - 0.5));
    float gridY = 1.0 - smoothstep(0.0, 0.04, abs(fract(uv.y * 8.0) - 0.5));
    color += float3(0.04, 0.12, 0.22) * max(gridX, gridY) * 0.12;
    float edgeFade = smoothstep(0.0, 0.025, uv.x) * smoothstep(0.0, 0.025, 1.0 - uv.x);
    color = mix(background, color, edgeFade);
    return float4(max(color, float3(0.0)), 1.0);
}

// Metal reconstruction based on https://www.shadertoy.com/view/3fBGzc.
fragment float4 micRipplesFragment(
    AudioVertexOut input [[stage_in]],
    constant AudioFrameUniforms &frame [[buffer(0)]],
    device const float *spectrum [[buffer(1)]],
    device const float *waveform [[buffer(2)]],
    device const float *history [[buffer(3)]]
) {
    float2 resolution = max(frame.resolution, float2(1.0));
    float2 point = (2.0 * input.position.xy - resolution) / min(resolution.x, resolution.y);
    float radius = length(point);
    float angle = atan2(point.y, point.x);
    float around = fract(angle / 6.28318530718 + 0.5);
    float angularWave = sampleAudio(waveform, around);
    float oppositeWave = sampleAudio(waveform, fract(around + 0.5));
    float bass = pow(sampleAudio(spectrum, 0.025), 0.58);
    float middle = pow(sampleAudio(spectrum, 0.18), 0.62);

    float warpedRadius = radius;
    warpedRadius += angularWave * (0.035 + bass * 0.055);
    warpedRadius += oppositeWave * middle * 0.018;
    warpedRadius += sin(angle * 5.0 - frame.time * 0.62) * frame.energy * 0.018;

    float travel = warpedRadius * 11.5 - frame.time * (0.72 + bass * 0.42);
    float rippleDistance = abs(fract(travel) - 0.5);
    float rippleCore = 1.0 - smoothstep(0.025, 0.085, rippleDistance);
    float rippleGlow = 0.035 / (rippleDistance + 0.035);
    float fade = exp(-radius * 1.45) * (1.0 - smoothstep(0.12, 1.28, radius));

    float frequency = pow(abs(around * 2.0 - 1.0), 1.8) * 0.72;
    float fft = pow(sampleAudio(spectrum, frequency), 0.58);
    float3 cool = float3(0.02, 0.34, 0.78);
    float3 bright = float3(0.18, 0.96, 1.0);
    float3 hot = float3(1.0, 0.18, 0.58);
    float3 rippleColor = mix(cool, bright, smoothstep(0.05, 0.48, fft));
    rippleColor = mix(rippleColor, hot, smoothstep(0.52, 0.92, fft + bass * 0.25));

    float center = 0.012 / (radius + 0.012);
    float3 color = themedBackground(frame);
    color += rippleColor * (rippleCore * (0.28 + fft * 1.25) + rippleGlow * rippleGlow * 0.10) * fade;
    color += mix(bright, hot, bass) * center * center * (0.10 + bass * 0.28);
    color += rippleColor * abs(angularWave) * 0.10 * (1.0 - smoothstep(0.0, 0.75, radius));
    color += (hash21(input.position.xy + floor(frame.time * 60.0)) - 0.5) * 0.003;
    return float4(max(color, float3(0.0)), 1.0);
}
