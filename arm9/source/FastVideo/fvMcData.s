.section .data

#define GX_CMD_PACK(a,b,c,d)    ((a) | ((b) << 8) | ((c) << 16) | ((d) << 24))

#define GX_CMD_NOP              0x00

#define GX_CMD_TRANSLATE        0x20
#define GX_CMD_COLOR            0x20
#define GX_CMD_NORMAL           0x21
#define GX_CMD_TEXCOORD         0x22
#define GX_CMD_VTX_16           0x23
#define GX_CMD_VTX_10           0x24
#define GX_CMD_VTX_XY           0x25
#define GX_CMD_VTX_XZ           0x26
#define GX_CMD_VTX_YZ           0x27
#define GX_CMD_VTX_DIFF         0x28
#define GX_CMD_POLY_ATTR        0x29
#define GX_CMD_TEX_PARAM        0x2A

#define GX_CMD_BEGIN            0x40
#define GX_CMD_END              0x41

#define GX_CMD_SWAPBUFFERS      0x50

#define GX_BEGIN_TRIANGLE       0x00
#define GX_BEGIN_QUAD           0x01
#define GX_BEGIN_TRI_STRIP      0x02
#define GX_BEGIN_QUAD_STRIP     0x03

#define BLOCK_VTX_PACK(x,y,z)   (((x) & 0x3FF) | ((((y) >> 3) & 0x3FF) << 10) | ((z) << 20))
#define VTX_PACK(a,b)   (((a) & 0xFFFF) | (((b) & 0xFFFF) << 16))

#define HEIGHT  192 //144

.balign 32 //cache alignment

.global fv_gMcGxCmdBuf
fv_gMcGxCmdBuf:
    .word GX_CMD_PACK(GX_CMD_POLY_ATTR, GX_CMD_BEGIN, GX_CMD_COLOR, 0x71)
    .word 0x1F00C0
    .word GX_BEGIN_TRI_STRIP
    .word 0
    .word 0
    .word 40 << 6
.rept 11
    .word GX_CMD_PACK(GX_CMD_VTX_XY, GX_CMD_VTX_XY, GX_CMD_VTX_XY, GX_CMD_VTX_XY)
    .word VTX_PACK(0 << 6, -256 << 3)
    .word VTX_PACK(0 << 6, 2 << 3)
    .word VTX_PACK(256 << 6, 2 << 3)
    .word VTX_PACK(0 << 6, -256 << 3)
    .word GX_CMD_PACK(GX_CMD_VTX_XY, GX_CMD_VTX_XY, GX_CMD_VTX_XY, GX_CMD_VTX_XY)
    .word VTX_PACK(0 << 6, 2 << 3)
    .word VTX_PACK(256 << 6, 2 << 3)
    .word VTX_PACK(0 << 6, -256 << 3)
    .word VTX_PACK(0 << 6, 2 << 3)
    .word GX_CMD_PACK(GX_CMD_VTX_XY, GX_CMD_VTX_XY, GX_CMD_VTX_XY, GX_CMD_VTX_XY)
    .word VTX_PACK(256 << 6, 2 << 3)
    .word VTX_PACK(0 << 6, -256 << 3)
    .word VTX_PACK(0 << 6, 2 << 3)
    .word VTX_PACK(256 << 6, 2 << 3)
.endr
    .word GX_CMD_END

    .word GX_CMD_PACK(GX_CMD_POLY_ATTR, GX_CMD_TEX_PARAM, GX_CMD_COLOR, GX_CMD_BEGIN)
    .word 0x1F0080
    .word (0xDED00000)// + ((24 * 256 * 2) >> 3))
    .word 0x7FFF //color
    .word GX_BEGIN_TRIANGLE
.global fv_gMcGxCmdBufA
fv_gMcGxCmdBufA:
    .space 30768
.balign 32 //cache alignment
.end
