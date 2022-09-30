#include <nds.h>
#include <stdio.h>
#include "RobotoRegular10_ntft.h"
#include "playBg.h"
#include "iconPlay.h"
#include "iconPause.h"
#include "circle0.h"
#include "circle1.h"
#include "core/uiUtil.h"
#include "PlayerView.h"

PlayerView::PlayerView() : _robotoRegular10(RobotoRegular10_ntft)
{
}

void PlayerView::Initialize()
{
    decompress(playBgTiles, BG_GFX_SUB, LZ77Vram);
    decompress(playBgMap, (u8*)BG_GFX_SUB + 0x800, LZ77Vram);
    dmaCopyWords(3, playBgPal, BG_PALETTE_SUB, playBgPalLen);

    _subOam.Apply(OAM_SUB);

    REG_DISPCNT_SUB = DISPLAY_BG0_ACTIVE | DISPLAY_BG1_ACTIVE | DISPLAY_BG2_ACTIVE | DISPLAY_SPR_ACTIVE |
                      DISPLAY_SPR_1D | DISPLAY_SPR_1D_SIZE_32 | MODE_0_2D | DISPLAY_WIN0_ON;

    REG_BG2CNT_SUB &= ~BG_PRIORITY_3;

    REG_BG0CNT_SUB = BG_32x32 | BG_PRIORITY_2 | BG_COLOR_16 | BG_MAP_BASE(1) | BG_TILE_BASE(0);
    REG_BG0HOFS_SUB = 0;
    REG_BG0VOFS_SUB = 0;

    REG_BG1CNT_SUB = BG_32x32 | BG_PRIORITY_1 | BG_COLOR_16 | BG_MAP_BASE(1) | BG_TILE_BASE(0);
    REG_BG1HOFS_SUB = 0;
    REG_BG1VOFS_SUB = -176;

    SUB_WIN0_X0 = 16;
    SUB_WIN0_X1 = 128;
    SUB_WIN0_Y0 = 117;
    SUB_WIN0_Y1 = 117 + 4;

    SUB_WIN_IN = 0x16;
    SUB_WIN_OUT = 0x15;

    for (int i = 0; i < 16; i++)
    {
        int rnew = 4 + ((31 - 4) * i) / 15;
        int gnew = 6 + ((31 - 6) * i) / 15;
        int bnew = 8 + ((31 - 8) * i) / 15;
        SPRITE_PALETTE_SUB[16 + i] = RGB5(rnew, gnew, bnew);
    }

    for (int i = 0; i < 16; i++)
    {
        int rnew = 6 + ((31 - 6) * i) / 15;
        int gnew = 8 + ((31 - 8) * i) / 15;
        int bnew = 11 + ((31 - 11) * i) / 15;
        SPRITE_PALETTE_SUB[32 + i] = RGB5(rnew, gnew, bnew);
    }

    for (int i = 0; i < 16; i++)
    {
        int rnew = 4 + ((6 - 4) * i) / 15;
        int gnew = 6 + ((8 - 6) * i) / 15;
        int bnew = 8 + ((11 - 8) * i) / 15;
        SPRITE_PALETTE_SUB[48 + i] = RGB5(rnew, gnew, bnew);
    }

    _twoDigitObjAddr = _subObj.Alloc(/*100*/ 60 * 2 * 32) >> 5;
    char twoDigitStr[3];
    for (int i = 0; i < /*100*/ 60; i++)
    {
        memset(_textTmpBuf, 0, sizeof(_textTmpBuf));
        twoDigitStr[0] = '0' + ((u32)i / 10);
        twoDigitStr[1] = '0' + ((u32)i % 10);
        twoDigitStr[2] = 0;
        int w, h;
        _robotoRegular10.MeasureString(twoDigitStr, w, h);
        const ntft_cinfo_char_t* charInfo = _robotoRegular10.GetCharInfo(twoDigitStr[0]);
        _twoDigitOffset[i] = charInfo->characterBeginOffset < 0 ? charInfo->characterBeginOffset : 0;
        charInfo = _robotoRegular10.GetCharInfo(twoDigitStr[1]);
        _twoDigitWidth[i] = w;
        _twoDigitEndOffset[i] = charInfo->characterEndOffset;
        _robotoRegular10.CreateStringData(twoDigitStr, _textTmpBuf, 16);
        uiutil_convertToObj(_textTmpBuf + 2 * 16, 16, 8, 16, &SPRITE_GFX_SUB[(_twoDigitObjAddr + 2 * i) << 4]);
    }

    _oneDigitObjAddr = _subObj.Alloc(10 * 32) >> 5;
    for (int i = 0; i < 10; i++)
    {
        memset(_textTmpBuf, 0, sizeof(_textTmpBuf));
        twoDigitStr[0] = '0' + i;
        twoDigitStr[1] = 0;
        int w, h;
        _robotoRegular10.MeasureString(twoDigitStr, w, h);
        const ntft_cinfo_char_t* charInfo = _robotoRegular10.GetCharInfo(twoDigitStr[0]);
        _oneDigitOffset[i] = charInfo->characterBeginOffset < 0 ? charInfo->characterBeginOffset : 0;
        _oneDigitWidth[i] = w;
        _oneDigitEndOffset[i] = charInfo->characterEndOffset;
        _robotoRegular10.CreateStringData(twoDigitStr, _textTmpBuf, 8);
        uiutil_convertToObj(_textTmpBuf + 2 * 8, 8, 8, 8, &SPRITE_GFX_SUB[(_oneDigitObjAddr + i) << 4]);
    }

    _colonObjAddr = _subObj.Alloc(32) >> 5;
    memset(_textTmpBuf, 0, sizeof(_textTmpBuf));
    twoDigitStr[0] = ':';
    twoDigitStr[1] = 0;
    int w, h;
    _robotoRegular10.MeasureString(twoDigitStr, w, h);
    const ntft_cinfo_char_t* charInfo = _robotoRegular10.GetCharInfo(twoDigitStr[0]);
    _colonOffset = charInfo->characterBeginOffset < 0 ? charInfo->characterBeginOffset : 0;
    _colonWidth = w + charInfo->characterEndOffset;
    _robotoRegular10.CreateStringData(twoDigitStr, _textTmpBuf, 8);
    uiutil_convertToObj(_textTmpBuf + 2 * 8, 8, 8, 8, &SPRITE_GFX_SUB[_colonObjAddr << 4]);

    SetCurrentTime(0 * 60 * 60 + 16 * 60 + 27);
    SetTotalTime(3 * 60 * 60 + 48 * 60 + 59);

    _circleObjAddr = _subObj.Alloc(32 * 20) >> 5;
    dmaCopyWords(3, circle0Tiles, &SPRITE_GFX_SUB[_circleObjAddr << 4], circle0TilesLen);
    dmaCopyWords(3, circle1Tiles, &SPRITE_GFX_SUB[(_circleObjAddr + 16) << 4], circle1TilesLen);

    _playIconObjAddr = _subObj.Alloc(32 * 4) >> 5;
    dmaCopyWords(3, iconPlayTiles, &SPRITE_GFX_SUB[_playIconObjAddr << 4], iconPlayTilesLen);
    _pauseIconObjAddr = _subObj.Alloc(32 * 4) >> 5;
    dmaCopyWords(3, iconPauseTiles, &SPRITE_GFX_SUB[_pauseIconObjAddr << 4], iconPauseTilesLen);

    _playing = false;
}

