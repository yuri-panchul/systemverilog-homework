# RISC-V factorial program

factorial:

        li      a0, 1
        li      t0, 2

loop:   mul     a0, a0, t0
        addi    t0, t0, 1
        beqz    zero, loop
