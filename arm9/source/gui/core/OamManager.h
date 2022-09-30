#pragma once
#include <string.h>

class OamManager
{
    SpriteEntry* _oamPtr;
    int _mtxIdx;
    OAMTable _oamTable ALIGN(4);

  public:
    OamManager()
    {
        Clear();
    }

    SpriteEntry* AllocOams(int count)
    {
        _oamPtr -= count;
        return _oamPtr;
    }

    SpriteRotation* AllocMatrices(int count, int& mtxId)
    {
        mtxId = _mtxIdx;
        SpriteRotation* result = &_oamTable.matrixBuffer[_mtxIdx];
        _mtxIdx += count;
        return result;
    }

    void Apply(u16* dst)
    {
        DC_FlushRange(&_oamTable, sizeof(OAMTable));
        dmaCopyWords(3, &_oamTable, dst, sizeof(OAMTable));
    }

    void Clear()
    {
        memset(&_oamTable, 0x2, sizeof(OAMTable));
        _oamPtr = &_oamTable.oamBuffer[128];
        _mtxIdx = 0;
    }
};
