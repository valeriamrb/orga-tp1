# $Id : getch.S, hmasci Exp $

#include <mips/regdef.h>
#include <sys/syscall.h>

.text

.abicalls
.align 2

.globl getch
.ent getch

getch:
	#debugging info: descripcion del stack frame
	.frame 	$fp, 40, ra	# ver que a lo mejor 40 no es un buen numero

	#bloque para codigo pic
	.set 	noreorder
	.cpload t9
	.set 	reorder

	#creo stack frame
	subu	sp, sp, 40

	#bloque para codigo pic
	.cprestore 24

	# salvando el callee
	sw	$fp, 28(sp)
	sw	ra, 32(sp)

	# Reserva de registro s0
	sw 	s0, 36($fp)


	move 	$fp, sp

	######################## INICIO GETCH ######################
	# PARAMETROS:
	sw	a0, 40($fp)
	# a0: File desciptor de archivo de entrada.
	# RETORNO:
	# v0: Caracter leido desde el buffer.
	# Si se alcanza un EOF se devuelve un 256.
	# Si ocurre un error fatal de lectura se devuelve un 257.

	################## DECIDO SI CARGO BUFFER ##################
	# Si (offset_entrada == 0) => CARGA DE BUFFER DESDE ARCHIVO.
	# 		      Sino => LEER CARACTER DESDE EL BUFFER
	lw 	t4, offset_entrada
	bnez 	t4, leer_caracter

	##########################################
	lw 	s0, ibyte	#Cantidad de bytes a leer en cada iteracion de loop
	li 	t2, 0		#Cantidad total de bytes leidos en todas las iteraciones de loop.

loop:	# Este loop se repite hasta que se pueda leer la cantidad total
	# de caracteres solicitados a getch


	sw t2, 16($fp) # Backup de t2

	############### CARGA DE BUFFER DESDE ARCHIVO ##############
	li 	v0, SYS_read		#v0: Nombre syscall.
	lw 	a0, 40($fp)		#a0: File descriptor.
	lw 	a1, buffer_entrada	#a1: Puntero donde guardar datos leidos.
	move 	a2, s0			#a2: Cantidad de bytes a leer.
	syscall

	lw t2, 16($fp) # Recupero t2

	############### COMPRUEBO ERROR FATAL DE LECTURA ##############
	bne a3, zero, error

	###################### CONTROL DE EOF ######################
	# Si v0 es cero entonces se alcanzo el fin de archivo
	# y se devuelve el numero 256.
	beqz v0, eof

	############## ACUMULO LA CANTIDAD DE BYTES LEIDOS #############
	add t2, t2, v0

	#### VERIFICO QUE SE HAYAN LEIDO LA CANTIDAD DE BYTES PEDIDOS ####
	blt v0, s0, decrementar

	b nodecrementar
decrementar:
	sub s0, s0, v0		# Si no se leyo la cantidad de bytes pedida
	b loop			# leo la cantidad restante.

nodecrementar:
	############## REDUCCION DE TAMANIO DEL BUFFER #############
	# Si el buffer no se carga completamente reduzco su tamanio
	# a la cantidad de caracteres leidos de disco. Esto puede
	# ocurrir solo en la ultima lectura desde disco.

	lw  	t5, ibyte		# t5: Longitud buffer.
	beq 	t5, t2, leer_caracter	# v0: Cantidad de caracteres leidos
					# de disco.
	sw 	v0, ibyte		# Reduccion de buffer.


leer_caracter:
	############### LEER CARACTER DESDE EL BUFFER ##############
	lw 	t0, buffer_entrada	# t0: Puntero al inicio del buffer.  TODO: Cambio por LW
	lw 	t1, offset_entrada	# t1: Offset en bytes en el buffer.
	add 	t3, t0, t1		# t3: Puntero de lectura de buffer.
	lb 	v0, 0(t3)		# v0: Devuelvo el caracter leido
					# desde el buffer.

	###################### AVANCE DE OFFSET ####################
	# Incremento el puntero de offset de buffer en 1 byte para
	# la siguiente lectura.

	lw 	t0, offset_entrada
	add 	t0, t0, 1
	sw 	t0, offset_entrada

	###################### RESET DE OFFSET #####################
	# Si se leyeron todos los caracteres del buffer reseto el
	# offset a cero para realizar nueva lectura de disco en
	# la siguiente ejecución de GETCH.

	lw 	t7, ibyte		# t7: Longitud de buffer.
	lw 	t8, offset_entrada	# t8: Offset en bytes.
	bne 	t8, t7, fin

	sw 	zero, offset_entrada	# Reseteo de offset.
	b	fin


eof:	li 	v0, 256			# devuelvo 256 en caso de
					# alcanzar eof
	b fin
error:
	li 	v0, 257			# devuelvo 257 en caso
					# de error fatal de lectura
fin:
	########################## FIN GETCH #######################

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

	.end	getch
	.size	getch,.-getch
