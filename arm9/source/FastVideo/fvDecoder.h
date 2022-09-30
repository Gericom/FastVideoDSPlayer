#pragma once
#include "../../common/fastVideo.h"

typedef struct
{
    u16 qTab[16];
    u8 q;
} fv_decoder_t;

typedef struct
{
    u32 qTab[64];
    const u8* clampTable;
    const u8* vlcIdxTab;
    const u8* vlcBitTab2;
    const u32* vlcPackTab;
    u32 dequant0;
    u32 dequant1;
    u32 dequantP0;
    u32 dequantP1;
    u32 q;
    u32 yBlocks;
    u32 texYOffset;
    const u32* dlB;
    u32 pFrameIsIBlock[24];
} fv_decoder_asm_t;

void fv_initDecoder(fv_decoder_t* dec);
void fv_initDecoderAsm(fv_decoder_asm_t* dec);
void fv_decodeFrame(fv_decoder_t* dec, const u16* src, u8* dst);
extern void fv_decodeFrame_asm(fv_decoder_asm_t* dec, const u16* src, u8* dst);
extern const u16* fv_decodePFrameVectors(fv_decoder_asm_t* dec, const u16* src);
extern void fv_decodePFrameDcts(fv_decoder_asm_t* dec, const u16* src, u8* residual);
extern void fv_finishPBlock(fv_decoder_asm_t* dec, const u8* residual, const u16* prediction);

static inline int fv_frameIsP(const u16* src)
{
    return *src >> 15;
}