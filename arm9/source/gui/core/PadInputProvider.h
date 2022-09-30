#pragma once
#include "InputProvider.h"

class PadInputProvider : public InputProvider
{
public:
    u16 SampleIntern()
    {
        return keysCurrent();
    }
};
