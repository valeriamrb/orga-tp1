# $Id : flush.S, hmasci Exp $

#include <mips/regdef.h>
#include <sys/syscall.h>

.text

.abicalls
.align 2

.globl flush
.ent flush

flush:
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

	sw	a0, 40($fp)	# a0: File desciptor de archivo de salida.

	############CARGAR ARCHIVO DESDE BUFFER####################
	li v0, SYS_write
	lw a0, 40($fp)		# a0: File desciptor de archivo de salida.
	lw a1, buffer_salida	#puntero al buffer desde donde leer  // TODO: Perdimos a0
	lw a2, offset_salida	#offset_salida: cantidad de bytes a guardar
	syscall			#TODO: Verificar A3

	###########FIN CARGAR ARCHIVO DESDE BUFFER###################
fin:
	# restauro callee-saved regs
	lw	gp, 24(sp)
	lw	$fp, 28(sp)
	lw	ra, 32(sp)
	# destruyo stack frame
	addu	sp, sp, 40
	# vuelvo a funcion llamante
	jr	ra

	.end	flush
	.size	flush,.-flush
