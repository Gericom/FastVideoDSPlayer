#include <nds.h>
#include <string.h>
#include "isdprint.h"
#include "../../common/ipc.h"
#include "fat.h"
#include "adpcm.h"
#include "irqWait.h"
#include "fvPlayer7.h"

#define FV_AUDIO_START_OFFSET 12

#define FV_AUDIO_CH_LEFT  1
#define FV_AUDIO_CH_RIGHT 3

static fv_player7_t sPlayer;

void fv_init(void)
{
    memset(&sPlayer, 0, sizeof(sPlayer));
}

static inline int getAudioTimerValue(int rate)
{
    return (16756991 + ((rate + 1) >> 1)) / rate;
}

static void audioFrameIrq(void)
{
}

static void decodeAudioFrame(void)
{
    adpcm_decompress(sPlayer.audioQueueL[sPlayer.queueReadPtr], FV_AUDIO_FRAME_SIZE,
                     sPlayer.audioRingL[sPlayer.ringPos]);
    adpcm_decompress(sPlayer.audioQueueR[sPlayer.queueReadPtr], FV_AUDIO_FRAME_SIZE,
                     sPlayer.audioRingR[sPlayer.ringPos]);

    // sPlayer.ringVideoFrameIds[sPlayer.ringPos] = sPlayer.queueVideoFrameIds[sPlayer.queueReadPtr];

    if (++sPlayer.ringPos == FV_AUDIO_RING_FRAMES)
        sPlayer.ringPos = 0;

    if (++sPlayer.queueReadPtr == FV_AUDIO_QUEUE_FRAMES)
        sPlayer.queueReadPtr = 0;

    sPlayer.queueFrameCount--;

    sPlayer.audioFramesNeeded--;
    sPlayer.audioFramesProvided++;
}

static void startAudio(void)
{
    if (sPlayer.audioStarted)
        return;

    sPlayer.ringPos = 0;
    sPlayer.audioFramesNeeded = 0;
    sPlayer.audioFramesProvided = 0;

    for (int i = 0; i < FV_AUDIO_START_OFFSET; i++)
    {
        if (sPlayer.queueFrameCount == 0)
            break;
        decodeAudioFrame();
    }

    sPlayer.audioFramesProvided -= FV_AUDIO_START_OFFSET;

    int tmr = getAudioTimerValue(FV_AUDIO_RATE);
    SCHANNEL_SOURCE(FV_AUDIO_CH_LEFT) = (u32)sPlayer.audioRingL;
    SCHANNEL_REPEAT_POINT(FV_AUDIO_CH_LEFT) = 0;
    SCHANNEL_LENGTH(FV_AUDIO_CH_LEFT) = sizeof(sPlayer.audioRingL) >> 2;
    SCHANNEL_TIMER(FV_AUDIO_CH_LEFT) = -tmr;

    SCHANNEL_SOURCE(FV_AUDIO_CH_RIGHT) = (u32)sPlayer.audioRingR;
    SCHANNEL_REPEAT_POINT(FV_AUDIO_CH_RIGHT) = 0;
    SCHANNEL_LENGTH(FV_AUDIO_CH_RIGHT) = sizeof(sPlayer.audioRingR) >> 2;
    SCHANNEL_TIMER(FV_AUDIO_CH_RIGHT) = -tmr;

    TIMER_CR(0) = 0;
    TIMER_CR(1) = 0;
    TIMER_CR(2) = 0;
    TIMER_CR(3) = 0;

    TIMER_DATA(0) = -2;   // 1/2 clock divider
    TIMER_DATA(1) = -tmr; // sample rate
    TIMER_DATA(2) = -256; // length of audio frame
    TIMER_DATA(3) = 0;    // audio block counter

    TIMER_CR(3) = TIMER_CASCADE | TIMER_ENABLE;
    TIMER_CR(2) = TIMER_CASCADE | TIMER_ENABLE | TIMER_IRQ_REQ;
    TIMER_CR(1) = TIMER_CASCADE | TIMER_ENABLE;

    irqSet(IRQ_TIMER2, audioFrameIrq);
    irqEnable(IRQ_TIMER2);

    SCHANNEL_CR(FV_AUDIO_CH_LEFT) =
        SCHANNEL_ENABLE | SOUND_VOL(0x7F) | SOUND_PAN(0) | SOUND_FORMAT_16BIT | SOUND_REPEAT;
    SCHANNEL_CR(FV_AUDIO_CH_RIGHT) =
        SCHANNEL_ENABLE | SOUND_VOL(0x7F) | SOUND_PAN(0x7F) | SOUND_FORMAT_16BIT | SOUND_REPEAT;
    TIMER_CR(0) = TIMER_ENABLE;

    sPlayer.audioStarted = true;
}

