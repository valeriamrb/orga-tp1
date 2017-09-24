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

	######### MUESTRO TODOS LOS CARACTERES EN ARCHIVO ##########
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

buffer_entrada:	.asciiz "xxxxxxxxxxxxxxxx"
ibyte:		.word	16
offset_entrada:	.word	0

buffer_salida:	.asciiz "xxxxxxxxxxxxxxxx"
obyte:		.word	16
offset_salida:	.word	0

caracter: 	.byte 	120
