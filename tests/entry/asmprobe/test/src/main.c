#include <stdio.h>

int asmprobe_value(void);

int main(void)
{
    int value = asmprobe_value();

    printf("asmprobe: value = %d\n", value);

    if (value != 42) {
        printf("asmprobe: FAILED\n");
        return 1;
    }

    printf("asmprobe: OK\n");
    return 0;
}
