.section .data
    A: .quad 0
    B: .quad 0
.section .text
.globl _start

soma:
    pushq %rbp
    movq  %rsp, %rbp
    movq  A, %rax
    movq  B, %rbx
    addq  %rbx, %rax # valor de retorno fica em rax
    popq  %rbp
    ret

_start:
    movq $10, A
    movq $3, B
    call soma
    movq %rax, A
    movq $60, %rax
    movq A, %rdi
    syscall
