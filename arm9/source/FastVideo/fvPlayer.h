#pragma once
#include "fvDecoder.h"

//the player has 4 stages
//0 - fetching video data -> done by arm7
//1 - decoding vectors of P frames and sending DL to GE
//2 - decoding full I frames or dcts of P frames
//3 - finishing P frames

#define FV_PLAYER_DATA_BUFFER_SIZE      (64 * 1024)
#define FV_PLAYER_DATA_BUFFER_COUNT     6

typedef struct
{
    u8* dataBuffer; //cache-aligned buffer containing encoded frame data
    int frameDataSizes[FV_PLAYER_DATA_BUFFER_COUNT]; //size of the encoded data in the buffers
    bool frameHasAudio[FV_PLAYER_DATA_BUFFER_COUNT];
    int dataBufferReadIdx;
    int dataBufferWriteIdx;
    volatile int validDataBufferCount;
    volatile int freeDataBufferCount;
    fv_decoder_asm_t decoder;
    int stage1Buffer;
    int stage2Buffer;
    const u16* stage2DataPtr;
    int stage2IsPFrame;
    int stage3IsPFrame;
    int stage2VramBlock;
    int stage3VramBlock;
    bool stage3HasAudio;
    int nextVramBlock;
    volatile int isRequesting;
    fv_header_t* fvHeader;
    int vblankPerFrame;
    u32 dlLength;
    int lateCount;
    bool audioStarted;
    bool firstKeyFrame;
    int curFrame;
    int lastKeyFrame;
    volatile bool seekComplete;
    volatile bool isPlaying;
} fv_player_t;

#ifdef __cplusplus
extern "C" {
#endif

bool fv_initPlayer(fv_player_t* player, const char* filePath, bool useWram);
void fv_destroyPlayer(fv_player_t* player);
void fv_startPlayer(fv_player_t* player);
void fv_updatePlayer(fv_player_t* player);

void fv_pausePlayer(fv_player_t* player);
void fv_resumePlayer(fv_player_t* player);
void fv_gotoKeyFrame(fv_player_t* player, u32 keyFrame);
void fv_gotoNearestKeyFrame(fv_player_t* player, u32 frame);

static inline u32 fv_gotoNextKeyFrame(fv_player_t* player)
{
    int frame = player->lastKeyFrame + 1;
    if ((u32)frame >= player->fvHeader->nrKeyFrames)
        frame = player->fvHeader->nrKeyFrames - 1;
    fv_gotoKeyFrame(player, frame);
    return frame;
}

static inline u32 fv_gotoPreviousKeyFrame(fv_player_t* player)
{
    int frame = player->lastKeyFrame - 1;
    if (frame < 0)
        frame = 0;
    fv_gotoKeyFrame(player, frame);
    return frame;
}

static inline u16* fv_getPlayerDataBuffer(const fv_player_t* player, int index)
{
    return (u16*)&player->dataBuffer[FV_PLAYER_DATA_BUFFER_SIZE * index];
}

#ifdef __cplusplus
}
#endif