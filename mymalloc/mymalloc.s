.section .data
    fmt_ld: .string "aaa: 0x%x\n"
    topoInicialHeap: .quad 0

.equ CHAR_NEWLINE, 0x0a
.equ    CHAR_HASH, 0x23
.equ    CHAR_PLUS, 0x2b
.equ   CHAR_MINUS, 0x2d


.section .text
.globl topoInicialHeap
.globl iniciaAlocador
.globl finalizaAlocador
.globl liberaMem
.globl alocaMem
.globl heapMap

brk_func:
    pushq %rbp
    movq %rsp, %rbp

    movq $12, %rax
    # %rdi já contém o valor do parâmetro da função brk
    syscall
    # %rax contém o valor de retorno

    popq %rbp
    ret
    
iniciaAlocador:
    pushq %rbp
    movq %rsp, %rbp

    movq $0, %rdi
    call brk_func
    movq %rax, topoInicialHeap # topoInicialHeap = brk(0);

    popq %rbp
    ret

finalizaAlocador:
    pushq %rbp
    movq %rsp, %rbp

    movq topoInicialHeap, %rdi
    call brk_func # brk(topoInicialHeap);

    popq %rbp
    ret

liberaMem:
    pushq %rbp
    movq %rsp, %rbp
    
    popq %rbp
    ret

alocaMem:
    pushq %rbp
    movq %rsp, %rbp

    popq %rbp
    ret

heapMap:
    pushq %rbp
    movq %rsp, %rbp
    
    movq $CHAR_HASH, %rdi
    call putchar # putchar('#');
    movq $CHAR_NEWLINE, %rdi
    call putchar # putchar('\n');

    popq %rbp
    ret
