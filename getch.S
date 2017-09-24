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

	move 	$fp, sp

	######################## INICIO GETCH ######################
	# PARAMETROS:
	sw	a0, 40($fp)
	# a0: File desciptor de archivo de entrada.
	# RETORNO:
	# v0: Caracter leido desde el buffer. Si se alcanza un EOF
	# se devuelve un 256.

	################## DECIDO SI CARGO BUFFER ##################
	# Si (offset_entrada == 0) => CARGA DE BUFFER DESDE ARCHIVO.
	# 		      Sino => LEER CARACTER DESDE EL BUFFER
	lw 	t4, offset_entrada
	bnez 	t4, leer_caracter
	nop

	############### CARGA DE BUFFER DESDE ARCHIVO ##############
	li 	v0, SYS_read		#v0: Nombre syscall.
	lw 	a0, 40($fp)		#a0: File descriptor.
	lw 	a1, buffer_entrada	#a1: Puntero donde guardar datos leidos.
	lw 	a2, ibyte		#a2: Cantidad de bytes a leer.
	syscall				#TODO: Verificar A3 cantidad leida

	###################### CONTROL DE EOF ######################
	# Si v0 es cero entonces se alcanzo el fin de archivo
	# y se devuelve el numero 256.
	beqz v0, eof
	nop

	############## REDUCCION DE TAMANIO DEL BUFFER #############
	# Si el buffer no se carga completamente reduzco su tamanio
	# a la cantidad de caracteres leidos de disco. Esto puede
	# ocurrir solo en la ultima lectura desde disco.

	lw  	t5, ibyte		# t5: Longitud buffer.
	beq 	t5, v0, leer_caracter	# v0: Cantidad de caracteres leidos
	nop				# de disco.
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
	nop
	sw 	zero, offset_entrada	# Reseteo de offset.
	b	fin
	nop

eof:	li 	v0, 256			# devuelvo 256 en caso de
					# alcanzar eof
fin:
	########################## FIN GETCH #######################
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
