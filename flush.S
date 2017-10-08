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

	# Reserva de registro s0
	sw 	s0, 36($fp)

	##################### ARGUMENTOS #######################
	sw	a0, 40($fp)	# a0: File desciptor de archivo de salida.

	# RETORNO:
	# En caso de exito se devuelve un 1
	# Si ocurre un error fatal de escritura se devuelve un 0.

	##########################################

	#################### PSEUDOCODIGO ###########################
	##	cantidad_bytes = offset_salida
	##	[v0, a3] = write(a0, buffer_salida, cantidad_bytes)
	##	if(a3 != 0){
	##		//Se produjo error de escritura
	##		return 0
	##	}
	##	while(v0 < cantidad_bytes) {
	##	    //Si no se leyo la cantidad de bytes pedida, leo la cantidad restante
	##			cantidad_bytes = cantidad_bytes - v0
	##			[v0, a3] = write(a1, buffer_salida, cantidad_bytes)
	##			if(a3 != 0){
	##				return 0
	##			}
	##	}
	##	return 1
	################# FIN BLOQUE DE PSEUDOCODIGO ###############

	lw 	s0, offset_salida	#Cantidad de bytes a leer en cada iteracion de loop

loop:	# Este loop se repite hasta que se pueda escribir la cantidad total
	# de caracteres solicitados a putch
	############CARGAR ARCHIVO DESDE BUFFER####################
	li v0, SYS_write
	lw a0, 40($fp)		# a0: File desciptor de archivo de salida.
	lw a1, buffer_salida	#puntero al buffer desde donde leer
	move a2, s0	#offset_salida: cantidad de bytes a guardar
	syscall

	############### COMPRUEBO ERROR FATAL DE ESCRITURA ##############
	bne a3, zero, error

	################:3
	# Si no hay error....
	#### VERIFICO QUE SE HAYAN ESCRITO LA CANTIDAD DE BYTES PEDIDOS ####
	blt v0, s0, decrementar

	b nodecrementar
decrementar:
	sub s0, s0, v0		# Si no se leyo la cantidad de bytes pedida
	b loop			# leo la cantidad restante.

nodecrementar:

	li v0, 1
	b fin

	###########FIN CARGAR ARCHIVO DESDE BUFFER###################
error:	li v0, 0
fin:

	# Recupero registro s0
	lw 	s0, 36($fp)

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
