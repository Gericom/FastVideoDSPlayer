#include <nds.h>
#include <stdio.h>
#include "../../common/ipc.h"
#include "FastVideo/fvDecoder.h"
#include "FastVideo/fvMcData.h"
#include "FastVideo/fvPlayer.h"
#include "mpu.h"
#include "gui/PlayerController.h"
#include "../../common/twlwram.h"

static DTCM_BSS fv_player_t sPlayer;

static PlayerController* sPlayerController;

extern u8 gDldiStub[];

int main(int argc, char** argv)
{
    DC_FlushAll();

    mpu_enableVramCache();

    bool canUseWram = false;
    if (isDSiMode() && twr_isUnlocked())
    {
        twr_setBlockMapping(TWR_WRAM_BLOCK_A, 0x03000000, 0x40000, TWR_WRAM_BLOCK_IMAGE_SIZE_256K);
        twr_setBlockMapping(TWR_WRAM_BLOCK_B, 0x03100000, 0x40000, TWR_WRAM_BLOCK_IMAGE_SIZE_256K);
        twr_setBlockMapping(TWR_WRAM_BLOCK_C, 0x03140000, 0x40000, TWR_WRAM_BLOCK_IMAGE_SIZE_256K);
        mpu_enableTwlWramCache();
        canUseWram = true;
    }

    fifoSetValue32Handler(FIFO_USER_01, NULL, NULL);

    // handshake
    fifoSendValue32(FIFO_USER_01, IPC_CMD_PACK(IPC_CMD_HANDSHAKE, 0));
    fifoWaitValue32(FIFO_USER_01);
    u32 handShake = fifoGetValue32(FIFO_USER_01);

    if (canUseWram && (handShake & IPC_CMD_ARG_MASK) == 0)
        canUseWram = false;

    if (!isDSiMode())
    {
        // setup dldi on arm7 if not on dsi
        DC_FlushRange(gDldiStub, 16 * 1024);
        fifoSendValue32(FIFO_USER_01, IPC_CMD_PACK(IPC_CMD_SETUP_DLDI, (u32)gDldiStub));
        fifoWaitValue32(FIFO_USER_01);
        fifoGetValue32(FIFO_USER_01);
    }

    videoSetModeSub(MODE_0_2D);
    vramSetBankH(VRAM_H_SUB_BG);
    vramSetBankI(VRAM_I_SUB_SPRITE);

    consoleInit(NULL, 2, BgType_Text4bpp, BgSize_T_256x256, /*0, 1*/ 2, 1, false, true);

    // iprintf("FastVideoDS Player by Gericom\n\n");

    vramSetBankA(VRAM_A_LCD);
    vramSetBankB(VRAM_B_LCD);
    vramSetBankC(VRAM_C_LCD);
    vramSetBankD(VRAM_D_LCD);
    vramSetBankE(VRAM_E_LCD);

    for (int i = 0; i < 3 * 128 * 1024; i += 4)
        *(vu32*)((u32)VRAM_A + i) = 0x80008000;

    const char* filePath;

    if (isDSiMode())
        filePath = "sd:/testVideo.fv";
    else
        filePath = "fat:/testVideo.fv";

    if (argc >= 2)
        filePath = argv[1];

    // iprintf("Playing %s\n", filePath);
    if (fv_initPlayer(&sPlayer, filePath, canUseWram))
    {
        sPlayerController = new PlayerController(&sPlayer);
        sPlayerController->Initialize();
        fv_startPlayer(&sPlayer);
        while (1)
            sPlayerController->Update();
    }
    fv_destroyPlayer(&sPlayer);
    while (1)
        swiWaitForVBlank();

    return 0;
}
