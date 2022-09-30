#pragma once
#include "fat/ff.h"

extern FATFS gFatFs;

void fat_init(void);
void fat_mountDldi(void);
