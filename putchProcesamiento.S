# $Id : putchProcesamiento.S, hmasci Exp $

#include <mips/regdef.h>
#include <sys/syscall.h>

.text

.abicalls
.align 2

.globl putchProcesamiento
.ent putchProcesamiento

putchProcesamiento:
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

	####################### ARGUMENTOS ######################
	sw	a0, 40($fp)	# a0: puntero al buffer de procesamiento
	sw	a1, 44($fp)	# a1: Caracter a guardar en buffer

	# t3: puntero de escritura de buffer de procesamiento

	############# GUARDAR CARACTER EN EL BUFFER DE PROCESAMIENTO ############
guardar_c:
	lw t0, buffer_procesamiento
	lw t1, offset_procesamiento
	add t3, t0, t1		#t3 = buffer_procesamiento + offset_procesamiento = puntero de escritura de buffer
	sb a1, 0(t3)		#guardo el caracter leido en la posicion correspondiente del buffer
	############# FIN GUARDAR CARACTER EN EL BUFFER ############

	############## AVANCE DE OFFSET #############
	lw t1, offset_procesamiento
	add t1, t1, 1
	sw t1, offset_procesamiento
	############## FIN AVANCE DE OFFSET #############

fin:
	# restauro callee-saved regs
	lw	gp, 24(sp)
	lw	$fp, 28(sp)
	lw	ra, 32(sp)
	# destruyo stack frame
	addu	sp, sp, 40
	# vuelvo a funcion llamante
	jr	ra

	.end	putchProcesamiento
	.size	putchProcesamiento,.-putchProcesamiento
