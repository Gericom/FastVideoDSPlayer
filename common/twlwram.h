#pragma once

typedef enum
{
    TWR_WRAM_BLOCK_A = 0,
    TWR_WRAM_BLOCK_B = 1,
    TWR_WRAM_BLOCK_C = 2
} TWRWramBlock;

typedef enum
{
    TWR_WRAM_BLOCK_IMAGE_SIZE_32K = 0,
    TWR_WRAM_BLOCK_IMAGE_SIZE_64K,
    TWR_WRAM_BLOCK_IMAGE_SIZE_128K,
    TWR_WRAM_BLOCK_IMAGE_SIZE_256K,
} TWRWramBlockImageSize;

#define TWR_WRAM_BASE               0x03000000

//WRAM A
#define TWR_WRAM_A_SLOT_SIZE        0x10000
#define TWR_WRAM_A_SLOT_SHIFT       16
#define TWR_WRAM_A_SLOT_COUNT       4

#define TWR_WRAM_A_ADDRESS_MAX      0x03FF0000

#define TWR_WRAM_A_SLOT_OFFSET(i)   ((i) << 2)
#define TWR_WRAM_A_SLOT_ENABLE      0x80

typedef enum
{
    TWR_WRAM_A_SLOT_MASTER_ARM9 = 0,
    TWR_WRAM_A_SLOT_MASTER_ARM7 = 1
} TWRWramASlotMaster;

#define TWR_MBK6_START_ADDR_MASK    0x00000FF0
#define TWR_MBK6_START_ADDR_SHIFT   4

#define TWR_MBK6_IMAGE_SIZE_SHIFT   12

#define TWR_MBK6_END_ADDR_SHIFT     20

//WRAM B
#define TWR_WRAM_BC_SLOT_SIZE       0x8000
#define TWR_WRAM_BC_SLOT_SHIFT      15
#define TWR_WRAM_BC_SLOT_COUNT      8

#define TWR_WRAM_BC_ADDRESS_MAX     0x03FF8000

#define TWR_WRAM_BC_SLOT_OFFSET(i)   ((i) << 2)
#define TWR_WRAM_BC_SLOT_ENABLE      0x80

typedef enum
{
    TWR_WRAM_B_SLOT_MASTER_ARM9 = 0,
    TWR_WRAM_B_SLOT_MASTER_ARM7 = 1,
    TWR_WRAM_B_SLOT_MASTER_DSP_CODE = 2
} TWRWramBSlotMaster;

typedef enum
{
    TWR_WRAM_C_SLOT_MASTER_ARM9 = 0,
    TWR_WRAM_C_SLOT_MASTER_ARM7 = 1,
    TWR_WRAM_C_SLOT_MASTER_DSP_DATA = 2
} TWRWramCSlotMaster;

#define TWR_MBK7_START_ADDR_MASK    0x00000FF8
#define TWR_MBK7_START_ADDR_SHIFT   3

#define TWR_MBK7_IMAGE_SIZE_SHIFT   12

#define TWR_MBK7_END_ADDR_SHIFT     19

#define TWR_MBK8_START_ADDR_MASK    0x00000FF8
#define TWR_MBK8_START_ADDR_SHIFT   3

#define TWR_MBK8_IMAGE_SIZE_SHIFT   12

#define TWR_MBK8_END_ADDR_SHIFT     19

#ifdef __cplusplus
extern "C" {
#endif

u32 twr_getBlockAddress(TWRWramBlock block);
void twr_setBlockMapping(TWRWramBlock block, u32 start, u32 length, TWRWramBlockImageSize imageSize);

#ifdef ARM9

void twr_mapWramASlot(int slot, TWRWramASlotMaster master, int offset, bool enable);
void twr_mapWramBSlot(int slot, TWRWramBSlotMaster master, int offset, bool enable);
void twr_mapWramCSlot(int slot, TWRWramCSlotMaster master, int offset, bool enable);

#endif

bool twr_isUnlocked(void);

#ifdef ARM7

static inline bool twr_isUnlockable(void)
{
    return (REG_SCFG_EXT & 0x80000000) != 0;
}

static inline void twr_unlockAll(void)
{
    REG_MBK9 = 0;
}

#endif

#ifdef __cplusplus
}
#endif