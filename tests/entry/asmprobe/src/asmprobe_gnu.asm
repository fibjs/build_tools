/* The assembly of this library is GNU syntax (the ASM language). */
	.text
	.globl asmprobe_asm_value
	.type asmprobe_asm_value, @function
asmprobe_asm_value:
	movl $41, %eax
	ret
	.size asmprobe_asm_value, .-asmprobe_asm_value
