#include <stdio.h>

int selfcheck_value(void);

int main(void)
{
    int value = selfcheck_value();

    printf("selfcheck: value = %d\n", value);

    if (value != 42) {
        printf("selfcheck: FAILED\n");
        return 1;
    }

    printf("selfcheck: OK\n");
    return 0;
}
