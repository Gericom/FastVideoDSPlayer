#include <nds.h>
#include "uiUtil.h"

void uiutil_convertToObj(u8* src, int width, int height, int stride, u16* dst)
{
	for (int y = 0; y < height / 8; y++)
	{
		for (int x = 0; x < width / 8; x++)
		{
			for (int y2 = 0; y2 < 8; y2++)
			{
				//write in 32 bit units for vram compatibility
				*((uint32_t*)dst) =
					((src[0] * 15 + 128) >> 8) |
					(((src[1] * 15 + 128) >> 8) << 4) |
					(((src[2] * 15 + 128) >> 8) << 8) |
					(((src[3] * 15 + 128) >> 8) << 12) |
					(((src[4] * 15 + 128) >> 8) << 16) |
					(((src[5] * 15 + 128) >> 8) << 20) |
					(((src[6] * 15 + 128) >> 8) << 24) |
					(((src[7] * 15 + 128) >> 8) << 28);
				dst += 2;
				src += stride;
			}
			src -= 8 * stride;
			src += 8;
		}
		src -= width;
		src += 8 * stride;
	}
}