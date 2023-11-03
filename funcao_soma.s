.section .text
.globl soma

soma:
    pushq %rbp
    movq  %rsp, %rbp
    movq    $0, %rax # long soma = 0;
    addq  %rdi, %rax # soma += a;
    addq  %rsi, %rax # soma += b;
    popq  %rbp
    ret
