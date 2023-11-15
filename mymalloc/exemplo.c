#include <stdio.h>
#include "mymalloc.h"

int main (long int argc, char** argv) {
  void *a, *b;

  iniciaAlocador();               // Impressão esperada
  heapMap();                  // <vazio>

  a = (void *) alocaMem(10);
  heapMap();                  // ################**********
  b = (void *) alocaMem(4);
  heapMap();                  // ################**********##############****
  liberaMem(a);
  heapMap();                  // ################----------##############****
  liberaMem(b);                   // ################----------------------------
                                  // ou
                                  // <vazio>
  finalizaAlocador();
}
