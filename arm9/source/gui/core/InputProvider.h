#pragma once

class InputProvider
{
    u16 _currentKeys;
    u16 _triggeredKeys;
    u16 _releasedKeys;

    u16 _inputBuffer[4];
    u8 _inputBufferRPtr;
    u8 _inputBufferWPtr;

  protected:
    InputProvider() : _currentKeys(0), _triggeredKeys(0), _releasedKeys(0), _inputBufferRPtr(0), _inputBufferWPtr(0)
    {
    }

    virtual u16 SampleIntern() = 0;

  public:
    virtual ~InputProvider()
    {
    }

    void Update()
    {
        u16 cur = _currentKeys;
        u16 trig = 0;
        u16 rel = 0;

        while (_inputBufferRPtr != _inputBufferWPtr)
        {
            u16 keyMask = _inputBuffer[_inputBufferRPtr];
            trig |= (keyMask ^ cur) & keyMask;
            rel |= (keyMask ^ cur) & cur;
            cur = keyMask;
            _inputBufferRPtr = (_inputBufferRPtr + 1) & 3;
        }

        _triggeredKeys = trig;
        _releasedKeys = rel;
        _currentKeys = cur;
    }

    /**
     * \brief Returns a bitmask of the keys currently being held
     */
    u16 GetCurrentKeys() const
    {
        return _currentKeys;
    }

    bool Current(u16 mask) const
    {
        return _currentKeys & mask;
    }

    /**
     * \brief Returns a bitmask of the keys that went from unpressed to pressed in the latest update
     */
    u16 GetTriggeredKeys() const
    {
        return _triggeredKeys;
    }

    bool Triggered(u16 mask) const
    {
        return _triggeredKeys & mask;
    }

    /**
     * \brief Returns a bitmask of the keys that went from pressed to unpressed in the latest update
     */
    u16 GetReleasedKeys() const
    {
        return _releasedKeys;
    }

    bool Released(u16 mask) const
    {
        return _releasedKeys & mask;
    }

    void Sample()
    {
        _inputBuffer[_inputBufferWPtr] = SampleIntern();
        _inputBufferWPtr = (_inputBufferWPtr + 1) & 3;
    }

    void Reset()
    {
        _currentKeys = 0;
        _inputBufferRPtr = 0;
        _inputBufferWPtr = 0;
    }
};
