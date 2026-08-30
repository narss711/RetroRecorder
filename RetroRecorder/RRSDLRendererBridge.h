#ifndef RRSDLRendererBridge_h
#define RRSDLRendererBridge_h

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef struct RRSDLRenderer RRSDLRenderer;

RRSDLRenderer *RRSDLRendererCreate(uint32_t width, uint32_t height);
void RRSDLRendererDestroy(RRSDLRenderer *renderer);

bool RRSDLRendererRender(
    RRSDLRenderer *renderer,
    const uint8_t *audio_bytes,
    uint32_t audio_byte_count,
    float time,
    uint8_t *rgba_bytes,
    size_t rgba_length
);

const char *RRSDLRendererLastError(const RRSDLRenderer *renderer);

#endif
