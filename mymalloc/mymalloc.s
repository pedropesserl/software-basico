.section .data
    topoInicialHeap: .quad 0
    fmt: .string "%s"
    secao_gerencial: .string "################"

.equ CHAR_NEWLINE, 0x0a
.equ    CHAR_HASH, 0x23
.equ    CHAR_PLUS, 0x2b
.equ   CHAR_MINUS, 0x2d

.section .text
.globl iniciaAlocador
.globl finalizaAlocador
.globl liberaMem
.globl alocaMem
.globl heapMap

# long brkFunc(void *addr);
# chama a syscall brk
brkFunc:
    pushq %rbp
    movq %rsp, %rbp

    movq $12, %rax
    # %rdi contém o valor do parâmetro da função brk
    syscall
    # %rax contém o valor de retorno

    popq %rbp
    ret

################################################################################

# void *achaBlocoAEsquerda(void *bloco_atual);
# a partir do topo inicial da pilha, percorre a lista ligada para encontrar
# o endereço do primeiro bloco à esquerda do parâmetro bloco_atual. Se não
# houver, retorna NULL.
achaBlocoAEsquerda:
    pushq %rbp
    movq %rsp, %rbp

    movq $0, %rax
    # %rdi contém o endereço de um bloco
    movq topoInicialHeap, %rsi
    addq $16, %rsi # %rsi contém o endereço do primeiro bloco
    cmpq %rdi, %rsi
    jge return_achaBlocoAEsquerda # se bloco_atual for o primeiro bloco, retorna NULL

do_while_rdx_lt_rdi:
    movq %rsi, %rax     # %rax armazena o valor de retorno
    movq -8(%rax), %rcx # %rcx armazena o tamanho do primeiro bloco
    movq %rax, %rdx
    addq $16, %rdx
    addq %rcx, %rdx     # %rdx armazena o endereço do próximo bloco
    movq %rdx, %rsi     # %rsi é um registrador auxiliar na operação %rax = %rdx
    cmpq %rdi, %rdx
    jl do_while_rdx_lt_rdi # if (%rdx < %rdi), repete

return_achaBlocoAEsquerda:
    popq %rbp
    ret

################################################################################

iniciaAlocador:
    pushq %rbp
    movq %rsp, %rbp

    movq $0, %rdi
    call brkFunc
    movq %rax, topoInicialHeap # topoInicialHeap = brk(0);

    popq %rbp
    ret

################################################################################

finalizaAlocador:
    pushq %rbp
    movq %rsp, %rbp

    movq topoInicialHeap, %rdi
    call brkFunc # brk(topoInicialHeap);

    popq %rbp
    ret

################################################################################

liberaMem:
    pushq %rbp
    movq %rsp, %rbp

    movq %rdi, %rsi # %rsi contém o endereço do início do bloco que queremos liberar
    # a seção de informações gerenciais começa 16 bytes antes
    movq -16(%rsi), %r8
    cmpq $0, %r8
    je return_liberaMem # se o bloco já estiver livre, apenas retorna
    movq $0, -16(%rsi) # marca o bloco como livre
    
    # checa os blocos à direita e à esquerda e realiza a fusão de blocos livres.
    # efetivamente:
    # se o bloco à direita existir e estiver livre:
    #   soma ao tamanho do bloco do meio o tamanho do bloco à direita
    #   (+16 referente à seção de gerenciamento)
    # se o bloco à esquerda existir e estiver livre:
    #   soma ao tamanho do bloco à esquerda o tamanho do bloco do meio
    #   (+16 referente à seção de gerenciamento)

    movq %rsi, %rcx
    movq -8(%rsi), %rdx # %rdx armazena o tamanho do bloco do meio
    addq %rdx, %rcx     # %rcx armazena o endereço da seção de informações
                        # gerenciais do bloco à direita, ou o topo da heap
                        # caso não exista bloco à direita
    pushq %rsi
    pushq %rcx # salvar registradores antes da syscall
    movq $0, %rdi
    call brkFunc # %rax armazena o topo atual da pilha
    popq %rcx
    popq %rsi # restaurar registradores após a syscall
    cmpq %rax, %rcx
    jge bloco_a_direita_analisado # if (%rcx >= %rax), não há bloco à direita

    movq (%rcx), %rdx   # %rdx armazena 1 ou 0, se o bloco à direita
                        # está respectivamente ocupado ou livre
    cmpq $0, %rdx
    jne bloco_a_direita_analisado # if (%rdx != 0), bloco ocupado
    