int PlayerView::RenderColon(SpriteEntry* oam, int x, int y)
{
    x += _colonOffset;

    oam[0].attribute[0] = ATTR0_NORMAL | ATTR0_TYPE_NORMAL | ATTR0_COLOR_16 | ATTR0_SQUARE | y; // OBJ_Y(y);
    oam[0].attribute[1] = ATTR1_SIZE_8 | x;                                                     // OBJ_X(x);
    oam[0].attribute[2] = ATTR2_PRIORITY(3) | ATTR2_PALETTE(1) | _colonObjAddr;

    return x + _colonWidth;
}

int PlayerView::RenderSingleDigit(SpriteEntry* oam, int digit, int x, int y)
{
    x += _oneDigitOffset[digit];

    oam[0].attribute[0] = ATTR0_NORMAL | ATTR0_TYPE_NORMAL | ATTR0_COLOR_16 | ATTR0_SQUARE | y; // OBJ_Y(y);
    oam[0].attribute[1] = ATTR1_SIZE_8 | x;                                                     // OBJ_X(x);
    oam[0].attribute[2] = ATTR2_PRIORITY(3) | ATTR2_PALETTE(1) | (_oneDigitObjAddr + digit);

    return x + _oneDigitWidth[digit] + _oneDigitEndOffset[digit];
}

int PlayerView::RenderDoubleDigit(SpriteEntry* oam, int digits, int x, int y)
{
    x += _twoDigitOffset[digits];

    oam[0].attribute[0] = ATTR0_NORMAL | ATTR0_TYPE_NORMAL | ATTR0_COLOR_16 | ATTR0_WIDE | y; // OBJ_Y(y);
    oam[0].attribute[1] = ATTR1_SIZE_8 | x;                                                   // OBJ_X(x);
    oam[0].attribute[2] = ATTR2_PRIORITY(3) | ATTR2_PALETTE(1) | (_twoDigitObjAddr + digits * 2);

    return x + _twoDigitWidth[digits] + _twoDigitEndOffset[digits];
}

