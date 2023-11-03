#include <stdio.h>
#include <stdlib.h>

long soma(long a, long b);

int main(void) {
    long x, y;
    scanf("%ld %ld", &x, &y);
    long z = soma(x, y);
    printf("%ld\n", z);
    return 0;
}
