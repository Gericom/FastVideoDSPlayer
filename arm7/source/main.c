#include <nds.h>
#include <nds/fifomessages.h>
#include <string.h>
#include "../../common/ipc.h"
#include "fat/ff.h"
#include "isdprint.h"
#include "fat.h"
#include "fvPlayer7.h"
#include "../../common/twlwram.h"

volatile bool exitflag = false;

static u16 sVBlankTime;
static u16 sLastVBlankTime;
static int sSleepCounter = 0;

enum
{
    KEYXY_TOUCH = (1 << 6),
    KEYXY_LID = (1 << 7)
};

// fixes issue with missing touch inputs
static void inputGetAndSendNew(void)
{
    touchPosition tempPos = { 0 };
    FifoMessage msg = { 0 };

    u16 keys = REG_KEYXY;

    if (!touchPenDown())
        keys |= KEYXY_TOUCH;
    else
        keys &= ~KEYXY_TOUCH;

    msg.SystemInput.keys = keys;

    if (!(keys & KEYXY_TOUCH))
    {
        msg.SystemInput.keys |= KEYXY_TOUCH;

        touchReadXY(&tempPos);

        if (tempPos.rawx && tempPos.rawy)
        {
            msg.SystemInput.keys &= ~KEYXY_TOUCH;
            msg.SystemInput.touch = tempPos;
        }
    }

    if (keys & KEYXY_LID)
        sSleepCounter++;
    else
        sSleepCounter = 0;

    // sleep if lid has been closed for 20 frames
    if (sSleepCounter >= 20)
    {
        systemSleep();
        sSleepCounter = 0;
    }

    msg.type = SYS_INPUT_MESSAGE;

    fifoSendDatamsg(FIFO_SYSTEM, sizeof(msg), (u8*)&msg);
}

void VblankHandler(void)
{
    inputGetAndSendNew();
    if (0 == (REG_KEYINPUT & (KEY_SELECT | KEY_START | KEY_L | KEY_R)))
        exitflag = true;
    int time = sVBlankTime - sLastVBlankTime;
    if (time < 0)
        time += 65536;
    // isnd_printf("%d\n", time);
    sLastVBlankTime = sVBlankTime;
    // if(sTimingStarted)
    // {
    // 	sVblankCount++;
    // 	u64 time = (((u64)TIMER_DATA(0) | ((u64)TIMER_DATA(1) << 16) | ((u64)TIMER_DATA(2) << 32)) + (sVblankCount + 1
    // >> 1)) / sVblankCount; 	isnd_printf("%d\n", (u32)((33513982LL * 10000) / time));
    // }
    // else if (sStartTiming)
    // {
    // 	TIMER_CR(0) = 0;
    // 	TIMER_CR(1) = 0;
    // 	TIMER_CR(2) = 0;

    // 	TIMER_DATA(0) = 0;
    // 	TIMER_DATA(1) = 0;
    // 	TIMER_DATA(2) = 0;

    // 	TIMER_CR(2) = TIMER_CASCADE | TIMER_ENABLE;
    // 	TIMER_CR(1) = TIMER_CASCADE | TIMER_ENABLE;
    // 	TIMER_CR(0) = TIMER_ENABLE;

    // 	sStartTiming = FALSE;
    // 	sTimingStarted = TRUE;
    // }
}

void powerButtonCB()
{
    exitflag = true;
}

extern void enableSound(void);

int main(void)
{
    // clear sound registers
    dmaFillWords(0, (void*)0x04000400, 0x100);

    if (isDSiMode())
    {
        if (twr_isUnlockable())
            twr_unlockAll();

        if (twr_isUnlocked())
        {
            twr_setBlockMapping(TWR_WRAM_BLOCK_B, 0x03100000, 0x40000, TWR_WRAM_BLOCK_IMAGE_SIZE_256K);
            twr_setBlockMapping(TWR_WRAM_BLOCK_C, 0x03140000, 0x40000, TWR_WRAM_BLOCK_IMAGE_SIZE_256K);
        }

        // switch to 47kHz output
        REG_SNDEXTCNT = 0;
        REG_SNDEXTCNT = SNDEXTCNT_FREQ_47KHZ | SNDEXTCNT_RATIO(8);
        cdcWriteReg(CDC_CONTROL, 6, 15);
        cdcWriteReg(CDC_CONTROL, 11, 0x85);
        cdcWriteReg(CDC_CONTROL, 18, 0x85);
        REG_SNDEXTCNT |= SNDEXTCNT_ENABLE;
    }

    enableSound();

    readUserSettings();
    ledBlink(0);

    irqInit();
    initClockIRQ();
    fifoInit();
    touchInit();

    installSystemFIFO();

    irqSet(IRQ_VBLANK, VblankHandler);

    irqEnable(IRQ_VBLANK | IRQ_NETWORK);

    setPowerButtonCB(powerButtonCB);

#ifdef PRINT_DEBUG
    isnd_initPrint();
#endif

    fat_init();
    fv_init();

    swiWaitForVBlank();

    while (!exitflag)
    {
        fv_main();
    }
    return 0;
}
