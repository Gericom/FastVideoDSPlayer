.arm
.cpu arm7tdmi
.text

.global irq_wait
irq_wait:
    push {lr}

    mrs r12, cpsr
    orr r2, r12, #0x80 //cpsr disable irq
    msr cpsr_c, r2

    and r12, r12, #0x80

    mov r2, #0x04000000
    ldr r3, [r2, #0x208] //old ime state
    mov lr, #1
    str lr, [r2, #0x208] //enable ime

    cmp r0, #1
        bne 1f

    ldr lr, [r2, #-8] //check flags
    bic lr, lr, r1
    str lr, [r2, #-8]

1:
    ldr lr, [r2, #-8] //check flags
    tst lr, r1
        bne 2f

    swi (6 << 16) //halt
    mrs lr, cpsr
    bic lr, lr, #0x80 //cpsr enable irq
    msr cpsr_c, lr
    //here the interrupt handler will be called
    mrs lr, cpsr
    orr lr, lr, #0x80 //cpsr disable irq
    msr cpsr_c, lr
    b 1b

2:
    bic lr, lr, r1
    str lr, [r2, #-8]

    str r3, [r2, #0x208] //restore ime
    mrs lr, cpsr
    bic lr, lr, #0x80
    orr lr, lr, r12
    msr cpsr_c, lr

    pop {r3}
    bx r3