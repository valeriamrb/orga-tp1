# $Id : Palindrome.S, hmasci Exp $

#include <mips/regdef.h>
#include <sys/syscall.h>

.text

.abicalls
.align 2

.globl palindrome
.ent palindrome

.globl buffer_entrada
.globl ibyte
.globl offset_entrada

.globl buffer_salida
.globl obyte
.globl offset_salida

palindrome:
	#debugging info: descripcion del stack frame
	.frame 	$fp, 40, ra		# ver que a lo mejor 40 no es un buen numero

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

	##################### INICIO PALINDROME ####################
	# PARAMETROS:
	sw	a0, 40($fp)
	sw	a1, 44($fp)
	# a0: File desciptor de archivo de entrada.
	# a1: Tamanio en bytes del buffer de entrada.
	# RETORNO:

	################ CREO EL BUFFER DE ENTRADA #################
	sw 	a1, ibyte		# Guardo tamanio buffer entrada
	 				# en variable global

	lw 	a0, 44($fp)		# a0: Tamanio de buffer en bytes
	jal 	mymalloc

	sw 	v0, buffer_entrada	# Guardo puntero a memoria alocada
					# en variable global

	#### MUESTRO TODOS LOS CARACTERES DEL ARCHIVO DE ENTRADA ###
loop:
	# Llamo a funcion getch y recibo caracter en v0
	lw 	t0, 40($fp)
	move 	a0, t0
	jal 	getch

	# Si v0 == 256 entonces termina el programa
	li 	t1, 256
	beq	v0, t1, fin
	nop

	# Imprimo caracter por pantalla
	sb	v0, caracter
	li 	v0, SYS_write
	li 	a0, 1		# stdout
	la 	a1, caracter	# Direccion conde leer caracter
	li 	a2, 1		# Cantidad de bytes a escribir
	syscall			# TODO: Verificar A3
	b	loop		# jump to loop
	nop

fin:
	############### ELIMINO EL BUFFER DE ENTRADA ###############
	lw 	a0, buffer_entrada
	jal 	myfree

	####################### FIN PALINDROME #####################

	# restauro callee-saved regs
	lw	gp, 24(sp)
	lw	$fp, 28(sp)
	lw	ra, 32(sp)
	# destruyo stack frame
	addu	sp, sp, 40
	# vuelvo a funcion llamante
	jr	ra

	.end	palindrome
	.size	palindrome,.-palindrome

	.data

buffer_entrada:	.word	0	#Almacena puntero a buffer de entrada.
ibyte:		.word	1	#Almacena longitud de buffer en bytes.
offset_entrada:	.word	0	#Puntero al proximo caracter del buffer a leer.

buffer_salida:	.asciiz "xxxxxxxxxxxxxxxx"
obyte:		.word	16
offset_salida:	.word	0

caracter: 	.byte 	120
