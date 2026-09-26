#include <stdio.h>

int entrycheck_value(void);

int main(void)
{
    int value = entrycheck_value();

    printf("entrycheck: value = %d\n", value);

    if (value != 7) {
        printf("entrycheck: FAILED\n");
        return 1;
    }

    printf("entrycheck: OK\n");
    return 0;
}