static void stopAudio(void)
{
    if (!sPlayer.audioStarted)
        return;

    sPlayer.audioStarted = false;
    TIMER_CR(0) = 0;
    irqDisable(IRQ_TIMER2);
    SCHANNEL_CR(FV_AUDIO_CH_LEFT) = 0;
    SCHANNEL_CR(FV_AUDIO_CH_RIGHT) = 0;
    TIMER_CR(1) = 0;
    TIMER_CR(2) = 0;
    TIMER_CR(3) = 0;
    sPlayer.ringPos = 0;
    memset(&sPlayer.audioRingL[0][0], 0, sizeof(sPlayer.audioRingL));
    memset(&sPlayer.audioRingR[0][0], 0, sizeof(sPlayer.audioRingR));
}

static void updateAudio(void)
{
    if (!sPlayer.audioStarted)
        return;

    int audioBlocks = TIMER_DATA(3);
    int needed = audioBlocks - (sPlayer.audioFramesProvided & 0xFFFF);
    if (needed < 0)
        needed += 65536;

    while (needed > 0 && sPlayer.queueFrameCount > 0)
    {
        decodeAudioFrame();
        needed--;
    }
}

static void gotoKeyFrameDirect(const fv_keyframe_t* keyFrameData)
{
    f_lseek(&sPlayer.file, keyFrameData->offset);

    // reset player state
    stopAudio();

    sPlayer.ringPos = 0;
    sPlayer.queueReadPtr = 0;
    sPlayer.queueWritePtr = 0;
    sPlayer.queueFrameCount = 0;
    sPlayer.audioFramesNeeded = 0;
    sPlayer.audioFramesProvided = 0;

    memset(&sPlayer.audioQueueL[0][0], 0, sizeof(sPlayer.audioQueueL));
    memset(&sPlayer.audioQueueR[0][0], 0, sizeof(sPlayer.audioQueueR));
}

static u32 gotoKeyFrame(u32 keyFrame)
{
    UINT br;
    fv_keyframe_t keyFrameData;

    f_lseek(&sPlayer.file, sizeof(fv_header_t) + sizeof(fv_keyframe_t) * keyFrame);
    f_read(&sPlayer.file, &keyFrameData, sizeof(fv_keyframe_t), &br);

    gotoKeyFrameDirect(&keyFrameData);

    return keyFrameData.frame;
}

static u32 gotoNearestKeyFrame(u32 frame, u32* resultFrame)
{
    UINT br;
    fv_keyframe_t keyFrameData = { 0 };
    fv_keyframe_t newKeyFrameData;
    u32 keyFrameId = -1;

    f_lseek(&sPlayer.file, sizeof(fv_header_t));

    for (int i = 0; i < sPlayer.nrKeyFrames; i++)
    {
        f_read(&sPlayer.file, &newKeyFrameData, sizeof(fv_keyframe_t), &br);
        if (newKeyFrameData.frame <= frame)
        {
            keyFrameData = newKeyFrameData;
            keyFrameId = i;
        }

        if (newKeyFrameData.frame >= frame)
            break;
    }

    gotoKeyFrameDirect(&keyFrameData);

    if (resultFrame)
        *resultFrame = keyFrameData.frame;

    return keyFrameId;
}

