#ifndef MYMALLOC_H_
#define MYMALLOC_H_

// Executa syscall brk para obter o endereço do topo corrente da heap e o armazena
// em uma variável global, topoInicialHeap.
void iniciaAlocador(void);

// Executa syscall brk para restaurar o valor original da heap contido em
// topoInicialHeap.
void finalizaAlocador(void);

// Indica que o bloco está livre.
int liberaMem(void *bloco);

// Aloca espaço na memória para um bloco de tamanho num_bytes.
void *alocaMem(int num_bytes);

// Imprime um mapa da região da heap a partir de topoInicialHeap.
void heapMap(void);

#endif // MYMALLOC_H_