# bloco à direita existe e está livre:
    movq 8(%rcx), %rdx  # %rdx agora armazena o tamanho do bloco à direita
    addq %rdx, -8(%rsi) # soma ao tamanho do bloco do meio o tamanho do bloco à direita
    addq $16, -8(%rsi)  # soma ao tamanho do bloco do meio 16 bytes referentes à seção
                        # de gerenciamento do bloco à direita
bloco_a_direita_analisado:
    pushq %rsi # preservar valor de %rsi na função caller
    movq %rsi, %rdi
    call achaBlocoAEsquerda # %rax armazena o endereço do início do bloco à
                            # esquerda, ou NULL se não existir
    popq %rsi # restaurar %rsi
    cmpq $0, %rax
    je return_liberaMem # if (%rax == NULL), não há bloco à esquerda

    movq -16(%rax), %rdx # %rdx armazena 1 ou 0, se o bloco à esquerda
                         # está respectivamente ocupado ou livre
    cmpq $0, %rdx
    jne return_liberaMem # if (%rdx != 0), bloco ocupado

# bloco à esquerda existe e está livre:
    movq -8(%rsi), %rdx # %rdx agora armazena o tamanho do bloco do meio
    addq %rdx, -8(%rax) # soma ao tamanho do bloco à esquerda o tamanho do bloco do meio
    addq $16, -8(%rax)  # soma ao tamanho do bloco à esquerda 16 bytes referentes à seção
                        # de gerenciamento do bloco do meio
return_liberaMem:
    popq %rbp
    ret

################################################################################

alocaMem:
    pushq %rbp
    movq %rsp, %rbp
    
    movq %rdi, %rsi # %rsi armazena o tamanho do bloco que queremos alocar

    movq topoInicialHeap, %rcx
    pushq %rsi
    pushq %rcx # salvar registradores não-preservados antes da syscall
    movq $0, %rdi
    call brkFunc # %rax armazena o topo atual da heap
    popq %rcx
    popq %rsi # restaurar registradores não-preservados após a syscall
    
    # procura um bloco livre de tamanho maior ou igual a %rsi
while_rcx_lt_rax:
    cmpq %rax, %rcx
    jge alocar_espaco_no_topo_da_heap # chegou até o topo da heap sem achar um bloco livre
    movq (%rcx), %r8 # %r8 contém 1 ou 0, se o bloco está respectivamente ocupado ou livre
    movq 8(%rcx), %r9 # %r9 contém o tamanho do bloco
    cmpq $0, %r8
    jne bloco_invalido # ocupado
    cmpq %rsi, %r9
    jl bloco_invalido  # tamanho menor que o tamanho desejado

    # achou bloco válido
    movq %rcx, %rax
    addq $16, %rax # %rax contém o valor de retorno (endereco do bloco alocado)
    movq $1, -16(%rax)  # marca o bloco como ocupado
    jmp return_alocaMem

    bloco_invalido: # um bloco é inválido se está ocupado ou é pequeno
        addq $16, %rcx
        addq %r9, %rcx # analisar próximo bloco
        jmp while_rcx_lt_rax

alocar_espaco_no_topo_da_heap:
    addq $16, %rax # %rax contém o valor de retorno (endereco do bloco alocado)
    movq %rax, %rcx
    addq %rsi, %rcx # %rcx armazena o novo valor da brk
    pushq %rax
    pushq %rsi # salvar registradores não-preservado antes da syscall
    movq %rcx, %rdi
    call brkFunc
    popq %rsi
    popq %rax # restaurar registradores após a syscall
    movq $1, -16(%rax)  # marca o novo bloco como ocupado
    movq %rsi, -8(%rax) # escreve o tamanho do novo bloco na seção gerencial

