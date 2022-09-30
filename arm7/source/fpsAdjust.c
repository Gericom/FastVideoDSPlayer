#include <nds.h>
#include <string.h>
#include <math.h>
#include "fpsAdjust.h"
#include "isdprint.h"

static fpsa_t* sActiveFpsa = NULL;

static void vcountIrqLower()
{
    while (1)
    {
        if (sActiveFpsa->initial)
        {
            sActiveFpsa->initial = FALSE;
            break;
        }

        if (!sActiveFpsa->backJump)
            sActiveFpsa->cycleDelta += sActiveFpsa->targetCycles - ((u64)FPSA_CYCLES_PER_FRAME << 24);
        u32 linesToAdd = 0;
        while (sActiveFpsa->cycleDelta >= (s64)((u64)FPSA_CYCLES_PER_LINE << 23))
        {
            sActiveFpsa->cycleDelta -= (u64)FPSA_CYCLES_PER_LINE << 24;
            if (++linesToAdd == 5)
                break;
        }
        if (linesToAdd == 0)
        {
            sActiveFpsa->backJump = FALSE;
            break;
        }
        if (linesToAdd > 1)
        {
            sActiveFpsa->backJump = TRUE;
        }
        else
        {
            // don't set the backJump flag because the irq is not retriggered if the new vcount
            // is the same as the previous line
            sActiveFpsa->backJump = FALSE;
        }
        // ensure we won't accidentally run out of line time
        while (REG_DISPSTAT & DISP_IN_HBLANK)
            ;
        int curVCount = REG_VCOUNT;
        REG_VCOUNT = curVCount - (linesToAdd - 1);
        if (linesToAdd == 1)
            break;

        while (REG_VCOUNT >= curVCount)//FPSA_ADJUST_MAX_VCOUNT - 5)
            ;
        while (REG_VCOUNT < curVCount)//FPSA_ADJUST_MAX_VCOUNT - 5)
            ;
    }
    REG_IF = IRQ_VCOUNT;
}

static void vcountIrqHigher()
{
    if (sActiveFpsa->initial)
    {
        sActiveFpsa->initial = FALSE;
        return;
    }
    sActiveFpsa->cycleDelta += ((u64)FPSA_CYCLES_PER_FRAME << 24) - sActiveFpsa->targetCycles;
    u32 linesToSkip = 0;
    while (sActiveFpsa->cycleDelta >= (s64)((u64)FPSA_CYCLES_PER_LINE << 23))
    {
        sActiveFpsa->cycleDelta -= (u64)FPSA_CYCLES_PER_LINE << 24;
        if (++linesToSkip == 5)
            break;
    }
    if (linesToSkip == 0)
        return;
    // ensure we won't accidentally run out of line time
    while (REG_DISPSTAT & DISP_IN_HBLANK)
        ;
    REG_VCOUNT = REG_VCOUNT + (linesToSkip + 1);
}

void fpsa_init(fpsa_t* fpsa)
{
    memset(fpsa, 0, sizeof(fpsa_t));
    fpsa->isStarted = FALSE;
    fpsa_setTargetFrameCycles(fpsa, (u64)FPSA_CYCLES_PER_FRAME << 24); // default to no adjustment
}

void fpsa_start(fpsa_t* fpsa)
{
    int irq = enterCriticalSection();
    do
    {
        if (fpsa->isStarted || sActiveFpsa)
            break;
        if (fpsa->targetCycles == ((u64)FPSA_CYCLES_PER_FRAME << 24))
            break;
        irqDisable(IRQ_VCOUNT);
        sActiveFpsa = fpsa;
        fpsa->backJump = FALSE;
        fpsa->cycleDelta = 0;
        fpsa->initial = TRUE;
        fpsa->isFpsLower = fpsa->targetCycles >= ((u64)FPSA_CYCLES_PER_FRAME << 24);
        // prevent the irq from immediately happening
        while (REG_VCOUNT != FPSA_ADJUST_MAX_VCOUNT + 2)
            ;
        fpsa->isStarted = TRUE;
        if (fpsa->isFpsLower)
        {
            SetYtrigger(FPSA_ADJUST_MAX_VCOUNT - 5);
            irqSet(IRQ_VCOUNT, vcountIrqLower);
        }
        else
        {
            SetYtrigger(FPSA_ADJUST_MIN_VCOUNT);
            irqSet(IRQ_VCOUNT, vcountIrqHigher);
        }
        irqEnable(IRQ_VCOUNT);
    } while (0);
    leaveCriticalSection(irq);
}

void fpsa_stop(fpsa_t* fpsa)
{
    if (!fpsa->isStarted)
        return;
    sActiveFpsa = NULL;
    fpsa->isStarted = FALSE;
    irqDisable(IRQ_VCOUNT);
}

void fpsa_setTargetFrameCycles(fpsa_t* fpsa, u64 cycles)
{
    fpsa->targetCycles = cycles;
}

void fpsa_setTargetFpsFraction(fpsa_t* fpsa, u32 num, u32 den)
{
    u64 cycles = (((double)FPSA_SYS_CLOCK * den * (1 << 24)) / num) + 0.5;
    fpsa_setTargetFrameCycles(fpsa, cycles);//((((u64)FPSA_SYS_CLOCK * (u64)den) << 24) + ((num + 1) >> 1)) / num);
}