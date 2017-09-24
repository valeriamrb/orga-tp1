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

	###########################################################

	# a0: file desciptor de archivo de salida
	# a1: Caracter a guardar en archivo salida

	lw t4, offset_salida

	############# GUARDAR CARACTER EN EL BUFFER ############
guardar_c:
	la t0, buffer_salida
	lw t1, offset_salida
	add t3, t0, t1		#t3 = buffer_entrada + offset_salida = puntero de escritura de buffer
	sb a1, 0(t3)		#guardo el caracter leido en la posicion correspondiente del buffer
	############# FIN GUARDAR CARACTER EN EL BUFFER ############

	############## AVANCE DE OFFSET #############
	lw t0, offset_salida
	add t0, t0, 1
	sw t0, offset_salida
	############## FIN AVANCE DE OFFSET #############

	lw t8, offset_salida
	lw t7, obyte
	blt t8, t7, fin #chequeo si el buffer esta lleno para copiarlo a archivo_salida.
	sw zero, offset_entrada #si el buffer se lleno reseteo el offset.

	############CARGAR ARCHIVO DESDE BUFFER####################
	li v0, SYS_write
	#li a0, FILE_DESCRIPTOR
	la a1, buffer_salida	#puntero al buffer desde donde leer  // TODO: Perdimos a0
	lw a2, obyte		#obytes: cantidad de bytes a guardar
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

	.end	putch
	.size	putch,.-putch
