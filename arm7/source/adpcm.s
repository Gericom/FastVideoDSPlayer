.text
.arm

indexTable:
    @ .byte 0, -1, 0, -1, 0, -1, 0, -1, 0, 2, 0, 4, 0, 6, 0, 8
    .byte 0, -3, 0, -3, 0, -2, 0, -1, 0, 2, 0, 4, 0, 6, 0, 8

stepTable:
    .word 7, 8, 9, 10, 11, 12, 13, 14
    .word 16, 17, 19, 21, 23, 25, 28
    .word 31, 34, 37, 41, 45, 50, 55
    .word 60, 66, 73, 80, 88, 97, 107
    .word 118, 130, 143, 157, 173, 190, 209
    .word 230, 253, 279, 307, 337, 371, 408
    .word 449, 494, 544, 598, 658, 724, 796
    .word 876, 963, 1060, 1166, 1282, 1411, 1552
    .word 1707, 1878, 2066, 2272, 2499, 2749, 3024, 3327, 3660, 4026
    .word 4428, 4871, 5358, 5894, 6484, 7132, 7845, 8630
    .word 9493, 10442, 11487, 12635, 13899, 15289, 16818
    .word 18500, 20350, 22385, 24623, 27086, 29794, 32767

//r0: src
//r1: length
//r2: dst
.global adpcm_decompress
adpcm_decompress:
    stmfd sp!, {r4-r11,lr}
    add r12, r0, r1
    ldr r11,= indexTable
    ldr r10,= stepTable
    mov r9, #1
    ldr r8,= 0x7FFF
    ldrsh r3, [r0], #2 //last
    ldrh r4, [r0], #2 //index
1:
    ldr r5, [r0], #4
    .set offs, 0
.rept 8
    ldr r6, [r10, r4, lsl #2]
    movs r7, r5, lsl #(29 - offs)
    orr r7, r9, r7, lsr #28
    ldrsb lr, [r11, r7]
    mul r6, r7, r6
    addcc r3, r3, r6, lsr #3
    subcs r3, r3, r6, lsr #3
    @ mov r6, r3, asr #15
    @ teq r6, r3, asr #31
    @ eorne r3, r8, r3, asr #31
    cmp r3, r8
        movgt r3, r8
    cmn r3, r8
        rsblt r3, r8, #0
    strh r3, [r2], #2
    adds r4, r4, lr
        movmi r4, #0
    cmp r4, #88
        movgt r4, #88
    .set offs, offs + 4
.endr
    cmp r0, r12
    blo 1b
    ldmfd sp!, {r4-r11,lr}
    bx lr