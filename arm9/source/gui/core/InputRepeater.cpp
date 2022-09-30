#include <nds.h>
#include "InputRepeater.h"

void InputRepeater::Update(const InputProvider* inputProvider)
{
	_trigKeys = inputProvider->GetTriggeredKeys();
	u16 curKeys = inputProvider->GetCurrentKeys();
	_repKeys = 0;
	if (_state != STATE_IDLE)
	{
		if (_state == STATE_FIRST)
		{
			if (curKeys & _mask)
			{
				_frameCounter++;
				if (_frameCounter >= _firstFrame)
				{
					_state = STATE_NEXT;
					_frameCounter = 0;
					_repKeys = curKeys & _mask;
				}
			}
			else
				_state = STATE_IDLE;
		}
		else if (_state == STATE_NEXT)
		{
			if (curKeys & _mask)
			{
				_frameCounter++;
				if (_frameCounter >= _nextFrame)
				{
					_frameCounter = 0;
					_repKeys = curKeys & _mask;
				}
			}
			else
				_state = STATE_IDLE;
		}
	}
	else if (curKeys & _mask)
	{
		_state = STATE_FIRST;
		_frameCounter = 0;
		_repKeys = curKeys & _mask;
	}
}
