#pragma once

#define FV_AUDIO_RATE          47605
#define FV_AUDIO_FRAME_SAMPLES 256
#define FV_AUDIO_FRAME_SIZE    (4 + FV_AUDIO_FRAME_SAMPLES / 2)

#define FV_SIGNATURE 0x53445646 // FVDS

typedef struct
{
    u32 frame;
    u32 offset;
} fv_keyframe_t;

typedef struct
{
    u32 signature;
    u16 width;
    u16 height;
    u32 fpsNum;
    u32 fpsDen;
    u16 audioRate;
    u16 audioChannels;
    u32 nrFrames;
    u32 nrKeyFrames;
} fv_header_t;
