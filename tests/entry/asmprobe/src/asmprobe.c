/*
 * Self test payload: the value comes out of the assembly source, so the library
 * only links when the assembler of the pinned language accepted that source.
 */

extern const int asmprobe_asm_value;

int asmprobe_value(void)
{
    return asmprobe_asm_value + 1;
}
