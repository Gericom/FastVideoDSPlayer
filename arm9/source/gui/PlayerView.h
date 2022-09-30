#pragma once

#include "core/VramManager.h"
#include "core/OamManager.h"
#include "core/NtftFont.h"

class PlayerView
{
    VramManager _subObj;
    OamManager _subOam;
    NtftFont _robotoRegular10;

    u8 _textTmpBuf[16 * 10];

    u16 _oneDigitObjAddr;
    s8 _oneDigitOffset[10];
    u8 _oneDigitWidth[10];
    s8 _oneDigitEndOffset[10];

    u16 _twoDigitObjAddr;
    s8 _twoDigitOffset[/*100*/60];
    u8 _twoDigitWidth[/*100*/60];
    s8 _twoDigitEndOffset[/*100*/60];

    u16 _colonObjAddr;
    s8 _colonOffset;
    u8 _colonWidth;

    u32 _curTime;

    SpriteEntry _curTimeOams[5];

    u32 _totalTime;
    u32 _invTotalTime;

    SpriteEntry _totalTimeOams[5];

    u16 _circleObjAddr;
    u16 _playIconObjAddr;
    u16 _pauseIconObjAddr;

    bool _playing;

    int RenderColon(SpriteEntry* oam, int x, int y);
    int RenderSingleDigit(SpriteEntry* oam, int digit, int x, int y);
    int RenderDoubleDigit(SpriteEntry* oam, int digits, int x, int y);

public:

    PlayerView();

    void Initialize();
    void Update();
    void VBlank();

    void SetTotalTime(u32 totalTime);
    void SetCurrentTime(u32 currentTime);
    
    void SetPlaying(bool playing)
    {
        _playing = playing;
    }
};
