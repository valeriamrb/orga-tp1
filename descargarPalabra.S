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


	##################### ARGUMENTOS #######################
	sw	a0, 40($fp)	# a0:File desciptor de archivo de salida.

	############# GUARDAR CARACTER EN EL BUFFER ############
	# t0: puntero al primer caracter del buffser de procesamiento
	# t1: puntero al ultimo caracter del buffer de procesamiento
	lw t0, buffer_procesamiento
	lw t1, offset_procesamiento
	sub t1, t1, 1	# TODO: ver
	add t1, t1, t0
loop:
	# Llamo a funcion putch y escribo caracter en archivo de salida
	lw 	a0, 40($fp)	# a0: file descriptor archivo salida
	lb 	a1, 0(t0)	# a1: caracter a guardar

	# respaldo t0 y t1 antes de llamar a putch
	sw t0, 16($fp)
	sw t1, 20($fp)

	# Guardo caracter en buffer de salida
	jal 	putch

	# restauro t0 y t1
	lw t0, 16($fp)
	lw t1, 20($fp)

	############## AVANCE DE OFFSET #############
	add t0, t0, 1

	############## LOOPEO MIENTRAS QUE EL PUNTERO #############
	############ DE LECTURA NO SE SALGA DEL BUFFER ############
	ble t0, t1, loop
	nop

fin:
	############## AGREGO CARCTER DE FIN DE LINEA #############
	lw 	a0, 40($fp)	# a0: file descriptor archivo salida
	li 	a1, 10		# a1: caracter a guardar
	jal putch

	######### RESETEO OFFSET DE PROCESAMIENTO A CERO ##########
	sw zero, offset_procesamiento	# TODO: ver

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

	.rdata
