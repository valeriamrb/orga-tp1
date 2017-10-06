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
	# Descripcion:
	# Coloca un caracter en el buffer de procesamiento.

	#Arguemetnos:
	sw	a0, 40($fp)	# a0: puntero al buffer de procesamiento
	sw	a1, 44($fp)	# a1: Caracter a guardar en buffer

	# Retorno:
	# v0 : Devuelve 1 si el procesamiento fue finalizado
	# exitosamente, 0 en caso contrario

guardar_c:
	####### COMPRUEBO QUE HAYA ESPACIO PARA EL NUEVO CARACTER ########
	lw 	t0, pbyte
	lw 	t1, offset_procesamiento
	blt 	t1, t0, guardarCaracter

	########### DUPLICO TAMANIO DE BUFFER DE PROCESAMIENTO ###########
	add 	t9, t0, t0
	sw 	t9, 16($fp) # Resguardo el tamanio del nuevo bloque

	lw 	a0, buffer_procesamiento
	move 	a1, t0
	move 	a2, t9

	jal 	myrealloc

	########### COMPRUEBO QUE EL REALLOC HAYA SIDO EXITOSO ###########
	bnez v0, actualizarLongitud

	# Si el realloc no fue exitoso...
	li v0, 0

	b fin


actualizarLongitud:
	##### ACTUALIZO LAS LONGITUDES DEL BUFFER DE PROCESAMIENTO #######
	sw v0, buffer_procesamiento
	lw t3, 16($fp)
	sw t3, pbyte

	######### GUARDAR CARACTER EN EL BUFFER DE PROCESAMIENTO #########
guardarCaracter:
	lw t0, buffer_procesamiento
	lw t1, offset_procesamiento
	add t3, t0, t1		#t3 = buffer_procesamiento + offset_procesamiento = puntero de escritura de buffer
	sb a1, 0(t3)		#guardo el caracter leido en la posicion correspondiente del buffer


	############## AVANCE DE OFFSET #############
	lw t1, offset_procesamiento
	add t1, t1, 1
	sw t1, offset_procesamiento


	############## FIN putchProcesamiento #############
fin:	li v0, 1	# En caso de exito devuelvo 1
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