static void handleFifo(u32 value)
{
    UINT br;

    switch (value >> IPC_CMD_CMD_SHIFT)
    {
        case IPC_CMD_READ_FRAME:
        {
            u32 len;
            if (f_read(&sPlayer.file, &len, 4, &br) != FR_OK || br != 4)
            {
                fifoSendValue32(FIFO_USER_01, IPC_CMD_PACK(IPC_CMD_READ_FRAME, 0));
                break;
            }
            f_read(&sPlayer.file, (void*)(value & IPC_CMD_ARG_MASK), len & 0x1FFFF, &br);
            fifoSendValue32(FIFO_USER_01, IPC_CMD_PACK(IPC_CMD_READ_FRAME, len & 0x1FFFF));
            // read audio frames
            u32 audioFrames = len >> 17;
            for (int i = 0; i < audioFrames; i++)
            {
                f_read(&sPlayer.file, sPlayer.audioQueueL[sPlayer.queueWritePtr], FV_AUDIO_FRAME_SIZE, &br);
                f_read(&sPlayer.file, sPlayer.audioQueueR[sPlayer.queueWritePtr], FV_AUDIO_FRAME_SIZE, &br);
                // sPlayer.queueVideoFrameIds[sPlayer.queueWritePtr] = sPlayer.curVideoFrame;
                if (++sPlayer.queueWritePtr == FV_AUDIO_QUEUE_FRAMES)
                    sPlayer.queueWritePtr = 0;

                sPlayer.queueFrameCount++;
            }

            // sPlayer.curVideoFrame++;
            break;
        }

        case IPC_CMD_OPEN_FILE:
        {
            FRESULT result = f_open(&sPlayer.file, (const char*)(value & IPC_CMD_ARG_MASK), FA_OPEN_EXISTING | FA_READ);
            if (result != FR_OK)
                fifoSendValue32(FIFO_USER_01, IPC_CMD_PACK(IPC_CMD_OPEN_FILE, 0));
            else
                fifoSendValue32(FIFO_USER_01, IPC_CMD_PACK(IPC_CMD_OPEN_FILE, 1));
            break;
        }

        case IPC_CMD_READ_HEADER:
        {
            fv_header_t* header = (fv_header_t*)(value & IPC_CMD_ARG_MASK);
            f_read(&sPlayer.file, header, sizeof(fv_header_t), &br);

            sPlayer.nrKeyFrames = header->nrKeyFrames;

            gotoKeyFrame(0);

            u32 num = header->fpsNum;
            u32 den = header->fpsDen;

            int vblankCount = 1;
            while (num * (vblankCount + 1) / den < 62)
                vblankCount++;

            // safety
            if (num * vblankCount / den < 62)
            {
                fpsa_init(&sPlayer.fpsa);
                fpsa_setTargetFpsFraction(&sPlayer.fpsa, num * vblankCount, den);
                sPlayer.fpsa.targetCycles =
                    (double)sPlayer.fpsa.targetCycles * getAudioTimerValue(FV_AUDIO_RATE) * FV_AUDIO_RATE / 16756991.0;
                fpsa_start(&sPlayer.fpsa);
            }

            fifoSendValue32(FIFO_USER_01, IPC_CMD_PACK(IPC_CMD_READ_HEADER, vblankCount));
            break;
        }

        case IPC_CMD_GOTO_KEYFRAME:
        {
            u32 frame = gotoKeyFrame(value & IPC_CMD_ARG_MASK);
            fifoSendValue32(FIFO_USER_01, IPC_CMD_PACK(IPC_CMD_GOTO_KEYFRAME, frame));
            break;
        }

        case IPC_CMD_GOTO_NEAREST_KEYFRAME:
        {
            u32 frame = value & IPC_CMD_ARG_MASK;
            u32 resultFrame;
            u32 keyFrame = gotoNearestKeyFrame(frame, &resultFrame);
            fifoSendValue32(FIFO_USER_01, IPC_CMD_PACK(IPC_CMD_GOTO_NEAREST_KEYFRAME, keyFrame));
            fifoSendValue32(FIFO_USER_01, IPC_CMD_PACK(IPC_CMD_GOTO_KEYFRAME, resultFrame));
            break;
        }

        case IPC_CMD_CONTROL_AUDIO:
        {
            if ((value & IPC_CMD_ARG_MASK) == IPC_ARG_CONTROL_AUDIO_START)
                startAudio();
            else if ((value & IPC_CMD_ARG_MASK) == IPC_ARG_CONTROL_AUDIO_STOP)
                stopAudio();
            else if ((value & IPC_CMD_ARG_MASK) == IPC_ARG_CONTROL_AUDIO_STOP_CLEAR)
            {
                stopAudio();
                sPlayer.ringPos = 0;
                sPlayer.queueReadPtr = 0;
                sPlayer.queueWritePtr = 0;
                sPlayer.queueFrameCount = 0;
                sPlayer.audioFramesNeeded = 0;
                sPlayer.audioFramesProvided = 0;

                memset(&sPlayer.audioQueueL[0][0], 0, sizeof(sPlayer.audioQueueL));
                memset(&sPlayer.audioQueueR[0][0], 0, sizeof(sPlayer.audioQueueR));
            }
            break;
        }

        case IPC_CMD_SETUP_DLDI:
        {
            if (!isDSiMode())
            {
                memcpy((void*)0x037F8000, (void*)(value & IPC_CMD_ARG_MASK), 16 * 1024);
                fat_mountDldi();
            }
            fifoSendValue32(FIFO_USER_01, IPC_CMD_PACK(IPC_CMD_SETUP_DLDI, 0));
            break;
        }

        case IPC_CMD_HANDSHAKE:
            fifoSendValue32(FIFO_USER_01, IPC_CMD_PACK(IPC_CMD_HANDSHAKE, 0));
            break;
    }
}

void fv_main(void)
{
    if (!fifoCheckValue32(FIFO_USER_01))
        irq_wait(false, IRQ_TIMER2 | IRQ_FIFO_NOT_EMPTY);

    updateAudio();

    if (fifoCheckValue32(FIFO_USER_01))
        handleFifo(fifoGetValue32(FIFO_USER_01));
}
