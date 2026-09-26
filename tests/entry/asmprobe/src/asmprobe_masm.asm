; The assembly of this library is MASM syntax (the ASM_MASM language), which is
; what the Windows toolchain of this repository assembles.

.CODE

PUBLIC asmprobe_asm_value

asmprobe_asm_value PROC
	mov eax, 41
	ret
asmprobe_asm_value ENDP

END
