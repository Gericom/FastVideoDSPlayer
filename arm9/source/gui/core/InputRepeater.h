#pragma once

#include "InputProvider.h"

class InputRepeater
{
	enum State
	{
		STATE_IDLE,
		STATE_FIRST,
		STATE_NEXT
	};

	u16 _trigKeys;
	u16 _repKeys;
	State _state;
	u16 _frameCounter;
	u16 _mask;
	u16 _firstFrame;
	u16 _nextFrame;
public:
	InputRepeater(u16 mask, u16 firstFrame, u16 nextFrame)
		: _trigKeys(0), _repKeys(0), _state(STATE_IDLE), _frameCounter(0), _mask(mask), _firstFrame(firstFrame), _nextFrame(nextFrame)
	{ }

	void Update(const InputProvider* inputProvider);

	u16 GetTriggeredKeys() const { return _trigKeys | _repKeys; }

    bool Triggered(u16 mask) const
    {
        return (_trigKeys | _repKeys) & mask;
    }
};