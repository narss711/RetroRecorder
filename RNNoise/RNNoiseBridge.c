#include "RNNoiseBridge.h"
#include "include/rnnoise.h"
#include <stdlib.h>

typedef struct RNNoiseProcessor {
    DenoiseState *state;
} RNNoiseProcessor;

RNNoiseProcessorRef RNNoiseProcessorCreate(void) {
    RNNoiseProcessor *processor = (RNNoiseProcessor *)calloc(1, sizeof(RNNoiseProcessor));
    if (processor == NULL) {
        return NULL;
    }

    processor->state = rnnoise_create(NULL);
    if (processor->state == NULL) {
        free(processor);
        return NULL;
    }

    return (RNNoiseProcessorRef)processor;
}

void RNNoiseProcessorDestroy(RNNoiseProcessorRef processorRef) {
    if (processorRef == NULL) {
        return;
    }

    RNNoiseProcessor *processor = (RNNoiseProcessor *)processorRef;
    if (processor->state != NULL) {
        rnnoise_destroy(processor->state);
    }

    free(processor);
}

int RNNoiseProcessorFrameSize(void) {
    return rnnoise_get_frame_size();
}

float RNNoiseProcessorProcessFrame(RNNoiseProcessorRef processorRef, const float *input, float *output) {
    if (processorRef == NULL || input == NULL || output == NULL) {
        return 0.0f;
    }

    RNNoiseProcessor *processor = (RNNoiseProcessor *)processorRef;
    if (processor->state == NULL) {
        return 0.0f;
    }

    return rnnoise_process_frame(processor->state, output, input);
}
