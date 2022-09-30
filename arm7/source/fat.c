#include <nds.h>
#include <string.h>
#include "fat/ff.h"
#include "fat.h"

FATFS gFatFs;

void fat_init(void)
{
    memset(&gFatFs, 0, sizeof(gFatFs));

    if (isDSiMode())
        f_mount(&gFatFs, "sd:", 1); //mount dsi sd card
}

void fat_mountDldi(void)
{
    f_mount(&gFatFs, "fat:", 1);
}
