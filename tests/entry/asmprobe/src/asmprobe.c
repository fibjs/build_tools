/*
 * Self test payload: the value comes out of the assembly source, so the library
 * only links when the assembler of the pinned language accepted that source.
 */

int asmprobe_asm_value(void);

int asmprobe_value(void)
{
    return asmprobe_asm_value() + 1;
}
