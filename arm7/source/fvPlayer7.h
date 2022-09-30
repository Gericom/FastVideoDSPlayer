#pragma once
#include "../../common/fastVideo.h"
#include "fat/ff.h"
#include "fpsAdjust.h"

#define FV_AUDIO_QUEUE_FRAMES  64

#define FV_AUDIO_RING_FRAMES 24

typedef struct
{
    bool audioStarted;
    FIL file;
    fpsa_t fpsa;
    u32 nrKeyFrames;
    // u32 curVideoFrame;
    int queueReadPtr;
    int queueWritePtr;
    int queueFrameCount;
    int audioFramesNeeded;
    int audioFramesProvided;
    int ringPos;
    // u32 queueVideoFrameIds[FV_AUDIO_QUEUE_FRAMES];
    // u32 ringVideoFrameIds[FV_AUDIO_RING_FRAMES];
    u8 audioQueueL[FV_AUDIO_QUEUE_FRAMES][FV_AUDIO_FRAME_SIZE] ALIGN(4);
    u8 audioQueueR[FV_AUDIO_QUEUE_FRAMES][FV_AUDIO_FRAME_SIZE] ALIGN(4);
    s16 audioRingL[FV_AUDIO_RING_FRAMES][FV_AUDIO_FRAME_SAMPLES] ALIGN(4);
    s16 audioRingR[FV_AUDIO_RING_FRAMES][FV_AUDIO_FRAME_SAMPLES] ALIGN(4);
} fv_player7_t;

void fv_init(void);
void fv_main(void);
