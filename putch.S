# $Id : putch.S, hmasci Exp $

#include <mips/regdef.h>
#include <sys/syscall.h>

.text

.abicalls
.align 2

.globl putch
.ent putch

putch:
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
	sw	a1, 44($fp)

	###########################################################

	# a0: file desciptor de archivo de salida
	# a1: Caracter a guardar en archivo salida

	#t3 = buffer_salida + offset_salida = puntero de escritura de buffer
	############# GUARDAR CARACTER EN EL BUFFER ############
guardar_c:
	lw t0, buffer_salida
	lw t1, offset_salida
	add t3, t0, t1		#t3 = puntero de escritura de buffer
	sb a1, 0(t3)		#guardo el caracter leido en la posicion correspondiente del buffer


	############## AVANCE DE OFFSET #############
	lw t0, offset_salida
	add t0, t0, 1
	sw t0, offset_salida

	############## COMPRUEBO SI EL BUFFER SE LLENO #############
	################## AL INSERTAR EL CARACTER #################
	#Si el buffer se lleno => DESCARGO BUFFER EN DISCO
	#Si el buffer no se lleno => FIN PUTCH
	lw t8, offset_salida
	lw t7, obyte
	blt t8, t7, fin
	nop

	############ DESCARGO BUFFER EN DISCO ####################
	li v0, SYS_write
	lw a0, 40($fp)
	lw a1, buffer_salida	#a1: Puntero donde guardar datos leidos.
	lw a2, obyte		#obytes: cantidad de bytes a guardar
	syscall			#TODO: Verificar A3

	sw zero, offset_salida #reseteo el offset.

	##################### FIN PUTCH ###########################
fin:
	# restauro callee-saved regs
	lw	gp, 24(sp)
	lw	$fp, 28(sp)
	lw	ra, 32(sp)
	# destruyo stack frame
	addu	sp, sp, 40
	# vuelvo a funcion llamante
	jr	ra

	.end	putch
	.size	putch,.-putch
