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
	.frame $fp, 32, ra

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

	# Reserva de registro s0
	sw 	s0, 28($fp)

	####################### STACK FRAME ######################
	# En base a mipsabi.pdf pagina 27, tomamos a las syscalls
	# como funciones ordinarias. Por lo que necesitamos
	# reservar ra en el SRA y crear el ABA del callee.

	#	+---------------+
	# 44	|		|	\
	#	+---------------+	|
	# 40	|		|	|
	#	+---------------+	|	ABA CALLER
	# 36	|		|	|
	#	+---------------+	|
	# 32	|	a0	|	/
	# 	+---------------+
	# 28	|	s0	|	\
	# 	+---------------+	|
	# 24	|	ra	|	|
	# 	+---------------+	|	SRA CALLEE
	# 20	|	fp	|	|
	# 	+---------------+	|
	# 16	|	gp	|	/
	# 	+---------------+
	# 12	|		|	\
	#	+---------------+	|
	# 08	|		|	|
	#	+---------------+	|	ABA CALLEE
	# 04	|		|	|
	#	+---------------+	|
	# 00	|		|	/
	#	+---------------+

	##################### DESCRIPCION #######################
	# Descarga de buffer de salida los caracteres que queden
	# pendiente de escribir en disco.

	# ARGUMENTOS:
	sw	a0, 32($fp)	# a0: File desciptor de archivo de salida.

	# RETORNO:
	# En caso de exito se devuelve un 1
	# Si ocurre un error fatal de escritura se devuelve un 0.

	#################### PSEUDOCODIGO ########################
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
	################# FIN BLOQUE DE PSEUDOCODIGO #############

	lw 	s0, offset_salida	#Cantidad de bytes a leer en cada iteracion de loop

loop:	# Este loop se repite hasta que se pueda escribir la cantidad total
	# de caracteres solicitados a putch
	############CARGAR ARCHIVO DESDE BUFFER####################
	li 	v0, SYS_write
	lw 	a0, 32($fp)		# a0: File desciptor de archivo de salida.
	lw 	a1, buffer_salida	#puntero al buffer desde donde leer
	move 	a2, s0	#offset_salida: cantidad de bytes a guardar
	syscall

	############ COMPRUEBO ERROR FATAL DE ESCRITURA ##########
	bne 	a3, zero, error


	# Si no hay error....
	#### VERIFICO QUE SE HAYAN ESCRITO LA CANTIDAD DE BYTES PEDIDOS ####
	blt 	v0, s0, decrementar

	b 	nodecrementar
decrementar:
	sub 	s0, s0, v0	# Si no se leyo la cantidad de bytes pedida
	b 	loop		# leo la cantidad restante.

nodecrementar:

	li 	v0, 1
	b 	fin

	############# FIN CARGAR ARCHIVO DESDE BUFFER ############
error:	li 	v0, 0
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

	.end	flush
	.size	flush,.-flush
