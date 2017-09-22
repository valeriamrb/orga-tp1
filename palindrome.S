# $Id : Palindrome.S, hmasci Exp $

#include <mips/regdef.h>
#include <sys/syscall.h>

.text

.abicalls
.align 2

.globl Palindrome
.ent Palindrome

Palindrome:
	#debugging info: descripcion del stack frame	
	.frame $fp, 40, ra		# ver que a lo mejor 40 no es un buen numero

	#bloque para codigo pic
	.set noreorder
	.cpload t9
	.set reorder

	#creo stack frame
	subu	sp, sp, 40

	#bloque para codigo pic
	.cpstore 24

	# salvando el callee
	sw	$fp, 28(sp)
	sw	ra, 32(sp)

	move $fp, sp

	sw	a0, 40($fp)