void PlayerView::Update()
{
    _subOam.Clear();

    SpriteEntry* oams = _subOam.AllocOams(14);
    memcpy(&oams[0], _curTimeOams, sizeof(_curTimeOams));
    memcpy(&oams[5], _totalTimeOams, sizeof(_totalTimeOams));

    // circle
    oams[11].attribute[0] = ATTR0_NORMAL | ATTR0_TYPE_NORMAL | ATTR0_COLOR_16 | ATTR0_SQUARE | 140;
    oams[11].attribute[1] = ATTR1_SIZE_32 | 110;
    oams[11].attribute[2] = ATTR2_PRIORITY(3) | ATTR2_PALETTE(3) | _circleObjAddr;
    oams[12].attribute[0] = ATTR0_NORMAL | ATTR0_TYPE_NORMAL | ATTR0_COLOR_16 | ATTR0_TALL | 140;
    oams[12].attribute[1] = ATTR1_SIZE_16 | (110 + 32);
    oams[12].attribute[2] = ATTR2_PRIORITY(3) | ATTR2_PALETTE(3) | (_circleObjAddr + 16);
    oams[13].attribute[0] = ATTR0_NORMAL | ATTR0_TYPE_NORMAL | ATTR0_COLOR_16 | ATTR0_WIDE | (140 + 32 - 4);
    oams[13].attribute[1] = ATTR1_SIZE_16 | ATTR1_FLIP_Y | 110;
    oams[13].attribute[2] = ATTR2_PRIORITY(3) | ATTR2_PALETTE(3) | _circleObjAddr;

    // play/pause
    oams[10].attribute[0] = ATTR0_NORMAL | ATTR0_TYPE_NORMAL | ATTR0_COLOR_16 | ATTR0_SQUARE | (146 + 4);
    oams[10].attribute[1] = ATTR1_SIZE_16 | (116 + 4);
    oams[10].attribute[2] = ATTR2_PRIORITY(3) | ATTR2_PALETTE(2) | (_playing ? _pauseIconObjAddr : _playIconObjAddr);
}

void PlayerView::VBlank()
{
    _subOam.Apply(OAM_SUB);

    SUB_WIN0_X0 = 16;
    u32 width;
    if (_curTime >= _totalTime)
        width = 224;
    else
        width = (_curTime * 224 * _invTotalTime + 0x400000) >> 23;
    SUB_WIN0_X1 = 16 + width;
    SUB_WIN0_Y0 = 117;
    SUB_WIN0_Y1 = 117 + 4;
}

void PlayerView::SetTotalTime(u32 totalTime)
{
    _totalTime = totalTime;

    _invTotalTime = 0x800000 / _totalTime;

    u32 totalH = _totalTime / 3600;
    u32 totalM = _totalTime / 60 % 60;
    u32 totalS = _totalTime % 60;

    int x = 240;
    x -= _twoDigitWidth[totalS];
    x -= _twoDigitOffset[totalS];
    x -= _colonWidth;
    x -= _colonOffset;
    x -= _twoDigitEndOffset[totalM];
    x -= _twoDigitWidth[totalM];
    x -= _twoDigitOffset[totalM];
    if (totalH != 0)
    {
        x -= _colonWidth;
        x -= _colonOffset;
        x -= _oneDigitEndOffset[totalH];
        x -= _oneDigitWidth[totalH];
        x -= _oneDigitOffset[totalH];
        x = RenderSingleDigit(&_totalTimeOams[0], totalH, x, 101);
        x = RenderColon(&_totalTimeOams[1], x, 101);
    }
    else
    {
        _totalTimeOams[0].attribute[0] = 0x200;
        _totalTimeOams[1].attribute[0] = 0x200;
    }
    x = RenderDoubleDigit(&_totalTimeOams[2], totalM, x, 101);
    x = RenderColon(&_totalTimeOams[3], x, 101);
    x = RenderDoubleDigit(&_totalTimeOams[4], totalS, x, 101);
}

void PlayerView::SetCurrentTime(u32 currentTime)
{
    _curTime = currentTime;

    int x = 16;
    if (_totalTime >= 3600)
    {
        x = RenderSingleDigit(&_curTimeOams[0], _curTime / 3600, x, 101);
        x = RenderColon(&_curTimeOams[1], x, 101);
    }
    else
    {
        _curTimeOams[0].attribute[0] = 0x200;
        _curTimeOams[1].attribute[0] = 0x200;
    }
    x = RenderDoubleDigit(&_curTimeOams[2], _curTime / 60 % 60, x, 101);
    x = RenderColon(&_curTimeOams[3], x, 101);
    x = RenderDoubleDigit(&_curTimeOams[4], _curTime % 60, x, 101);
}