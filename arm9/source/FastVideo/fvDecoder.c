#include <nds.h>
#include "fvConst.h"
#include "fvDecoder.h"

void fv_initDecoderAsm(fv_decoder_asm_t* dec)
{
    dec->q = 0xFF;
    for(int i = 0; i < 64; i++)
        dec->qTab[i] = fv_gDCTQTab2x2[i];
    dec->clampTable = &fv_gClampTable[32];
    dec->vlcIdxTab = fv_gVlcIdxTab;
    dec->vlcBitTab2 = fv_gVlcBitTab2;
    dec->vlcPackTab = fv_gVlcPackTab;
    dec->dequant0 = 32 | (23 << 16);
    dec->dequant1 = 23 | (64 << 16);
    dec->dequantP0 = 32 | (23 << 16);
    dec->dequantP1 = 23 | (64 << 16);
    // dec->dequantP0 = 32 | (36 << 16);
    // dec->dequantP1 = 36 | (48 << 16);
    // dec->dequant0 = 64 | (46 << 16);
    // dec->dequant1 = 46 | (128 << 16);
}