#pragma once

#include "core/PadInputProvider.h"
#include "core/InputRepeater.h"
#include "../FastVideo/fvPlayer.h"
#include "PlayerView.h"

class PlayerController
{
    enum SubScreenState
    {
        SUB_SCREEN_STATE_ACTIVE,
        SUB_SCREEN_STATE_DIMMING,
        SUB_SCREEN_STATE_OFF
    };

    SubScreenState _subScreenState;
    int _subScreenStateCounter;
    bool _subBacklightOff;

    int _dimWaitFrames;
    int _dimFadeFrames;
    u32 _invDimFadeFrames;

    fv_player_t* _player;
    bool _playing;
    u32 _seekKeyFrame;
    u32 _lastTime;

    bool _seekPenDown;
    bool _playPausePenDown;
    int _seekLastFrame;

    PadInputProvider _inputProvider;
    InputRepeater _inputRepeater;

    PlayerView _view;

    void TogglePlayPause();

    void UpdateTouch();
    void UpdateKeys();
    void UpdateDim();

public:
    PlayerController(fv_player_t* player);

    void Initialize();
    void Update();
};
