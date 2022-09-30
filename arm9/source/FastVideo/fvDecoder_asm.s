.section .itcm
.arm
.altmacro

fv_decoder_asm__clampTable = 256
fv_decoder_asm__vlcIdxTab = fv_decoder_asm__clampTable + 4
fv_decoder_asm__vlcBitTab2 = fv_decoder_asm__vlcIdxTab + 4
fv_decoder_asm__vlcPackTab = fv_decoder_asm__vlcBitTab2 + 4
fv_decoder_asm__dequant0 = fv_decoder_asm__vlcPackTab + 4
fv_decoder_asm__dequant1 = fv_decoder_asm__dequant0 + 4
fv_decoder_asm__dequantP0 = fv_decoder_asm__dequant1 + 4
fv_decoder_asm__dequantP1 = fv_decoder_asm__dequantP0 + 4
fv_decoder_asm__q = fv_decoder_asm__dequantP1 + 4
fv_decoder_asm__yBlocks = fv_decoder_asm__q + 4
fv_decoder_asm__texYOffset = fv_decoder_asm__yBlocks + 4
fv_decoder_asm__dlB = fv_decoder_asm__texYOffset + 4
fv_decoder_asm__pFrameIsIBlock = fv_decoder_asm__dlB + 4


.macro idct2_fast dst_offset, next_dct_offset
    smlabb r8, r6, r0, r3 //r8 = d0
    smlatt r6, r6, r0, r8 //r6 = d0 + d1 = t0
    smulbb r9, r7, r1 //r9 = d2
    smlatt r7, r7, r1, r9 //r7 = d2 + d3 = t1
    rsb r8, r6, r8, lsl #1 //r8 = d0 - d1 = t2
    rsb r9, r7, r9, lsl #1 //r9 = d2 - d3 = t3

    add r6, r6, r7 //r6 = p0
    sub r7, r6, r7, lsl #1 //r7 = p1
    ldrb r6, [r12, r6, asr #5]
    ldrb r7, [r12, r7, asr #5]
    add r8, r8, r9 //r8 = p2
    sub r9, r8, r9, lsl #1 //r9 = p3
    ldrb r8, [r12, r8, asr #5]
    ldrb r9, [r12, r9, asr #5]
    strb r6, [sp, #\dst_offset]    
    strb r7, [sp, #\dst_offset + 1]    
    strb r8, [sp, #\dst_offset + 0 + 16]
    ldr r6, [sp, #\next_dct_offset]
    ldr r7, [sp, #\next_dct_offset + 4]
    strb r9, [sp, #\dst_offset + 1 + 16]
.endm
    @ bx lr

.macro idct2_add_fast dst_offset, src_offset, next_dct_offset=-1
    smlabb r8, r6, r0, r2 //r8 = d0
    smlatt r6, r6, r0, r8 //r6 = d0 + d1 = t0
    smulbb r9, r7, r1 //r9 = d2
    smlatt r7, r7, r1, r9 //r7 = d2 + d3 = t1
    rsb r8, r6, r8, lsl #1 //r8 = d0 - d1 = t2
    rsb r9, r7, r9, lsl #1 //r9 = d2 - d3 = t3

    ldrb r10, [sp, #\src_offset]
    ldrb r11, [sp, #\src_offset + 1]
    add r6, r6, r7 //r6 = p0
    sub r7, r6, r7, lsl #1 //r7 = p1
    ldrb r6, [r10, r6, lsr #5]
    ldrb r7, [r11, r7, lsr #5]
    ldrb r10, [sp, #\src_offset + 16]
    ldrb r11, [sp, #\src_offset + 17]
    add r8, r8, r9 //r8 = p2
    sub r9, r8, r9, lsl #1 //r9 = p3
    ldrb r8, [r10, r8, lsr #5]
    ldrb r9, [r11, r9, lsr #5]
    strb r6, [sp, #\dst_offset]
    strb r7, [sp, #\dst_offset + 1]
    strb r8, [sp, #\dst_offset + 0 + 16]
.if \next_dct_offset != -1
    ldr r6, [sp, #\next_dct_offset]
    ldr r7, [sp, #\next_dct_offset + 4]
.endif
    strb r9, [sp, #\dst_offset + 1 + 16]
.endm

.macro idct2_fast_p dst_offset, next_dct_offset=-1
    smlabb r8, r6, r0, r3 //r8 = d0
    smlatt r6, r6, r0, r8 //r6 = d0 + d1 = t0
    smulbb r9, r7, r1 //r9 = d2
    smlatt r7, r7, r1, r9 //r7 = d2 + d3 = t1
    rsb r8, r6, r8, lsl #1 //r8 = d0 - d1 = t2
    rsb r9, r7, r9, lsl #1 //r9 = d2 - d3 = t3

    add r6, r6, r7 //r6 = p0
    sub r7, r6, r7, lsl #1 //r7 = p1
    and r6, r12, r6, asr #5
    and r7, r12, r7, asr #5
    add r8, r8, r9 //r8 = p2
    sub r9, r8, r9, lsl #1 //r9 = p3
    and r8, r12, r8, asr #5
    and r9, r12, r9, asr #5
    orr r6, r6, r7, lsl #8
    strh r6, [r10, #\dst_offset]
    orr r8, r8, r9, lsl #8
.if \next_dct_offset != -1
    ldr r6, [sp, #\next_dct_offset]
    ldr r7, [sp, #\next_dct_offset + 4]
.endif
    strh r8, [r10, #\dst_offset + 16]
.endm

@ idct2_add_fast_zero:
@     ldrh r8, [r10]
@     ldrh r9, [r10, #16]
@     strh r8, [r2]
@     strh r9, [r2, #16]
@     add pc, lr, #(26 * 4)
@     @ bx lr

.macro gen_idct2_add_fast_zero dst_offset, src_offset, next_dct_offset=0
idct2_add_fast_zero_dst_\()\dst_offset\()_\()\src_offset\()_\()\next_dct_offset\():
    ldrh r8, [sp, #\src_offset]
    ldrh r9, [sp, #\src_offset + 16]
.if \next_dct_offset
    ldr r6, [sp, #\next_dct_offset]
    ldr r7, [sp, #\next_dct_offset + 4]
.endif
    strh r8, [sp, #\dst_offset]
    strh r9, [sp, #\dst_offset + 16]
.if \next_dct_offset
    add pc, lr, #(24 * 4) //#(28 * 4)
.else    
    add pc, lr, #(22 * 4) //#(26 * 4)
.endif
.endm

.macro idct2_add_fast_zero_2 dst_offset, src_offset, next_dct_offset
    bleq idct2_add_fast_zero_dst_\()\dst_offset\()_\()\src_offset\()_\()\next_dct_offset
.endm
    
.macro idct2_add_fast_zero dst_offset, src_offset, next_dct_offset=0
    idct2_add_fast_zero_2 %(\dst_offset), %(\src_offset), %(\next_dct_offset)
.endm

gen_idct2_add_fast_zero 22, 20, 228
gen_idct2_add_fast_zero 28, 20, 236
gen_idct2_add_fast_zero 30, 28, 244
gen_idct2_add_fast_zero 24, 20, 252
gen_idct2_add_fast_zero 26, 24, 260
gen_idct2_add_fast_zero 32, 24, 268
gen_idct2_add_fast_zero 34, 32, 276
gen_idct2_add_fast_zero 52, 20, 284
gen_idct2_add_fast_zero 54, 52, 292
gen_idct2_add_fast_zero 60, 52, 300
gen_idct2_add_fast_zero 62, 60, 308
gen_idct2_add_fast_zero 56, 52, 316
gen_idct2_add_fast_zero 58, 56, 324
gen_idct2_add_fast_zero 64, 56, 332
gen_idct2_add_fast_zero 66, 64, 340

gen_idct2_add_fast_zero 84, 20, 348
gen_idct2_add_fast_zero 86, 84, 356
gen_idct2_add_fast_zero 92, 84, 364
gen_idct2_add_fast_zero 94, 92, 372
gen_idct2_add_fast_zero 88, 84, 380
gen_idct2_add_fast_zero 90, 88, 388
gen_idct2_add_fast_zero 96, 88, 396
gen_idct2_add_fast_zero 98, 96, 404
gen_idct2_add_fast_zero 116, 84, 412
gen_idct2_add_fast_zero 118, 116, 420
gen_idct2_add_fast_zero 124, 116, 428
gen_idct2_add_fast_zero 126, 124, 436
gen_idct2_add_fast_zero 120, 116, 444
gen_idct2_add_fast_zero 122, 120, 452
gen_idct2_add_fast_zero 128, 120, 460
gen_idct2_add_fast_zero 130, 128, 468

gen_idct2_add_fast_zero 148, 20, 476
gen_idct2_add_fast_zero 150, 148, 484
gen_idct2_add_fast_zero 156, 148, 492
gen_idct2_add_fast_zero 158, 156, 500
gen_idct2_add_fast_zero 152, 148, 508
gen_idct2_add_fast_zero 154, 152, 516
gen_idct2_add_fast_zero 160, 152, 524
gen_idct2_add_fast_zero 162, 160, 532
gen_idct2_add_fast_zero 180, 148, 540
gen_idct2_add_fast_zero 182, 180, 548
gen_idct2_add_fast_zero 188, 180, 556
gen_idct2_add_fast_zero 190, 188, 564
gen_idct2_add_fast_zero 184, 180, 572
gen_idct2_add_fast_zero 186, 184, 580
gen_idct2_add_fast_zero 192, 184, 588
gen_idct2_add_fast_zero 194, 192

gen_idct2_add_fast_zero 26, 24, 232
gen_idct2_add_fast_zero 32, 24, 240
gen_idct2_add_fast_zero 34, 32, 248
gen_idct2_add_fast_zero 28, 24, 256
gen_idct2_add_fast_zero 30, 28, 264
gen_idct2_add_fast_zero 36, 28, 272
gen_idct2_add_fast_zero 38, 36, 280
gen_idct2_add_fast_zero 56, 24, 288
gen_idct2_add_fast_zero 58, 56, 296
gen_idct2_add_fast_zero 64, 56, 304
gen_idct2_add_fast_zero 66, 64, 312
gen_idct2_add_fast_zero 60, 56, 320
gen_idct2_add_fast_zero 62, 60, 328
gen_idct2_add_fast_zero 68, 60, 336
gen_idct2_add_fast_zero 70, 68, 344
gen_idct2_add_fast_zero 88, 24, 352
gen_idct2_add_fast_zero 90, 88, 360
gen_idct2_add_fast_zero 96, 88, 368
gen_idct2_add_fast_zero 98, 96, 376
gen_idct2_add_fast_zero 92, 88, 384
gen_idct2_add_fast_zero 94, 92, 392
gen_idct2_add_fast_zero 100, 92, 400
gen_idct2_add_fast_zero 102, 100, 408
gen_idct2_add_fast_zero 120, 88, 416
gen_idct2_add_fast_zero 122, 120, 424
gen_idct2_add_fast_zero 128, 120, 432
gen_idct2_add_fast_zero 130, 128, 440
gen_idct2_add_fast_zero 124, 120, 448
gen_idct2_add_fast_zero 126, 124, 456
gen_idct2_add_fast_zero 132, 124, 464
gen_idct2_add_fast_zero 134, 132, 472
gen_idct2_add_fast_zero 152, 24, 480
gen_idct2_add_fast_zero 154, 152, 488
gen_idct2_add_fast_zero 160, 152, 496
gen_idct2_add_fast_zero 162, 160, 504
gen_idct2_add_fast_zero 156, 152, 512
gen_idct2_add_fast_zero 158, 156, 520
gen_idct2_add_fast_zero 164, 156, 528
gen_idct2_add_fast_zero 166, 164, 536
gen_idct2_add_fast_zero 184, 152, 544
gen_idct2_add_fast_zero 186, 184, 552
gen_idct2_add_fast_zero 192, 184, 560
gen_idct2_add_fast_zero 194, 192, 568
gen_idct2_add_fast_zero 188, 184, 576
gen_idct2_add_fast_zero 190, 188, 584
gen_idct2_add_fast_zero 196, 188, 592
gen_idct2_add_fast_zero 198, 196

.macro gen_idct2_fast_zero dst_offset, next_dct_offset=0
idct2_fast_zero_dst_\()\dst_offset\()_\()\next_dct_offset\():
.if \next_dct_offset
    ldr r6, [sp, #\next_dct_offset]
    ldr r7, [sp, #\next_dct_offset + 4]
.endif
    //the bottom 16 bits of r2 are zero
    strh r2, [r10, #\dst_offset]
    strh r2, [r10, #\dst_offset + 16]
.if \next_dct_offset
    add pc, lr, #(20 * 4) //#(28 * 4)
.else    
    add pc, lr, #(18 * 4) //#(26 * 4)
.endif
.endm

.macro idct2_fast_zero_2 dst_offset, next_dct_offset
    bleq idct2_fast_zero_dst_\()\dst_offset\()_\()\next_dct_offset
.endm
    
.macro idct2_fast_zero dst_offset, next_dct_offset=0
    idct2_fast_zero_2 %(\dst_offset), %(\next_dct_offset)
.endm

gen_idct2_fast_zero 0, 224
gen_idct2_fast_zero 2, 232
gen_idct2_fast_zero 8, 240
gen_idct2_fast_zero 10, 248
gen_idct2_fast_zero 4, 256
gen_idct2_fast_zero 6, 264
gen_idct2_fast_zero 12, 272
gen_idct2_fast_zero 14, 280
gen_idct2_fast_zero 32, 288
gen_idct2_fast_zero 34, 296
gen_idct2_fast_zero 40, 304
gen_idct2_fast_zero 42, 312
gen_idct2_fast_zero 36, 320
gen_idct2_fast_zero 38, 328
gen_idct2_fast_zero 44, 336
gen_idct2_fast_zero 46, 0
gen_idct2_fast_zero 64, 352
gen_idct2_fast_zero 66, 360
gen_idct2_fast_zero 72, 368
gen_idct2_fast_zero 74, 376
gen_idct2_fast_zero 68, 384
gen_idct2_fast_zero 70, 392
gen_idct2_fast_zero 76, 400
gen_idct2_fast_zero 78, 408
gen_idct2_fast_zero 96, 416
gen_idct2_fast_zero 98, 424
gen_idct2_fast_zero 104, 432
gen_idct2_fast_zero 106, 440
gen_idct2_fast_zero 100, 448
gen_idct2_fast_zero 102, 456
gen_idct2_fast_zero 108, 464
gen_idct2_fast_zero 110, 0
gen_idct2_fast_zero 128, 480
gen_idct2_fast_zero 130, 488
gen_idct2_fast_zero 136, 496
gen_idct2_fast_zero 138, 504
gen_idct2_fast_zero 132, 512
gen_idct2_fast_zero 134, 520
gen_idct2_fast_zero 140, 528
gen_idct2_fast_zero 142, 536
gen_idct2_fast_zero 160, 544
gen_idct2_fast_zero 162, 552
gen_idct2_fast_zero 168, 560
gen_idct2_fast_zero 170, 568
gen_idct2_fast_zero 164, 576
gen_idct2_fast_zero 166, 584
gen_idct2_fast_zero 172, 592
gen_idct2_fast_zero 174, 172

@ idct2_add_fast_02:
@     smlabb r9, r6, r0, r3 //r8 = d0 = t0 = t2
@     smlabb r8, r7, r1, r9 //r9 = d2 = t1 = t3

@     ldrh r11, [r10]

@     rsb r9, r8, r9, lsl #1
@     add r8, r12, r8, asr #5
@     add r9, r12, r9, asr #5
@     ldrb r7, [r9, r11, lsr #8]
@     mov r11, r11, ror #8
@     ldrb r6, [r8, r11, lsr #24]
@     ldrh r11, [r10, #16]
@     strb r7, [r2, #1]
@     ldrb r9, [r9, r11, lsr #8]
@     mov r11, r11, ror #8
@     ldrb r8, [r8, r11, lsr #24]
@     strb r6, [r2, #0]    
@     strb r8, [r2, #0 + 16]    
@     strb r9, [r2, #1 + 16]
@     add pc, lr, #(26 * 4)

@ idct2_add_b:
@     smlabb r4, r6, r0, r3 //r4 = d0
@     smlabt r5, r7, r0, r4 //r5 = d0 + d1 = t0
@     smulbb r11, r8, r1 //r11 = d2
@     rsb r4, r5, r4, lsl #1 //r4 = d0 - d1 = t2

//r0 = fv_decoder_t* dec
//r1 = const u16* src
//r2 = u8* dst
.global fv_decodeFrame_asm
fv_decodeFrame_asm:
    stmfd sp!, {r4-r11,lr}
stack_size = 64 * 2 * 3 + 3 * 64 + 4
    sub sp, sp, #stack_size
lastGDC_offset = stack_size - 4
    //setup bitreader
    ldrh r3, [r1], #2
    ldrh r12, [r1], #2
    mov r4, #-16 //r4 = remaining
    mov r3, r3, lsl #16 //r3 = bits
    orr r3, r3, r12

    movs r3, r3, lsl #1
        //if (isPFrame) return;
        addcs sp, sp, #stack_size
        ldmcsfd sp!, {r4-r11,pc}
    adds r4, r4, #1
        blpl fillBitsR7R9
    
    ldrb lr, [r0, #fv_decoder_asm__q] //lr = q
    mov r12, r3, lsr #26 //r12 = newQ
    mov r3, r3, lsl #6
    adds r4, r4, #6
        blpl fillBitsR7R9

    cmp lr, r12
        blne updateQTab

    mov r10, #0 //lastGDC
    str r10, [sp, #lastGDC_offset]
    @ mov r11, #18
    ldr r11, [r0, #fv_decoder_asm__yBlocks]
    1:
        sub r11, r11, #(32 << 16)
        2:
            push {r2, r11}
#define stack_offset 8
            //clear dct
            mov r5, #0
            mov r6, #0
            mov r7, #0
            mov r8, #0
            add r12, sp, #stack_offset + 64 * 3
        .rept 24
            stmia r12!, {r5-r8}
        .endr

            ldr r8, [r0, #fv_decoder_asm__vlcIdxTab]
            ldr r11, [r0, #fv_decoder_asm__vlcBitTab2]
            ldr r12, [r0, #fv_decoder_asm__vlcPackTab]
            mov r10, #3
            
            add r5, sp, #stack_offset + 64 * 3
            bl readDCT

            ldrsh r2, [sp, #stack_offset + 64 * 3]
            ldr lr, [sp, #(lastGDC_offset + stack_offset)]
            add r5, sp, #stack_offset + 64 * 3 + 64 * 2            
            add r2, r2, lr //dctG[0] += lastGDC
            str r2, [sp, #(lastGDC_offset + stack_offset)]
            strh r2, [sp, #stack_offset + 64 * 3]
            bl readDCT

            add r5, sp, #stack_offset + 64 * 3 + 64 * 2 * 2
            bl readDCT

#define DST_OFFSET_G(x,y)   (stack_offset + (y) * 8 + (x))
#define DST_OFFSET_R(x,y)   (stack_offset + 64 + (y) * 8 + (x))
#define DST_OFFSET_B(x,y)   (stack_offset + 2 * 64 + (y) * 8 + (x))
#define DCT_OFFSET(idx)     (stack_offset + 64 * 3 + 2 * 4 * (idx))

            push {r0,r1,r3}
#undef stack_offset
#define stack_offset (8 + 3 * 4)

            mov r3, #16
            ldr r12, [r0, #fv_decoder_asm__clampTable]
            ldr r1, [r0, #fv_decoder_asm__dequant1]
            ldr r0, [r0, #fv_decoder_asm__dequant0]
            ldr r6, [sp, #DCT_OFFSET(0)]
            ldr r7, [sp, #DCT_OFFSET(0) + 4]
            add r2, r3, r12, lsl #5

            idct2_fast DST_OFFSET_G(0,0), DCT_OFFSET(1)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_G(2,0), DST_OFFSET_G(0,0), DCT_OFFSET(2)
            idct2_add_fast DST_OFFSET_G(2,0), DST_OFFSET_G(0,0), DCT_OFFSET(2)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_G(0,1), DST_OFFSET_G(0,0), DCT_OFFSET(3)
            idct2_add_fast DST_OFFSET_G(0,1), DST_OFFSET_G(0,0), DCT_OFFSET(3)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_G(2,1), DST_OFFSET_G(0,1), DCT_OFFSET(4)
            idct2_add_fast DST_OFFSET_G(2,1), DST_OFFSET_G(0,1), DCT_OFFSET(4)

            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_G(4,0), DST_OFFSET_G(0,0), DCT_OFFSET(5)
            idct2_add_fast DST_OFFSET_G(4,0), DST_OFFSET_G(0,0), DCT_OFFSET(5)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_G(6,0), DST_OFFSET_G(4,0), DCT_OFFSET(6)
            idct2_add_fast DST_OFFSET_G(6,0), DST_OFFSET_G(4,0), DCT_OFFSET(6)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_G(4,1), DST_OFFSET_G(4,0), DCT_OFFSET(7)
            idct2_add_fast DST_OFFSET_G(4,1), DST_OFFSET_G(4,0), DCT_OFFSET(7)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_G(6,1), DST_OFFSET_G(4,1), DCT_OFFSET(8)
            idct2_add_fast DST_OFFSET_G(6,1), DST_OFFSET_G(4,1), DCT_OFFSET(8)

            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_G(0,4), DST_OFFSET_G(0,0), DCT_OFFSET(9)
            idct2_add_fast DST_OFFSET_G(0,4), DST_OFFSET_G(0,0), DCT_OFFSET(9)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_G(2,4), DST_OFFSET_G(0,4), DCT_OFFSET(10)
            idct2_add_fast DST_OFFSET_G(2,4), DST_OFFSET_G(0,4), DCT_OFFSET(10)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_G(0,5), DST_OFFSET_G(0,4), DCT_OFFSET(11)
            idct2_add_fast DST_OFFSET_G(0,5), DST_OFFSET_G(0,4), DCT_OFFSET(11)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_G(2,5), DST_OFFSET_G(0,5), DCT_OFFSET(12)
            idct2_add_fast DST_OFFSET_G(2,5), DST_OFFSET_G(0,5), DCT_OFFSET(12)

            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_G(4,4), DST_OFFSET_G(0,4), DCT_OFFSET(13)
            idct2_add_fast DST_OFFSET_G(4,4), DST_OFFSET_G(0,4), DCT_OFFSET(13)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_G(6,4), DST_OFFSET_G(4,4), DCT_OFFSET(14)
            idct2_add_fast DST_OFFSET_G(6,4), DST_OFFSET_G(4,4), DCT_OFFSET(14)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_G(4,5), DST_OFFSET_G(4,4), DCT_OFFSET(15)
            idct2_add_fast DST_OFFSET_G(4,5), DST_OFFSET_G(4,4), DCT_OFFSET(15)        
            orrs r11, r6, r7

#undef DCT_OFFSET
#define DCT_OFFSET(idx)     (stack_offset + 64 * 3 + 64 * 2 + 2 * 4 * (idx))

            idct2_add_fast_zero DST_OFFSET_G(6,5), DST_OFFSET_G(4,5), DCT_OFFSET(0)
            idct2_add_fast DST_OFFSET_G(6,5), DST_OFFSET_G(4,5), DCT_OFFSET(0)

            //Red
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_R(0,0), DST_OFFSET_G(0,0), DCT_OFFSET(1)
            idct2_add_fast DST_OFFSET_R(0,0), DST_OFFSET_G(0,0), DCT_OFFSET(1)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_R(2,0), DST_OFFSET_R(0,0), DCT_OFFSET(2)
            idct2_add_fast DST_OFFSET_R(2,0), DST_OFFSET_R(0,0), DCT_OFFSET(2)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_R(0,1), DST_OFFSET_R(0,0), DCT_OFFSET(3)
            idct2_add_fast DST_OFFSET_R(0,1), DST_OFFSET_R(0,0), DCT_OFFSET(3)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_R(2,1), DST_OFFSET_R(0,1), DCT_OFFSET(4)
            idct2_add_fast DST_OFFSET_R(2,1), DST_OFFSET_R(0,1), DCT_OFFSET(4)
 
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_R(4,0), DST_OFFSET_R(0,0), DCT_OFFSET(5)
            idct2_add_fast DST_OFFSET_R(4,0), DST_OFFSET_R(0,0), DCT_OFFSET(5)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_R(6,0), DST_OFFSET_R(4,0), DCT_OFFSET(6)
            idct2_add_fast DST_OFFSET_R(6,0), DST_OFFSET_R(4,0), DCT_OFFSET(6)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_R(4,1), DST_OFFSET_R(4,0), DCT_OFFSET(7)
            idct2_add_fast DST_OFFSET_R(4,1), DST_OFFSET_R(4,0), DCT_OFFSET(7)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_R(6,1), DST_OFFSET_R(4,1), DCT_OFFSET(8)
            idct2_add_fast DST_OFFSET_R(6,1), DST_OFFSET_R(4,1), DCT_OFFSET(8)

            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_R(0,4), DST_OFFSET_R(0,0), DCT_OFFSET(9)
            idct2_add_fast DST_OFFSET_R(0,4), DST_OFFSET_R(0,0), DCT_OFFSET(9)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_R(2,4), DST_OFFSET_R(0,4), DCT_OFFSET(10)
            idct2_add_fast DST_OFFSET_R(2,4), DST_OFFSET_R(0,4), DCT_OFFSET(10)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_R(0,5), DST_OFFSET_R(0,4), DCT_OFFSET(11)
            idct2_add_fast DST_OFFSET_R(0,5), DST_OFFSET_R(0,4), DCT_OFFSET(11)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_R(2,5), DST_OFFSET_R(0,5), DCT_OFFSET(12)
            idct2_add_fast DST_OFFSET_R(2,5), DST_OFFSET_R(0,5), DCT_OFFSET(12)

            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_R(4,4), DST_OFFSET_R(0,4), DCT_OFFSET(13)
            idct2_add_fast DST_OFFSET_R(4,4), DST_OFFSET_R(0,4), DCT_OFFSET(13)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_R(6,4), DST_OFFSET_R(4,4), DCT_OFFSET(14)
            idct2_add_fast DST_OFFSET_R(6,4), DST_OFFSET_R(4,4), DCT_OFFSET(14)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_R(4,5), DST_OFFSET_R(4,4), DCT_OFFSET(15)
            idct2_add_fast DST_OFFSET_R(4,5), DST_OFFSET_R(4,4), DCT_OFFSET(15)
            orrs r11, r6, r7

#undef DCT_OFFSET
#define DCT_OFFSET(idx)     (stack_offset + 64 * 3 + 64 * 2 * 2 + 2 * 4 * (idx))

            idct2_add_fast_zero DST_OFFSET_R(6,5), DST_OFFSET_R(4,5), DCT_OFFSET(0)
            idct2_add_fast DST_OFFSET_R(6,5), DST_OFFSET_R(4,5), DCT_OFFSET(0)

            //Blue
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_B(0,0), DST_OFFSET_G(0,0), DCT_OFFSET(1)
            idct2_add_fast DST_OFFSET_B(0,0), DST_OFFSET_G(0,0), DCT_OFFSET(1)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_B(2,0), DST_OFFSET_B(0,0), DCT_OFFSET(2)
            idct2_add_fast DST_OFFSET_B(2,0), DST_OFFSET_B(0,0), DCT_OFFSET(2)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_B(0,1), DST_OFFSET_B(0,0), DCT_OFFSET(3)
            idct2_add_fast DST_OFFSET_B(0,1), DST_OFFSET_B(0,0), DCT_OFFSET(3)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_B(2,1), DST_OFFSET_B(0,1), DCT_OFFSET(4)
            idct2_add_fast DST_OFFSET_B(2,1), DST_OFFSET_B(0,1), DCT_OFFSET(4)
 
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_B(4,0), DST_OFFSET_B(0,0), DCT_OFFSET(5)
            idct2_add_fast DST_OFFSET_B(4,0), DST_OFFSET_B(0,0), DCT_OFFSET(5)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_B(6,0), DST_OFFSET_B(4,0), DCT_OFFSET(6)
            idct2_add_fast DST_OFFSET_B(6,0), DST_OFFSET_B(4,0), DCT_OFFSET(6)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_B(4,1), DST_OFFSET_B(4,0), DCT_OFFSET(7)
            idct2_add_fast DST_OFFSET_B(4,1), DST_OFFSET_B(4,0), DCT_OFFSET(7)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_B(6,1), DST_OFFSET_B(4,1), DCT_OFFSET(8)
            idct2_add_fast DST_OFFSET_B(6,1), DST_OFFSET_B(4,1), DCT_OFFSET(8)

            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_B(0,4), DST_OFFSET_B(0,0), DCT_OFFSET(9)
            idct2_add_fast DST_OFFSET_B(0,4), DST_OFFSET_B(0,0), DCT_OFFSET(9)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_B(2,4), DST_OFFSET_B(0,4), DCT_OFFSET(10)
            idct2_add_fast DST_OFFSET_B(2,4), DST_OFFSET_B(0,4), DCT_OFFSET(10)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_B(0,5), DST_OFFSET_B(0,4), DCT_OFFSET(11)
            idct2_add_fast DST_OFFSET_B(0,5), DST_OFFSET_B(0,4), DCT_OFFSET(11)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_B(2,5), DST_OFFSET_B(0,5), DCT_OFFSET(12)
            idct2_add_fast DST_OFFSET_B(2,5), DST_OFFSET_B(0,5), DCT_OFFSET(12)

            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_B(4,4), DST_OFFSET_B(0,4), DCT_OFFSET(13)
            idct2_add_fast DST_OFFSET_B(4,4), DST_OFFSET_B(0,4), DCT_OFFSET(13)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_B(6,4), DST_OFFSET_B(4,4), DCT_OFFSET(14)
            idct2_add_fast DST_OFFSET_B(6,4), DST_OFFSET_B(4,4), DCT_OFFSET(14)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_B(4,5), DST_OFFSET_B(4,4), DCT_OFFSET(15)
            idct2_add_fast DST_OFFSET_B(4,5), DST_OFFSET_B(4,4), DCT_OFFSET(15)
            orrs r11, r6, r7
            idct2_add_fast_zero DST_OFFSET_B(6,5), DST_OFFSET_B(4,5)
            idct2_add_fast DST_OFFSET_B(6,5), DST_OFFSET_B(4,5)

            pop {r0,r1,r3}
#undef stack_offset
#define stack_offset 8

            pop {r2}

#undef stack_offset
#define stack_offset 4

            add r5, sp, #(stack_offset)
            bl colorpack555

            pop {r11}

            sub r2, r2, #(4096 - 16)

            adds r11, r11, #(1 << 16)
            bcc 2b

        add r2, r2, #(512 * 7)
        subs r11, r11, #1
        bne 1b

    add sp, sp, #stack_size
    ldmfd sp!, {r4-r11,pc}
#undef stack_offset
#undef DST_OFFSET_R
#undef DST_OFFSET_G
#undef DST_OFFSET_B
#undef DCT_OFFSET

.pool

@ fillBits:
@     push {lr}
@     ldrh lr, [r1], #2
@     orr r3, r3, lr, lsl r4
@     sub r4, r4, #16
@     pop {pc}

updateQTab:
    push {lr}
    strb r12, [r0, #fv_decoder_asm__q]
    @ mov lr, #0xAB
    @ orr lr, lr, #0x2A00
    @ smulwb r5, lr, r12 //r5 = q / 6
    @ ldr lr,= fv_gDequantCoefs4
    @ ldr r7,= fv_gDeZigZagTable4x4
    @ sub r12, r12, r5, lsl #2
    @ sub r12, r12, r5, lsl #1 //r12 = q % 6
    @ ldrb r12, [lr, r12, lsl #4]!
    @ ldrb r8, [r7], #1
    @ mov r12, r12, lsl r5
    @ cmp r12, #176
    @     movgt r12, #176
    @ orr r12, r12, r8, lsl #18
    @ str r12, [r0], #4
    @ add r12, r12, #(0x10 << 18)
    @ str r12, [r0], #4
    @ add r12, r12, #(0x10 << 18)
    @ str r12, [r0], #4
    @ add r12, r12, #(0x10 << 18)
    @ str r12, [r0], #4
    @ mov r6, #15
    @ 1:
    @     ldrb r8, [r7], #1
    @     ldrb r12, [lr, #1]!
    @     mov r12, r12, lsl r5
    @     orr r12, r12, r8, lsl #18
    @     str r12, [r0], #4
    @     add r12, r12, #(0x10 << 18)
    @     str r12, [r0], #4
    @     add r12, r12, #(0x10 << 18)
    @     str r12, [r0], #4
    @     add r12, r12, #(0x10 << 18)
    @     str r12, [r0], #4
    @     subs r6, #1
    @     bne 1b
    @ sub r0, r0, #(4 * 64)
    pop {pc}

fillBitsR7R9:
    ldrh r9, [r1], #2
    mov r7, r4
    sub r4, r4, #16
    orr r3, r3, r9, lsl r7
    bx lr
    
.macro dct_loop_start
    cmp r10, r3, lsr #25
    ldrneb r7, [r11, r3, lsr #23] //bottom 4 bits of 13 bit value don't influence the bit length
    ldrneb r6, [r8, r3, lsr #19]
    beq code_is_3
    mov r3, r3, lsl r7
    ldr r9, [r12, r6, lsl #2]
    adds r4, r4, r7
    ldr lr, [r0, r9, lsr #24]!
        bpl dct_continue_read_bits
    tst r9, #0x10000 //stop bit
    strh r9, [r5, lr]
.endm

//r8 = vlcIdxTab
//r10 = 3
//r11 = vlcBitTab2
//r12 = vlcPackTab
readDCT:
    push {r0, lr}
    sub r0, r0, #4
1:
    dct_loop_start
.rept 5
    popne {r0, pc}
    dct_loop_start
.endr
    beq 1b
    pop {r0, pc}

    code_is_3:
        movs r3, r3, lsl #8
        bcs code_3_1
        code_3_0:
            adds r4, r4, #8
                ldrplh r9, [r1], #2
                orrpl r3, r3, r9, lsl r4
            ldrb r6, [r8, r3, lsr #19]
                subpl r4, r4, #16
            sub lr, r8, #(4 * 208)
            ldrb r7, [lr, r6]!
            ldrsb r9, [lr, #-(1 * 208)]
            ldrb lr, [lr, #(2 * 208)]
            mov r3, r3, lsl r7
            adds r4, r4, r7
            ldr lr, [r0, lr, lsl #2]!
                bpl dct_continue_read_bits
            cmp r6, #135 //stop bit
            strh r9, [r5, lr]
            blo 1b
            pop {r0, pc}

        code_3_1:
            movs r3, r3, lsl #1
            bcs code_3_11
            code_3_10:
                adds r4, r4, #9       
                    ldrplh r9, [r1], #2
                    orrpl r3, r3, r9, lsl r4
                ldrb r6, [r8, r3, lsr #19]
                    subpl r4, r4, #16
                sub lr, r8, #(4 * 208)
                ldrb r7, [lr, r6]!
                ldrsb r9, [lr, #(1 * 208)]
                ldrb lr, [lr, #(3 * 208)]
                mov r3, r3, lsl r7
                adds r4, r4, r7
                ldr lr, [r0, lr, lsl #2]!
                    bpl dct_continue_read_bits
                cmp r6, #135 //stop bit
                strh r9, [r5, lr]
                blo 1b
                pop {r0, pc}

            code_3_11:
                adds r4, r4, #9                    
                    blpl fillBitsR7R9
                mov r6, r3, lsr #25
                mov r3, r3, lsl #7
                adds r4, r4, #7
                    blpl fillBitsR7R9
                and lr, r6, #0x3F
                add lr, lr, #1
                ldr lr, [r0, lr, lsl #2]!
                mov r9, r3, asr #20
                mov r3, r3, lsl #12
                adds r4, r4, #12
                    bpl 3f
                tst r6, #0x40 //stop bit
                strh r9, [r5, lr]
                beq 1b
                pop {r0, pc}

    dct_continue_read_bits:
        ldrh r7, [r1], #2
        cmp r6, #135 //stop bit
        strh r9, [r5, lr]
        orr r3, r3, r7, lsl r4
        sub r4, r4, #16
        pophs {r0, pc}   
        dct_loop_start  
    .rept 5
        popne {r0, pc}
        dct_loop_start
    .endr   
        beq 1b
        pop {r0, pc}

    3:
        ldrh r7, [r1], #2
        tst r6, #0x40 //stop bit
        strh r9, [r5, lr]
        orr r3, r3, r7, lsl r4
        sub r4, r4, #16
        beq 1b
        pop {r0, pc}

colorpack555:
    push {lr}
    ldr r11,= 0xFF00FF00
    ldr lr,= 0x80008000
.rept 8
    ldr r6, [r5, #64] //R3 R2 R1 R0
    ldr r12, [r5, #(64 * 2)] //B3 B2 B1 B0
    ldr r10, [r5], #4 //G3 G2 G1 G0
    and r7, r12, r11  //B3 B1
    bic r12, r12, r11 //B2 B0
    and r8, r10, r11 //G3 G1
    bic r10, r10, r11 //G2 G0
    and r9, r6, r11 //R3 R1
    bic r6, r6, r11 //R2 R0
    orr r6, r6, r10, lsl #5
    orr r6, r6, r12, lsl #10
    orr r6, r6, lr
    orr r9, lr, r9, lsr #8
    orr r9, r9, r8, lsr #3
    orr r9, r9, r7, lsl #2
    stmia r2!, {r6,r9}

    ldr r6, [r5, #64] //R3 R2 R1 R0
    ldr r12, [r5, #(64 * 2)] //B3 B2 B1 B0
    ldr r10, [r5], #4 //G3 G2 G1 G0
    and r7, r12, r11  //B3 B1
    bic r12, r12, r11 //B2 B0
    and r8, r10, r11 //G3 G1
    bic r10, r10, r11 //G2 G0
    and r9, r6, r11 //R3 R1
    bic r6, r6, r11 //R2 R0
    orr r6, r6, r10, lsl #5
    orr r6, r6, r12, lsl #10
    orr r6, r6, lr
    orr r9, lr, r9, lsr #8
    orr r9, r9, r8, lsr #3
    orr r9, r9, r7, lsl #2
    stmia r2, {r6,r9}
    add r2, r2, #(256 * 2 - 8)
.endr
    pop {pc}
    @ bx lr

.macro decodeVectorDelta
    //dx
    clz r6, r3
    mov r3, r3, lsl r6
    mov r3, r3, lsl #1
    rsb r7, r6, #32
    mov r7, r3, lsr r7
    mov r8, #1
    add r7, r7, r8, lsl r6
    tst r7, #1
        rsbne r7, r7, #1
    add r11, r11, r7, asr #1
    mov r3, r3, lsl r6
    add r4, r4, r6, lsl #1
    adds r4, r4, #1
        blpl fillBitsR7R9

    //dy
    clz r6, r3
    mov r3, r3, lsl r6
    mov r3, r3, lsl #1
    rsb r7, r6, #32
    mov r7, r3, lsr r7
    add r7, r7, r8, lsl r6
    tst r7, #1
        rsbne r7, r7, #1
    add r5, r5, r7, asr #1
    mov r3, r3, lsl r6
    add r4, r4, r6, lsl #1
    adds r4, r4, #1
        blpl fillBitsR7R9
.endm

.macro finishVector add_y_offset
    strh r11, [r10], #2
    //convert to two tex coords
    movs r11, r11, asr #1
    mov r11, r11, lsl #4
    strh r11, [r2], #2
    addcs r11, r11, #16
    strh r11, [r12], #2

    pop {r11}

.if add_y_offset
    ldr r6, [r0, #fv_decoder_asm__texYOffset]
.endif

    strh r5, [r10], #2
    //convert to two tex coords
.if add_y_offset
    add r5, r5, r6//#(112 << 1)
.endif
    movs r5, r5, asr #1
    mov r5, r5, lsl #4
    strh r5, [r2], #18
    addcs r5, r5, #16
    strh r5, [r12], #18
.endm

//r0 = fv_decoder_t* dec
//r1 = const u16* src
.global fv_decodePFrameVectors
fv_decodePFrameVectors:
    stmfd sp!, {r4-r11,lr}
    stack_size = 32 * 4
    sub sp, sp, #stack_size

    //setup bitreader
    ldrh r3, [r1], #2
    ldrh r12, [r1], #2
    mov r4, #-16 //r4 = remaining
    mov r3, r3, lsl #16 //r3 = bits
    orr r3, r3, r12

    movs r3, r3, lsl #1
        //if (!isPFrame) return;
        addcc sp, sp, #stack_size
        ldmccfd sp!, {r4-r11,pc}
    adds r4, r4, #1
        blpl fillBitsR7R9

    ldr r2,= fv_gMcGxCmdBufA + 4
    ldr r12, [r0, #fv_decoder_asm__dlB]
    @ ldr r12,= fv_gMcGxCmdBufB + 4

    ldr r11, [r0, #fv_decoder_asm__yBlocks]
    @ mov r11, #(18 >> 1) //#18
    mov r10, sp
    mov r11, r11, lsr #1

        push {r11}
        //create the prediction vector    
        mov r11, #0 //x
        mov r5, #0 //y

        mov r6, r3, lsr #31
        mov r3, r3, lsl #1
        adds r4, r4, #1
            blpl fillBitsR7R9
        cmp r6, #1
            beq vectors_done_first

        decodeVectorDelta

    vectors_done_first:
        finishVector 0

        @ pop {r11}
        //interlock
        sub r11, r11, #(31 << 16)

    2:
        push {r11}
        //create the prediction vector
        //x
        ldrsh r11, [r10, #-4] //(x-1,y)
        //y
        ldrsh r5, [r10, #-2] //(x-1,y)

        mov r6, r3, lsr #31
        mov r3, r3, lsl #1
        adds r4, r4, #1
            blpl fillBitsR7R9
        cmp r6, #1
            beq vectors_done_row0

        decodeVectorDelta

    vectors_done_row0:
        finishVector 0

        @ pop {r11}
        //interlock
        adds r11, r11, #(1 << 16)
        bcc 2b

    subs r11, r11, #1


    1:
        sub r11, r11, #(31 << 16)
        mov r10, sp
            push {r11}
            //create the prediction vector
            //x
            ldrsh r11, [r10] //(x,y-1)
            ldrsh r7, [r10, #4] //(x+1,y-1)
            ldrsh r5, [r10, #2] //(x,y-1)
            ldrsh r8, [r10, #6] //(x+1,y-1)
            //x
            cmp r7, r11
                movgt r11, r7
            //y
            cmp r8, r5
                movgt r5, r8            

            mov r6, r3, lsr #31
            mov r3, r3, lsl #1
            adds r4, r4, #1
                blpl fillBitsR7R9
            cmp r6, #1
                beq vectors_done_first_column

            decodeVectorDelta

        vectors_done_first_column:
            finishVector 0

            @ pop {r11}
            //interlock
            adds r11, r11, #(1 << 16)

        2:
            push {r11}
            //create the prediction vector
            ldrsh r11, [r10, #-4] //(x-1,y)
            ldrsh r6, [r10] //(x,y-1)
            ldrsh r7, [r10, #4] //(x+1,y-1)
            ldrsh r5, [r10, #-2] //(x-1,y)
            //x
            sub	r8, r11, r6
            sub	r9, r11, r7
            teq	r8, r9
            bmi	median_x
            sub	r9, r7, r6
            teq	r8, r9
            movmi r11, r6
            movpl r11, r7
        median_x:

            //y
            ldrsh r6, [r10, #2] //(x,y-1)
            ldrsh r7, [r10, #6] //(x+1,y-1)

            //interlock

            sub	r8, r5, r6
            sub	r9, r5, r7
            teq	r8, r9
            bmi	median_y
            sub	r9, r7, r6
            teq	r8, r9
            movmi r5, r6
            movpl r5, r7
        median_y:

            mov r6, r3, lsr #31
            mov r3, r3, lsl #1
            adds r4, r4, #1
                blpl fillBitsR7R9
            cmp r6, #1
                beq vectors_done

            decodeVectorDelta

        vectors_done:
            finishVector 0

            @ pop {r11}
            //interlock
            adds r11, r11, #(1 << 16)
            bcc 2b

            push {r11}
            //create the prediction vector
            ldrsh r11, [r10, #-4] //(x-1,y)
            ldrsh r7, [r10] //(x,y-1)
            ldrsh r5, [r10, #-2] //(x-1,y)
            ldrsh r8, [r10, #2] //(x,y-1)
            //x
            cmp r7, r11
                movgt r11, r7
            //y
            cmp r8, r5
                movgt r5, r8          

            mov r6, r3, lsr #31
            mov r3, r3, lsl #1
            adds r4, r4, #1
                blpl fillBitsR7R9
            cmp r6, #1
                beq vectors_done_last_column

            decodeVectorDelta

        vectors_done_last_column:
            finishVector 0

            @ pop {r11}

        subs r11, r11, #1
        bne 1b

    add r2, r2, #12
    ldr r11, [r0, #fv_decoder_asm__yBlocks]
    add r12, r12, #12

    sub r11, r11, r11, lsr #1
    @ mov r11, #(18 >> 1)
    1:
        sub r11, r11, #(31 << 16)
        mov r10, sp
            push {r11}
            //create the prediction vector
            ldrsh r11, [r10] //(x,y-1)
            ldrsh r7, [r10, #4] //(x+1,y-1)
            ldrsh r5, [r10, #2] //(x,y-1)
            ldrsh r8, [r10, #6] //(x+1,y-1)
            //x
            cmp r7, r11
                movgt r11, r7
            //y
            cmp r8, r5
                movgt r5, r8        

            mov r6, r3, lsr #31
            mov r3, r3, lsl #1
            adds r4, r4, #1
                blpl fillBitsR7R9
            cmp r6, #1
                beq vectors_done_first_column2

            decodeVectorDelta

        vectors_done_first_column2:
            finishVector 1

            @ pop {r11}
            //interlock
            adds r11, r11, #(1 << 16)

        2:
            push {r11}
            //create the prediction vector
            ldrsh r11, [r10, #-4] //(x-1,y)
            ldrsh r6, [r10] //(x,y-1)
            ldrsh r7, [r10, #4] //(x+1,y-1)
            ldrsh r5, [r10, #-2] //(x-1,y)
            //x
            sub	r8, r11, r6
            sub	r9, r11, r7
            teq	r8, r9
            bmi	median_x2
            sub	r9, r7, r6
            teq	r8, r9
            movmi r11, r6
            movpl r11, r7
        median_x2:

            //y
            ldrsh r6, [r10, #2] //(x,y-1)
            ldrsh r7, [r10, #6] //(x+1,y-1)

            //interlock

            sub	r8, r5, r6
            sub	r9, r5, r7
            teq	r8, r9
            bmi	median_y2
            sub	r9, r7, r6
            teq	r8, r9
            movmi r5, r6
            movpl r5, r7
        median_y2:

            mov r6, r3, lsr #31
            mov r3, r3, lsl #1
            adds r4, r4, #1
                blpl fillBitsR7R9
            cmp r6, #1
                beq vectors_done2

            decodeVectorDelta

        vectors_done2:
            finishVector 1

            @ pop {r11}
            //interlock
            adds r11, r11, #(1 << 16)
            bcc 2b

            push {r11}
            //create the prediction vector
            ldrsh r11, [r10, #-4] //(x-1,y)
            ldrsh r7, [r10] //(x,y-1)
            ldrsh r5, [r10, #-2] //(x-1,y)
            ldrsh r8, [r10, #2] //(x,y-1)
            //x
            cmp r7, r11
                movgt r11, r7
            //y
            cmp r8, r5
                movgt r5, r8

            mov r6, r3, lsr #31
            mov r3, r3, lsl #1
            adds r4, r4, #1
                blpl fillBitsR7R9
            cmp r6, #1
                beq vectors_done_last_column2

            decodeVectorDelta

        vectors_done_last_column2:
            finishVector 1

            @ pop {r11}

        subs r11, r11, #1
        bne 1b

    mov r0, r1
    rsb r1, r4, #16
    cmp r1, #16
        subge r0, r0, #2
    add sp, sp, #stack_size
    ldmfd sp!, {r4-r11,pc}

.pool

//r0 = fv_decoder_t* dec
//r1 = const u16* src
//r2 = u8* dst
.global fv_decodePFrameDcts
fv_decodePFrameDcts:
    stmfd sp!, {r4-r11,lr}
stack_size = 64 * 2 * 3 + 3 * 64 + 4
    sub sp, sp, #stack_size
lastGDC_offset = stack_size - 4
    //setup bitreader
    ldrh r3, [r1], #2
    ldrh r12, [r1], #2
    mov r4, #-16 //r4 = remaining
    mov r3, r3, lsl #16 //r3 = bits
    orr r3, r3, r12

    ldr r11, [r0, #fv_decoder_asm__yBlocks]
    @ mov r11, #18
    1:
        mov r10, #0
        sub r11, r11, #(32 << 16)
        2:
            push {r11}
#define stack_offset 4

            //clear dct
            mov r5, #0
            mov r6, #0
            mov r7, #0
            mov r8, #0
            add r12, sp, #stack_offset + 64 * 3
        .rept 24
            stmia r12!, {r5-r8}
        .endr

            ldr r8, [r0, #fv_decoder_asm__vlcIdxTab]
            ldr r11, [r0, #fv_decoder_asm__vlcBitTab2]
            ldr r12, [r0, #fv_decoder_asm__vlcPackTab]

            movs r3, r3, lsl #1
            adc r10, r10, r10 //r10 = (r10 << 1) | isIFrame
            push {r2, r10}
#undef stack_offset
#define stack_offset 12
            mov r10, #3
                bcs pframe_iblock

            adds r4, r4, #1
                blpl fillBitsR7R9

            mov r6, r3, lsr #31
            mov r3, r3, lsl #1
            adds r4, r4, #1
                blpl fillBitsR7R9
            cmp r6, #1
                moveq r2, #0
                movne r2, #(1 << 16)
                addeq r5, sp, #stack_offset + 64 * 3
                bleq readDCT

            mov r6, r3, lsr #31
            mov r3, r3, lsl #1
            adds r4, r4, #1
                blpl fillBitsR7R9
            cmp r6, #1
                orrne r2, #(2 << 16)
                addeq r5, sp, #stack_offset + 64 * 3 + 64 * 2
                bleq readDCT

            mov r6, r3, lsr #31
            mov r3, r3, lsl #1
            adds r4, r4, #1
                blpl fillBitsR7R9
            cmp r6, #1
                orrne r2, #(4 << 16)
                addeq r5, sp, #stack_offset + 64 * 3 + 64 * 2 * 2
                bleq readDCT

#define DST_OFFSET_G(x,y)   ((y) * 8 + (x))
#define DST_OFFSET_R(x,y)   (64 + (y) * 8 + (x))
#define DST_OFFSET_B(x,y)   (2 * 64 + (y) * 8 + (x))
#define DCT_OFFSET(idx)     (stack_offset + 64 * 3 + 2 * 4 * (idx))

            push {r0,r1,r3}
#undef stack_offset
#define stack_offset (12 + 3 * 4)

            mov r3, #16
            mov r12, #0xFF
            ldr r1, [r0, #fv_decoder_asm__dequantP1]
            ldr r0, [r0, #fv_decoder_asm__dequantP0]
            ldr r10, [sp, #stack_offset - 12]

            tst r2, #(1 << 16)
                beq p_block_has_g_dct

            mov r6, #0
            mov r7, #0
            mov r8, #0
            mov r9, #0
            add r5, r10, #DST_OFFSET_G(0,0)
            stmia r5!, {r6-r9}
            stmia r5!, {r6-r9}
            stmia r5!, {r6-r9}
            stmia r5!, {r6-r9}
            b p_block_r

        p_block_has_g_dct:
            ldr r6, [sp, #DCT_OFFSET(0)]
            ldr r7, [sp, #DCT_OFFSET(0) + 4]

            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_G(0,0), DCT_OFFSET(1)
            idct2_fast_p DST_OFFSET_G(0,0), DCT_OFFSET(1)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_G(2,0), DCT_OFFSET(2)
            idct2_fast_p DST_OFFSET_G(2,0), DCT_OFFSET(2)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_G(0,1), DCT_OFFSET(3)
            idct2_fast_p DST_OFFSET_G(0,1), DCT_OFFSET(3)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_G(2,1), DCT_OFFSET(4)
            idct2_fast_p DST_OFFSET_G(2,1), DCT_OFFSET(4)

            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_G(4,0), DCT_OFFSET(5)
            idct2_fast_p DST_OFFSET_G(4,0), DCT_OFFSET(5)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_G(6,0), DCT_OFFSET(6)
            idct2_fast_p DST_OFFSET_G(6,0), DCT_OFFSET(6)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_G(4,1), DCT_OFFSET(7)
            idct2_fast_p DST_OFFSET_G(4,1), DCT_OFFSET(7)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_G(6,1), DCT_OFFSET(8)
            idct2_fast_p DST_OFFSET_G(6,1), DCT_OFFSET(8)

            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_G(0,4), DCT_OFFSET(9)
            idct2_fast_p DST_OFFSET_G(0,4), DCT_OFFSET(9)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_G(2,4), DCT_OFFSET(10)
            idct2_fast_p DST_OFFSET_G(2,4), DCT_OFFSET(10)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_G(0,5), DCT_OFFSET(11)
            idct2_fast_p DST_OFFSET_G(0,5), DCT_OFFSET(11)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_G(2,5), DCT_OFFSET(12)
            idct2_fast_p DST_OFFSET_G(2,5), DCT_OFFSET(12)

            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_G(4,4), DCT_OFFSET(13)
            idct2_fast_p DST_OFFSET_G(4,4), DCT_OFFSET(13)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_G(6,4), DCT_OFFSET(14)
            idct2_fast_p DST_OFFSET_G(6,4), DCT_OFFSET(14)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_G(4,5), DCT_OFFSET(15)
            idct2_fast_p DST_OFFSET_G(4,5), DCT_OFFSET(15)        
            orrs r11, r6, r7

#undef DCT_OFFSET
#define DCT_OFFSET(idx)     (stack_offset + 64 * 3 + 64 * 2 + 2 * 4 * (idx))

            idct2_fast_zero DST_OFFSET_G(6,5)
            idct2_fast_p DST_OFFSET_G(6,5)

        p_block_r:

            tst r2, #(2 << 16)
                beq p_block_has_r_dct

            mov r6, #0
            mov r7, #0
            mov r8, #0
            mov r9, #0
            add r5, r10, #DST_OFFSET_R(0,0)
            stmia r5!, {r6-r9}
            stmia r5!, {r6-r9}
            stmia r5!, {r6-r9}
            stmia r5!, {r6-r9}
            b p_block_b

        p_block_has_r_dct:

            ldr r6, [sp, #DCT_OFFSET(0)]
            ldr r7, [sp, #DCT_OFFSET(0) + 4]

            //Red
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_R(0,0), DCT_OFFSET(1)
            idct2_fast_p DST_OFFSET_R(0,0), DCT_OFFSET(1)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_R(2,0), DCT_OFFSET(2)
            idct2_fast_p DST_OFFSET_R(2,0), DCT_OFFSET(2)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_R(0,1), DCT_OFFSET(3)
            idct2_fast_p DST_OFFSET_R(0,1), DCT_OFFSET(3)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_R(2,1), DCT_OFFSET(4)
            idct2_fast_p DST_OFFSET_R(2,1), DCT_OFFSET(4)
 
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_R(4,0), DCT_OFFSET(5)
            idct2_fast_p DST_OFFSET_R(4,0), DCT_OFFSET(5)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_R(6,0), DCT_OFFSET(6)
            idct2_fast_p DST_OFFSET_R(6,0), DCT_OFFSET(6)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_R(4,1), DCT_OFFSET(7)
            idct2_fast_p DST_OFFSET_R(4,1), DCT_OFFSET(7)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_R(6,1), DCT_OFFSET(8)
            idct2_fast_p DST_OFFSET_R(6,1), DCT_OFFSET(8)

            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_R(0,4), DCT_OFFSET(9)
            idct2_fast_p DST_OFFSET_R(0,4), DCT_OFFSET(9)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_R(2,4), DCT_OFFSET(10)
            idct2_fast_p DST_OFFSET_R(2,4), DCT_OFFSET(10)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_R(0,5), DCT_OFFSET(11)
            idct2_fast_p DST_OFFSET_R(0,5), DCT_OFFSET(11)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_R(2,5), DCT_OFFSET(12)
            idct2_fast_p DST_OFFSET_R(2,5), DCT_OFFSET(12)

            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_R(4,4), DCT_OFFSET(13)
            idct2_fast_p DST_OFFSET_R(4,4), DCT_OFFSET(13)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_R(6,4), DCT_OFFSET(14)
            idct2_fast_p DST_OFFSET_R(6,4), DCT_OFFSET(14)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_R(4,5), DCT_OFFSET(15)
            idct2_fast_p DST_OFFSET_R(4,5), DCT_OFFSET(15)
            orrs r11, r6, r7

#undef DCT_OFFSET
#define DCT_OFFSET(idx)     (stack_offset + 64 * 3 + 64 * 2 * 2 + 2 * 4 * (idx))

            idct2_fast_zero DST_OFFSET_R(6,5)
            idct2_fast_p DST_OFFSET_R(6,5)

        p_block_b:

            tst r2, #(4 << 16)
                beq p_block_has_b_dct

            mov r6, #0
            mov r7, #0
            mov r8, #0
            mov r9, #0
            add r5, r10, #DST_OFFSET_B(0,0)
            stmia r5!, {r6-r9}
            stmia r5!, {r6-r9}
            stmia r5!, {r6-r9}
            stmia r5!, {r6-r9}
            b p_block_dct_done

        p_block_has_b_dct:
            
            ldr r6, [sp, #DCT_OFFSET(0)]
            ldr r7, [sp, #DCT_OFFSET(0) + 4]

            //Blue
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_B(0,0), DCT_OFFSET(1)
            idct2_fast_p DST_OFFSET_B(0,0), DCT_OFFSET(1)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_B(2,0), DCT_OFFSET(2)
            idct2_fast_p DST_OFFSET_B(2,0), DCT_OFFSET(2)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_B(0,1), DCT_OFFSET(3)
            idct2_fast_p DST_OFFSET_B(0,1), DCT_OFFSET(3)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_B(2,1), DCT_OFFSET(4)
            idct2_fast_p DST_OFFSET_B(2,1), DCT_OFFSET(4)
 
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_B(4,0), DCT_OFFSET(5)
            idct2_fast_p DST_OFFSET_B(4,0), DCT_OFFSET(5)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_B(6,0), DCT_OFFSET(6)
            idct2_fast_p DST_OFFSET_B(6,0), DCT_OFFSET(6)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_B(4,1), DCT_OFFSET(7)
            idct2_fast_p DST_OFFSET_B(4,1), DCT_OFFSET(7)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_B(6,1), DCT_OFFSET(8)
            idct2_fast_p DST_OFFSET_B(6,1), DCT_OFFSET(8)

            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_B(0,4), DCT_OFFSET(9)
            idct2_fast_p DST_OFFSET_B(0,4), DCT_OFFSET(9)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_B(2,4), DCT_OFFSET(10)
            idct2_fast_p DST_OFFSET_B(2,4), DCT_OFFSET(10)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_B(0,5), DCT_OFFSET(11)
            idct2_fast_p DST_OFFSET_B(0,5), DCT_OFFSET(11)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_B(2,5), DCT_OFFSET(12)
            idct2_fast_p DST_OFFSET_B(2,5), DCT_OFFSET(12)

            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_B(4,4), DCT_OFFSET(13)
            idct2_fast_p DST_OFFSET_B(4,4), DCT_OFFSET(13)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_B(6,4), DCT_OFFSET(14)
            idct2_fast_p DST_OFFSET_B(6,4), DCT_OFFSET(14)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_B(4,5), DCT_OFFSET(15)
            idct2_fast_p DST_OFFSET_B(4,5), DCT_OFFSET(15)
            orrs r11, r6, r7
            idct2_fast_zero DST_OFFSET_B(6,5), DST_OFFSET_B(4,5)
            idct2_fast_p DST_OFFSET_B(6,5), DST_OFFSET_B(4,5)

        p_block_dct_done:

            pop {r0,r1,r3}

            pop {r2, r10, r11}

            add r2, r2, #64 * 3

            adds r11, r11, #(1 << 16)
            bcc 2b
        add lr, r0, r11, lsl #2
        str r10, [lr, #fv_decoder_asm__pFrameIsIBlock - 4]
        subs r11, r11, #1
        bne 1b

    add sp, sp, #stack_size
    ldmfd sp!, {r4-r11,pc}

#undef stack_offset
#undef DCT_OFFSET
#undef DST_OFFSET_R
#undef DST_OFFSET_G
#undef DST_OFFSET_B

pframe_iblock:
#define stack_offset 12
    adds r4, r4, #1
        blpl fillBitsR7R9
    
    add r5, sp, #stack_offset + 64 * 3
    bl readDCT

    add r5, sp, #stack_offset + 64 * 3 + 64 * 2            
    bl readDCT

    add r5, sp, #stack_offset + 64 * 3 + 64 * 2 * 2
    bl readDCT

#define DST_OFFSET_G(x,y)   (stack_offset + (y) * 8 + (x))
#define DST_OFFSET_R(x,y)   (stack_offset + 64 + (y) * 8 + (x))
#define DST_OFFSET_B(x,y)   (stack_offset + 2 * 64 + (y) * 8 + (x))
#define DCT_OFFSET(idx)     (stack_offset + 64 * 3 + 2 * 4 * (idx))

    push {r0,r1,r3}
#undef stack_offset
#define stack_offset (12 + 3 * 4)

    mov r3, #16
    ldr r12, [r0, #fv_decoder_asm__clampTable]
    ldr r1, [r0, #fv_decoder_asm__dequant1]
    ldr r0, [r0, #fv_decoder_asm__dequant0]
    ldr r6, [sp, #DCT_OFFSET(0)]
    ldr r7, [sp, #DCT_OFFSET(0) + 4]
    add r2, r3, r12, lsl #5

    idct2_fast DST_OFFSET_G(0,0), DCT_OFFSET(1)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_G(2,0), DST_OFFSET_G(0,0), DCT_OFFSET(2)
    idct2_add_fast DST_OFFSET_G(2,0), DST_OFFSET_G(0,0), DCT_OFFSET(2)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_G(0,1), DST_OFFSET_G(0,0), DCT_OFFSET(3)
    idct2_add_fast DST_OFFSET_G(0,1), DST_OFFSET_G(0,0), DCT_OFFSET(3)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_G(2,1), DST_OFFSET_G(0,1), DCT_OFFSET(4)
    idct2_add_fast DST_OFFSET_G(2,1), DST_OFFSET_G(0,1), DCT_OFFSET(4)

    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_G(4,0), DST_OFFSET_G(0,0), DCT_OFFSET(5)
    idct2_add_fast DST_OFFSET_G(4,0), DST_OFFSET_G(0,0), DCT_OFFSET(5)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_G(6,0), DST_OFFSET_G(4,0), DCT_OFFSET(6)
    idct2_add_fast DST_OFFSET_G(6,0), DST_OFFSET_G(4,0), DCT_OFFSET(6)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_G(4,1), DST_OFFSET_G(4,0), DCT_OFFSET(7)
    idct2_add_fast DST_OFFSET_G(4,1), DST_OFFSET_G(4,0), DCT_OFFSET(7)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_G(6,1), DST_OFFSET_G(4,1), DCT_OFFSET(8)
    idct2_add_fast DST_OFFSET_G(6,1), DST_OFFSET_G(4,1), DCT_OFFSET(8)

    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_G(0,4), DST_OFFSET_G(0,0), DCT_OFFSET(9)
    idct2_add_fast DST_OFFSET_G(0,4), DST_OFFSET_G(0,0), DCT_OFFSET(9)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_G(2,4), DST_OFFSET_G(0,4), DCT_OFFSET(10)
    idct2_add_fast DST_OFFSET_G(2,4), DST_OFFSET_G(0,4), DCT_OFFSET(10)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_G(0,5), DST_OFFSET_G(0,4), DCT_OFFSET(11)
    idct2_add_fast DST_OFFSET_G(0,5), DST_OFFSET_G(0,4), DCT_OFFSET(11)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_G(2,5), DST_OFFSET_G(0,5), DCT_OFFSET(12)
    idct2_add_fast DST_OFFSET_G(2,5), DST_OFFSET_G(0,5), DCT_OFFSET(12)

    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_G(4,4), DST_OFFSET_G(0,4), DCT_OFFSET(13)
    idct2_add_fast DST_OFFSET_G(4,4), DST_OFFSET_G(0,4), DCT_OFFSET(13)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_G(6,4), DST_OFFSET_G(4,4), DCT_OFFSET(14)
    idct2_add_fast DST_OFFSET_G(6,4), DST_OFFSET_G(4,4), DCT_OFFSET(14)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_G(4,5), DST_OFFSET_G(4,4), DCT_OFFSET(15)
    idct2_add_fast DST_OFFSET_G(4,5), DST_OFFSET_G(4,4), DCT_OFFSET(15)        
    orrs r11, r6, r7

#undef DCT_OFFSET
#define DCT_OFFSET(idx)     (stack_offset + 64 * 3 + 64 * 2 + 2 * 4 * (idx))

    idct2_add_fast_zero DST_OFFSET_G(6,5), DST_OFFSET_G(4,5), DCT_OFFSET(0)
    idct2_add_fast DST_OFFSET_G(6,5), DST_OFFSET_G(4,5), DCT_OFFSET(0)

    //Red
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_R(0,0), DST_OFFSET_G(0,0), DCT_OFFSET(1)
    idct2_add_fast DST_OFFSET_R(0,0), DST_OFFSET_G(0,0), DCT_OFFSET(1)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_R(2,0), DST_OFFSET_R(0,0), DCT_OFFSET(2)
    idct2_add_fast DST_OFFSET_R(2,0), DST_OFFSET_R(0,0), DCT_OFFSET(2)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_R(0,1), DST_OFFSET_R(0,0), DCT_OFFSET(3)
    idct2_add_fast DST_OFFSET_R(0,1), DST_OFFSET_R(0,0), DCT_OFFSET(3)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_R(2,1), DST_OFFSET_R(0,1), DCT_OFFSET(4)
    idct2_add_fast DST_OFFSET_R(2,1), DST_OFFSET_R(0,1), DCT_OFFSET(4)

    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_R(4,0), DST_OFFSET_R(0,0), DCT_OFFSET(5)
    idct2_add_fast DST_OFFSET_R(4,0), DST_OFFSET_R(0,0), DCT_OFFSET(5)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_R(6,0), DST_OFFSET_R(4,0), DCT_OFFSET(6)
    idct2_add_fast DST_OFFSET_R(6,0), DST_OFFSET_R(4,0), DCT_OFFSET(6)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_R(4,1), DST_OFFSET_R(4,0), DCT_OFFSET(7)
    idct2_add_fast DST_OFFSET_R(4,1), DST_OFFSET_R(4,0), DCT_OFFSET(7)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_R(6,1), DST_OFFSET_R(4,1), DCT_OFFSET(8)
    idct2_add_fast DST_OFFSET_R(6,1), DST_OFFSET_R(4,1), DCT_OFFSET(8)

    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_R(0,4), DST_OFFSET_R(0,0), DCT_OFFSET(9)
    idct2_add_fast DST_OFFSET_R(0,4), DST_OFFSET_R(0,0), DCT_OFFSET(9)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_R(2,4), DST_OFFSET_R(0,4), DCT_OFFSET(10)
    idct2_add_fast DST_OFFSET_R(2,4), DST_OFFSET_R(0,4), DCT_OFFSET(10)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_R(0,5), DST_OFFSET_R(0,4), DCT_OFFSET(11)
    idct2_add_fast DST_OFFSET_R(0,5), DST_OFFSET_R(0,4), DCT_OFFSET(11)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_R(2,5), DST_OFFSET_R(0,5), DCT_OFFSET(12)
    idct2_add_fast DST_OFFSET_R(2,5), DST_OFFSET_R(0,5), DCT_OFFSET(12)

    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_R(4,4), DST_OFFSET_R(0,4), DCT_OFFSET(13)
    idct2_add_fast DST_OFFSET_R(4,4), DST_OFFSET_R(0,4), DCT_OFFSET(13)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_R(6,4), DST_OFFSET_R(4,4), DCT_OFFSET(14)
    idct2_add_fast DST_OFFSET_R(6,4), DST_OFFSET_R(4,4), DCT_OFFSET(14)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_R(4,5), DST_OFFSET_R(4,4), DCT_OFFSET(15)
    idct2_add_fast DST_OFFSET_R(4,5), DST_OFFSET_R(4,4), DCT_OFFSET(15)
    orrs r11, r6, r7

#undef DCT_OFFSET
#define DCT_OFFSET(idx)     (stack_offset + 64 * 3 + 64 * 2 * 2 + 2 * 4 * (idx))

    idct2_add_fast_zero DST_OFFSET_R(6,5), DST_OFFSET_R(4,5), DCT_OFFSET(0)
    idct2_add_fast DST_OFFSET_R(6,5), DST_OFFSET_R(4,5), DCT_OFFSET(0)

    //Blue
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_B(0,0), DST_OFFSET_G(0,0), DCT_OFFSET(1)
    idct2_add_fast DST_OFFSET_B(0,0), DST_OFFSET_G(0,0), DCT_OFFSET(1)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_B(2,0), DST_OFFSET_B(0,0), DCT_OFFSET(2)
    idct2_add_fast DST_OFFSET_B(2,0), DST_OFFSET_B(0,0), DCT_OFFSET(2)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_B(0,1), DST_OFFSET_B(0,0), DCT_OFFSET(3)
    idct2_add_fast DST_OFFSET_B(0,1), DST_OFFSET_B(0,0), DCT_OFFSET(3)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_B(2,1), DST_OFFSET_B(0,1), DCT_OFFSET(4)
    idct2_add_fast DST_OFFSET_B(2,1), DST_OFFSET_B(0,1), DCT_OFFSET(4)

    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_B(4,0), DST_OFFSET_B(0,0), DCT_OFFSET(5)
    idct2_add_fast DST_OFFSET_B(4,0), DST_OFFSET_B(0,0), DCT_OFFSET(5)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_B(6,0), DST_OFFSET_B(4,0), DCT_OFFSET(6)
    idct2_add_fast DST_OFFSET_B(6,0), DST_OFFSET_B(4,0), DCT_OFFSET(6)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_B(4,1), DST_OFFSET_B(4,0), DCT_OFFSET(7)
    idct2_add_fast DST_OFFSET_B(4,1), DST_OFFSET_B(4,0), DCT_OFFSET(7)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_B(6,1), DST_OFFSET_B(4,1), DCT_OFFSET(8)
    idct2_add_fast DST_OFFSET_B(6,1), DST_OFFSET_B(4,1), DCT_OFFSET(8)

    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_B(0,4), DST_OFFSET_B(0,0), DCT_OFFSET(9)
    idct2_add_fast DST_OFFSET_B(0,4), DST_OFFSET_B(0,0), DCT_OFFSET(9)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_B(2,4), DST_OFFSET_B(0,4), DCT_OFFSET(10)
    idct2_add_fast DST_OFFSET_B(2,4), DST_OFFSET_B(0,4), DCT_OFFSET(10)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_B(0,5), DST_OFFSET_B(0,4), DCT_OFFSET(11)
    idct2_add_fast DST_OFFSET_B(0,5), DST_OFFSET_B(0,4), DCT_OFFSET(11)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_B(2,5), DST_OFFSET_B(0,5), DCT_OFFSET(12)
    idct2_add_fast DST_OFFSET_B(2,5), DST_OFFSET_B(0,5), DCT_OFFSET(12)

    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_B(4,4), DST_OFFSET_B(0,4), DCT_OFFSET(13)
    idct2_add_fast DST_OFFSET_B(4,4), DST_OFFSET_B(0,4), DCT_OFFSET(13)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_B(6,4), DST_OFFSET_B(4,4), DCT_OFFSET(14)
    idct2_add_fast DST_OFFSET_B(6,4), DST_OFFSET_B(4,4), DCT_OFFSET(14)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_B(4,5), DST_OFFSET_B(4,4), DCT_OFFSET(15)
    idct2_add_fast DST_OFFSET_B(4,5), DST_OFFSET_B(4,4), DCT_OFFSET(15)
    orrs r11, r6, r7
    idct2_add_fast_zero DST_OFFSET_B(6,5), DST_OFFSET_B(4,5)
    idct2_add_fast DST_OFFSET_B(6,5), DST_OFFSET_B(4,5)

    pop {r0,r1,r3}
#undef stack_offset
#define stack_offset 12

    pop {r2}

#undef stack_offset
#define stack_offset 8

    add r5, sp, #(stack_offset)
    bl colorpack555_pframe_iblock

    pop {r10, r11}
    add r2, r2, #64

    adds r11, r11, #(1 << 16)
    bcc 2b

    add lr, r0, r11, lsl #2
    str r10, [lr, #fv_decoder_asm__pFrameIsIBlock - 4]

    subs r11, r11, #1
    bne 1b

    add sp, sp, #stack_size
    ldmfd sp!, {r4-r11,pc}

#undef stack_offset

colorpack555_pframe_iblock:
    push {lr}
    ldr r11,= 0xFF00FF00
    ldr lr,= 0x80008000
.rept 8
    ldr r6, [r5, #64] //R3 R2 R1 R0
    ldr r12, [r5, #(64 * 2)] //B3 B2 B1 B0
    ldr r10, [r5], #4 //G3 G2 G1 G0
    and r7, r12, r11  //B3 B1
    bic r12, r12, r11 //B2 B0
    and r8, r10, r11 //G3 G1
    bic r10, r10, r11 //G2 G0
    and r9, r6, r11 //R3 R1
    bic r6, r6, r11 //R2 R0
    orr r6, r6, r10, lsl #5
    orr r6, r6, r12, lsl #10
    orr r6, r6, lr
    orr r9, lr, r9, lsr #8
    orr r9, r9, r8, lsr #3
    orr r9, r9, r7, lsl #2
    stmia r2!, {r6,r9}

    ldr r6, [r5, #64] //R3 R2 R1 R0
    ldr r12, [r5, #(64 * 2)] //B3 B2 B1 B0
    ldr r10, [r5], #4 //G3 G2 G1 G0
    and r7, r12, r11  //B3 B1
    bic r12, r12, r11 //B2 B0
    and r8, r10, r11 //G3 G1
    bic r10, r10, r11 //G2 G0
    and r9, r6, r11 //R3 R1
    bic r6, r6, r11 //R2 R0
    orr r6, r6, r10, lsl #5
    orr r6, r6, r12, lsl #10
    orr r6, r6, lr
    orr r9, lr, r9, lsr #8
    orr r9, r9, r8, lsr #3
    orr r9, r9, r7, lsl #2
    stmia r2!, {r6,r9}
.endr
    pop {pc}

.macro finishPPixels offset1, offset2, last=0
    ldr r3, [r2]
    ldrsb r4, [r1, #(offset1)]
    mov r5, r3, lsl #22 //G
    ldrsb r7, [r1, #64 + (offset1)]
    add r5, r4, r5, lsr #27
    ldrb r5, [r12, r5]
    mov r6, r3, lsl #27
    add r6, r7, r6, lsr #27
    ldrsb r4, [r1, #64 * 2 + (offset1)]
    ldrb r6, [r12, r6]
    mov r7, r3, lsl #17
    add r4, r4, r7, lsr #27
    ldrb r4, [r12, r4]

    orr r7, r6, r5, lsl #5
    orr r7, r7, r10
    ldrsb r6, [r1, #(offset2)]
    orr r7, r7, r4, lsl #10

    mov r5, r3, lsl #6 //G
    add r5, r6, r5, lsr #27
    ldrsb r4, [r1, #64 + (offset2)]
    ldrb r5, [r12, r5]
    mov r6, r3, lsl #11 //R
    add r6, r4, r6, lsr #27
    ldrsb r4, [r1, #64 * 2 + (offset2)]
    ldrb r6, [r12, r6]
    mov r3, r3, lsl #1 //B
    add r4, r4, r3, lsr #27
    ldrb r4, [r12, r4]

    orr r7, r7, r6, lsl #16
    orr r7, r7, r5, lsl #(5 + 16)
    orr r7, r7, r4, lsl #(10 + 16)
.if last
    str r7, [r2], #(512 - 12)
.else
    str r7, [r2], #4
.endif
.endm

//without clamping
@ .macro finishPPixels offset1, offset2, last=0
@     ldr r3, [r2]
@     ldrsb r4, [r1, #(offset1)]
@     ldrsb r5, [r1, #64 + (offset1)]
@     ldrsb r6, [r1, #64 * 2 + (offset1)]
@     add r3, r3, r4, lsl #5
@     add r3, r3, r5
@     add r3, r3, r6, lsl #10

@     ldrsb r4, [r1, #(offset2)]
@     ldrsb r5, [r1, #64 + (offset2)]
@     ldrsb r6, [r1, #64 * 2 + (offset2)]
@     add r3, r3, r4, lsl #(5 + 16)
@     add r3, r3, r5, lsl #16
@     add r3, r3, r6, lsl #(10 + 16)

@ .if last
@     str r3, [r2], #(512 - 12)
@ .else
@     str r3, [r2], #4
@ .endif
@ .endm

.pool

//r0: decoder
//r1: residual src
//r2: prediction src
.global fv_finishPBlock
fv_finishPBlock:
    stmfd sp!, {r4-r11,lr}
    ldr r12, [r0, #fv_decoder_asm__clampTable]
    mov r10, #0x8000
    orr r10, r10, #0x80000000
    @ mov r11, #18
    ldr r11, [r0, #fv_decoder_asm__yBlocks]
    1:
        ldr lr, [r0, #fv_decoder_asm__yBlocks]
        mov r5, #0x04000000
        ldr r9, [r5, #0x64]//REG_DISPCAPCNT
        add lr, #1
        rsb lr, r11, lr
        @ rsb lr, r11, #19
        tst r9, #0x80000000
        beq vcount_loop_end
        vcount_loop:
            ldrh r9, [r5, #6]
            cmp r9, lr, lsl #3
            blt vcount_loop
    vcount_loop_end:
        add lr, r0, r11, lsl #2
        ldr r9, [lr, #fv_decoder_asm__pFrameIsIBlock - 4]
        sub r11, r11, #(32 << 16)
        2:
            movs r9, r9, lsl #1
                bcs finishPBlock_I
        .set dctoffs, 0
        .rept 8
            finishPPixels (dctoffs + 0), (dctoffs + 2)
            finishPPixels (dctoffs + 1), (dctoffs + 3)
            finishPPixels (dctoffs + 4), (dctoffs + 6)
            finishPPixels (dctoffs + 5), (dctoffs + 7), 1
            .set dctoffs, dctoffs + 8
        .endr
            add r1, r1, #64 * 3
            sub r2, r2, #(512 * 8 - 16)
            adds r11, r11, #(1 << 16)
            bcc 2b

        add r2, r2, #(512 * 7)
        subs r11, r11, #1
        bne 1b

    ldmfd sp!, {r4-r11,pc}

.pool

finishPBlock_I:
        .rept 7
            ldmia r1!, {r4, r6, r7, r8}
            stmia r2, {r4, r6, r7, r8}
            add r2, r2, #(256 * 2)
        .endr
            ldmia r1!, {r4, r6, r7, r8}
            stmia r2, {r4, r6, r7, r8}
            sub r2, r2, #(512 * 7 - 16)
            add r1, r1, #64
            adds r11, r11, #(1 << 16)
            bcc 2b

        add r2, r2, #(512 * 7)
        subs r11, r11, #1
        bne 1b

    ldmfd sp!, {r4-r11,pc}

.pool