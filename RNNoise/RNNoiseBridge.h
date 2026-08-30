#ifndef RNNOISE_BRIDGE_H
#define RNNOISE_BRIDGE_H

#ifdef __cplusplus
extern "C" {
#endif

typedef void *RNNoiseProcessorRef;

RNNoiseProcessorRef RNNoiseProcessorCreate(void);
void RNNoiseProcessorDestroy(RNNoiseProcessorRef processor);
int RNNoiseProcessorFrameSize(void);
float RNNoiseProcessorProcessFrame(RNNoiseProcessorRef processor, const float *input, float *output);

#ifdef __cplusplus
}
#endif

#endif
