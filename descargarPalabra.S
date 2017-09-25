# $Id : descargarPalabra.S, hmasci Exp $

#include <mips/regdef.h>
#include <sys/syscall.h>

.text

.abicalls
.align 2

.globl descargarPalabra
.ent descargarPalabra

descargarPalabra:
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

	sw	a0, 40($fp)

	###########################################################

	############# GUARDAR CARACTER EN EL BUFFER ############
	# t0: puntero al primer caracter del buffer de procesamiento
	# t1: puntero al ultimo caracter del buffer de procesamiento
	lw t0, buffer_procesamiento
	lw t1, buffer_procesamiento
	lw t2, offset_procesamiento
	sub t2, t2, 1	# TODO: Veeer
	add t1, t1, t2
loop:
	# # Llamo a funcion putch y escribo caracter en archivo de salida
	 lw 	a0, 40($fp)	# a0: file descriptor archivo salida
	 lb 	a1, 0(t0)	# a1: caracter a guardar
	 jal 	putch

	############## AVANCE DE OFFSET #############
	add t0, t0, 1
	############## FIN AVANCE DE OFFSET #############


	ble t0, t1, loop # TODO :ver si ble es menor o igual
	nop

fin:
	# restauro callee-saved regs
	lw	gp, 24(sp)
	lw	$fp, 28(sp)
	lw	ra, 32(sp)
	# destruyo stack frame
	addu	sp, sp, 40
	# vuelvo a funcion llamante
	jr	ra

	.end	descargarPalabra
	.size	descargarPalabra,.-descargarPalabra