return_alocaMem:
    popq %rbp
    ret

################################################################################

heapMap:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx # registradores preservados:
    pushq %r12 # serão usados na função por terem seus conteúdos
    pushq %r13 # inalterados antes e depois de chamadas de função
    pushq %r14
    pushq %r15
    
    movq $0, %rdi
    call brkFunc # %rax = brk(0);
    movq %rax, %rbx            # %rbx contém o endereço do topo atual
    movq topoInicialHeap, %r12 # %r12 contém o endereço do topo inicial

    while_r12_lt_rbx:
        cmpq %rbx, %r12
        jge fim_while_r12_lt_rbx # while (%r12 < %rbx)

        # imprime bytes da seção de informações gerenciais
        # movq $CHAR_HASH, %rdi
        # call putchar # putchar('#');
        # movq $CHAR_HASH, %rdi
        # call putchar # putchar('#');
        # movq $CHAR_HASH, %rdi
        # call putchar # putchar('#');
        # movq $CHAR_HASH, %rdi
        # call putchar # putchar('#');
        # movq $CHAR_HASH, %rdi
        # call putchar # putchar('#');
        # movq $CHAR_HASH, %rdi
        # call putchar # putchar('#');
        # movq $CHAR_HASH, %rdi
        # call putchar # putchar('#');
        # movq $CHAR_HASH, %rdi
        # call putchar # putchar('#');
        # movq $CHAR_HASH, %rdi
        # call putchar # putchar('#');
        # movq $CHAR_HASH, %rdi
        # call putchar # putchar('#');
        # movq $CHAR_HASH, %rdi
        # call putchar # putchar('#');
        # movq $CHAR_HASH, %rdi
        # call putchar # putchar('#');
        # movq $CHAR_HASH, %rdi
        # call putchar # putchar('#');
        # movq $CHAR_HASH, %rdi
        # call putchar # putchar('#');
        # movq $CHAR_HASH, %rdi
        # call putchar # putchar('#');
        # movq $CHAR_HASH, %rdi
        # call putchar # putchar('#');
        
        # movq $secao_gerencial, %rdi
        # call printf # printf("################");

        # movq $fmt, %rdi
        # movq $secao_gerencial, %rsi
        # call printf # printf("%s", "################");

        movq $1, %rdi # %rdi armazena STDOUT
        movq $secao_gerencial, %rsi
        movq $16, %rdx
        call write

        movq (%r12), %r13  # %r13 é 1 ou 0 se o bloco está respectivamente ocupado ou livre
        movq 8(%r12), %r14 # %r14 contém o tamanho do bloco
        cmpq $1, %r13
        je bloco_ocupado  # if (%r13 == 1), bloco ocupado

    # bloco livre:
        movq $0, %r15 # long i = 0;
        while_r15_lt_r14_bloco_livre:
            cmpq %r14, %r15
            jge imprimiu_bloco # while (%r15 < %r14)
            
            movq $CHAR_MINUS, %rdi
            call putchar # putchar('-');
            movq $0, %rdi
            call fflush # fflush(NULL);

            addq $1, %r15 # %r15++
            jmp while_r15_lt_r14_bloco_livre

        # bloco livre impresso

    bloco_ocupado:
        movq $0, %r15 # long i = 0
        while_r15_lt_r14_bloco_ocupado:
            cmpq %r14, %r15
            jge imprimiu_bloco # while (%r15 < %r14)

            movq $CHAR_PLUS, %rdi
            call putchar # putchar('+');
            movq $0, %rdi
            call fflush # fflush(NULL);

            addq $1, %r15 # %r15++
            jmp while_r15_lt_r14_bloco_ocupado

        # bloco ocupado impresso

    imprimiu_bloco:
        addq $16, %r12  # %r12 += tamanho da seção de informações gerenciais
        addq %r14, %r12 # %r12 += tamanho do bloco
        jmp while_r12_lt_rbx

fim_while_r12_lt_rbx:
    movq $CHAR_NEWLINE, %rdi
    call putchar # putchar('\n');

    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx # registradores preservados
    popq %rbp
    ret
