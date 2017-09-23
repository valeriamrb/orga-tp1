# $Id : getch.S, hmasci Exp $

#include <mips/regdef.h>
#include <sys/syscall.h>

.text

.abicalls
.align 2

.globl getch
.ent getch

getch:
	#debugging info: descripcion del stack frame
	.frame $fp, 40, ra		# ver que a lo mejor 40 no es un buen numero

	#bloque para codigo pic
	.set noreorder
	.cpload t9
	.set reorder

	#creo stack frame
	subu	sp, sp, 40

	#bloque para codigo pic
	.cprestore 24

	# salvando el callee
	sw	$fp, 28(sp)
	sw	ra, 32(sp)

	move $fp, sp

	#argumento
	sw	a0, 40($fp)

	###########################################################

	# a0: file desciptor de archivo de entrada

	li v0, SYS_read
	#li a0, FILE_DESCRIPTOR
	la a1, buffer_entrada	#puntero al buffer donde guardar
	lw a2, ibyte		#ibytes: cantidad de bytes a leer
	syscall			#TODO: Verificar A3

	lb v0, buffer_entrada

	#lw v0, ibyte

	###########################################################
	# restauro callee-saved regs
	lw	gp, 24(sp)
	lw	$fp, 28(sp)
	lw	ra, 32(sp)
	# destruyo stack frame
	addu	sp, sp, 40
	# vuelvo a funcion llamante
	jr	ra

	.end	getch
	.size	getch,.-getch

; 	.data
; buffer: .word 0
