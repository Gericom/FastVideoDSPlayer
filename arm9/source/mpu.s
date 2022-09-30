.section .itcm
.arm

#define PAGE_1M		(0b10011 << 1)

.global mpu_enableVramCache
mpu_enableVramCache:
    //setup region 2 for vram
    ldr	r0,= (PAGE_1M | 0x06800000 | 1)
	mcr	p15, 0, r0, c6, c2, 0
    //write buffer
    mrc	p15, 0, r0, c3, c0, 0
    orr r0, #(1 << 2)
    mcr	p15, 0, r0, c3, c0, 0
    //dcache
    mrc	p15, 0, r0, c2, c0, 0
    orr r0, #(1 << 2)
    mcr	p15, 0, r0, c2, c0, 0

    bx lr

.global mpu_enableTwlWramCache
mpu_enableTwlWramCache:
    //write buffer
    mrc	p15, 0, r0, c3, c0, 0
    orr r0, #(1 << 3)
    mcr	p15, 0, r0, c3, c0, 0
    //dcache
    mrc	p15, 0, r0, c2, c0, 0
    orr r0, #(1 << 3)
    mcr	p15, 0, r0, c2, c0, 0

    bx lr