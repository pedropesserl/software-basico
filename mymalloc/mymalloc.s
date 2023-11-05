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
    # supõe que %rdi já contém o valor do parâmetro da função brk
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
    pushq %rbx # registradores preservados:
    pushq %r12 # serão usados na função por terem seus conteúdos
    pushq %r13 # inalterados antes e depois de chamadas de função
    pushq %r14
    pushq %r15
    
    movq $0, %rdi
    call brk_func # %rax = brk(0);
    movq %rax, %rbx            # %rbx contém o endereço do topo atual
    movq topoInicialHeap, %r12 # %r12 contém o endereço do topo inicial

    while_r12_lt_rbx:
        cmpq %rbx, %r12
        jge fim_while_rcx_lt_rax # while (%r12 < %rbx)

        # imprime bytes da seção de informações gerenciais
        movq $CHAR_HASH, %rdi
        call putchar # putchar('#');
        movq $CHAR_HASH, %rdi
        call putchar # putchar('#');

        movq (%r12), %r13  # %r13 é 1 ou 0, se o bloco está respectivamente ocupado ou livre
        movq 8(%r12), %r14 # %r14 contém o tamanho do bloco
        cmpq %r13, $1
        je bloco_ocupado  # if (%r13 == 1), bloco ocupado

    # bloco livre:
        movq $0, %r15 # long i = 0;
        while_r15_lt_r14_bloco_livre:
            cmpq %r14, %r15
            jge imprimiu_bloco # while (%r15 < %r14)
            
            movq $CHAR_MINUS, %rdi
            call putchar # putchar('-');

            addq $1, %r15 # %r15++
            jmp while_r15_lt_r14_bloco_livre

        jmp imprimiu_bloco # bloco livre impresso

    bloco_ocupado:
        movq $0, %r15 # long i = 0
        while_r15_lt_r14_bloco_ocupado:
            cmpq %r14, %r15
            jge imprimiu_bloco # while (%r15 < %r14)

            movq $CHAR_PLUS, %rdi
            call putchar # putchar('+');

            addq $1, %r15 # %r15++
            jmp while_r15_lt_r14_bloco_ocupado

        # bloco ocupado impresso

    imprimiu_bloco:
        addq $16, %r12  # %r12 += tamanho da seção de informações gerenciais
        addq %r14, %r12 # %r12 += tamanho do bloco
        jmp while_r12_lt_rbx

fim_while_rcx_lt_rax:
    movq $CHAR_NEWLINE, %rdi
    call putchar # putchar('\n');

    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx # registradores preservados
    popq %rbp
    ret
