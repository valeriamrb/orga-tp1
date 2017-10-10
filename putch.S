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
	.frame $fp, 32, ra		# ver que a lo mejor 40 no es un buen numero

	#bloque para codigo pic
	.set noreorder
	.cpload t9
	.set reorder

	#creo stack frame
	subu	sp, sp, 32

	#bloque para codigo pic
	.cprestore 16

	# salvando el callee
	sw	$fp, 20(sp)
	sw	ra, 24(sp)

	move 	$fp, sp

	####################### STACK FRAME ######################
	# En base a mipsabi.pdf pagina 27, tomamos a las syscalls
	# como funciones ordinarias. Por lo que necesitamos
	# reservar ra en el SRA y crear el ABA del callee.

	#	+---------------+
	# 44	|		|	\
	#	+---------------+	|
	# 40	|		|	|
	#	+---------------+	|	ABA CALLER
	# 36	|	a1	|	|
	#	+---------------+	|
	# 32	|	a0	|	/
	# 	+---------------+
	# 28	|	s0	|	\
	# 	+---------------+	|
	# 24	|	ra	|	|
	# 	+---------------+	|	SRA
	# 20	|	fp	|	|
	# 	+---------------+	|
	# 16	|	gp	|	/
	# 	+---------------+
	# 12	|		|	\
	# 	+---------------+	|
	# 08	|		|	|
	# 	+---------------+	|	ABA CALLEE
	# 04	|		|	|
	# 	+---------------+	|
	# 00	|		|	/
	# 	+---------------+

	###################### DESCRIPCION #######################
	# Coloca un caracter en el buffer de salida. Si el buffer
	# de salida se llena, dicho buffer se descarga a disco.
	# Luego, se coloca el caracter en el buffer ya vacio.

	sw	a0, 32($fp)	# a0: file desciptor de archivo de salida
	sw	a1, 36($fp)	# a1: Caracter a guardar en archivo salida

	# Reserva de registro s0
	sw 	s0, 28($fp)

	# RETORNO:
	# Si ocurre un error fatal de escritura se devuelve un 0.
	# En caso de exito se devuelve un 1.

	#################### PSEUDOCODIGO ###########################
	##	t3 = buffer_salida + 1 //t3: puntero de escritura de buffer
	##	t3[0] = a1 //guardo el caracter leido en la posicion correspondiente del buffer//
	##	offset_salida = offset_salida + 1
	##	if(offset_salida < obyte) {
	##		//Si no se lleno el buffer de salida, retorno exitoso
	##		return 1
	##	}
	##	//Si se lleno el buffer de salida lo cargo en disco
	##	cantidad_bytes = obytes
	##	[v0, a3] = write(a0, buffer_salida, cantidad_bytes)
	##	if(a3 != 0){
	##		//Se produjo error de escritura
	##		return 0
	##	}
	##	while(v0 < cantidad_bytes) {
	##	    //Si no se leyo la cantidad de bytes pedida, leo la cantidad restante
	##			cantidad_bytes = cantidad_bytes - v0
	##			[v0, a3] = write(a0, buffer_salida, cantidad_bytes)
	##			if(a3 != 0){
	##				return 0
	##			}
	##	}
	##	return 1
	################# FIN BLOQUE DE PSEUDOCODIGO ###############


	############# GUARDAR CARACTER EN EL BUFFER ############
guardar_c:
	lw t0, buffer_salida
	lw t1, offset_salida
	#t3 = buffer_salida + offset_salida = puntero de escritura de buffer
	add t3, t0, t1
	sb a1, 0(t3)		# Guardo el caracter leido en la posicio
	 			# correspondiente del buffer.

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

	##########################################
	lw 	s0, obyte	#Cantidad de bytes a leer en cada iteracion de loop

loop:	# Este loop se repite hasta que se pueda escribir la cantidad total
	# de caracteres solicitados a putch

	############ DESCARGO BUFFER EN DISCO ####################
	li v0, SYS_write
	lw a0, 32($fp)		#file desciptor de archivo de salida
	lw a1, buffer_salida	#a1: Puntero donde guardar datos leidos.
	move a2, s0		#obytes: cantidad de bytes a guardar
	syscall

	############### COMPRUEBO ERROR FATAL DE ESCRITURA ##############
	bne a3, zero, error

	# Si no hay error....
	#### VERIFICO QUE SE HAYAN ESCRITO LA CANTIDAD DE BYTES PEDIDOS ####
	blt v0, s0, decrementar

	b nodecrementar
decrementar:
	sub s0, s0, v0		# Si no se leyo la cantidad de bytes pedida
	b loop						# leo la cantidad restante.

nodecrementar:
	# Vaciado logico del buffer de salida reseteando su
	# puntero de escritura offset.
	sw zero, offset_salida

	li v0, 1	# En caso de exito devuelvo 1

	b fin

error:	li v0, 0	# En caso de error devuelvo 0
	##################### FIN PUTCH ###########################
fin:

	# Recupero registro s0
	lw 	s0, 28($fp)

	# restauro callee-saved regs
	lw	gp, 16(sp)
	lw	$fp, 20(sp)
	lw	ra, 24(sp)
	# destruyo stack frame
	addu	sp, sp, 32
	# vuelvo a funcion llamante
	jr	ra

	.end	putch
	.size	putch,.-putch
