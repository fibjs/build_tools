/* The assembly of this library is GNU syntax (the ASM language).  The value is
 * data, so the source assembles for every target of the tree; the two symbol
 * names cover the platforms that prefix C names with an underscore. */
	.data
	.globl asmprobe_asm_value
	.globl _asmprobe_asm_value
asmprobe_asm_value:
_asmprobe_asm_value:
	.long 41
