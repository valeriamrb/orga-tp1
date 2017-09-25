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

.globl buffer_procesamiento
.globl offset_procesamiento

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
	sw	a0, 40($fp)	# a0: File desciptor de archivo de entrada.
	sw	a1, 44($fp)	# a1: Tamanio en bytes del buffer de entrada.
	sw	a2, 48($fp)	# a2: File desciptor de archivo de salida.
	sw	a3, 52($fp)	# a3: Tamanio en bytes del buffer de salida.

	################ CREO EL BUFFER DE ENTRADA #################
	sw 	a1, ibyte		# Guardo tamanio buffer entrada
	 				# en variable global

	lw 	a0, 44($fp)		# a0: Tamanio de buffer en bytes
	jal 	mymalloc

	sw 	v0, buffer_entrada	# Guardo puntero a memoria alocada
					# en variable global

	################ CREO EL BUFFER DE SALIDA #################

	lw 	t4, 52($fp)		# 52($fp): Tamanio en bytes del buffer de salida.
	sw 	t4, obyte		# Guardo tamanio buffer entrada
	 				# en variable global

	lw 	a0, 52($fp)		# 52($fp): Tamanio en bytes del buffer de salida.
	jal 	mymalloc

	sw 	v0, buffer_salida	# Guardo puntero a memoria alocada
					# en variable global

	################ CREO EL BUFFER DE PROCESAMIENTO #################
	li 	a0, 100				# a0: Tamanio de buffer en bytes
	jal 	mymalloc

	sw 	v0, buffer_procesamiento	# Guardo puntero a memoria alocada
						# en variable global

	###### LEO TODOS LOS CARACTERES DEL ARCHIVO DE ENTRADA #####
	########### Y LOS IMPRIMO EN EL ARCHIVO DE SALIDA ##########
loop:
	# Llamo a funcion getch y recibo caracter en v0
	lw 	a0, 40($fp)	# 40($fp): File desciptor de archivo de entrada.
	jal 	getch		#Recibo caracter leido en v0

	# Backapeo el caracter que recibi en 16($fp)
	sw v0, 16($fp)		#16($fp): Caracter leido

	# Si v0 == 256 entonces termina el programa
	li 	t1, 256
	beq	v0, t1, fin	#TODO: esinvalido?
	nop

	#Verifico si el caracter es valido
	lw a0, 16($fp)		# 16($fp): caracter leido a comprobar
	jal esCaracterValido
	beqz v0, esInvalido	# v0: valido=1 invalido=0
	nop

	# Guardo caracter en buffer_procesamiento
	lw 	a0, buffer_procesamiento	# a0: puntero al buffer de procesamiento
	lw 	a1, 16($fp)			# 16($fp): caracter leido a guardar
	jal 	putchProcesamiento

	# Nueva iteracion
	b	loop
	nop

esInvalido:
	#Si el buffer no esta vacio, llamo a esCapicua:
	lw t5, offset_procesamiento
	beqz t5, loop #TODO: controlar errores
	nop

	jal esCapicua
	# chequeo v0
	beqz v0 , resetOffsetProcesamiento
	nop
	#Si es capicua llama a descargar palabra

	lw a0, 48($fp)
	jal descargarPalabra

resetOffsetProcesamiento:

	sw  zero, offset_procesamiento

	#loopea cargando la siguiente palabra en el buffer de procesamiento
	b loop
	nop

	# b flush
	# nop

fin:

	# lw a0, 48($fp)		# a2:48($fp):File desciptor de archivo de salida.
	# jal descargarPalabra

	lw 	a0, 48($fp)	# a0: File desciptor de archivo de salida.
	jal 	flush

	############### ELIMINO EL BUFFER DE ENTRADA ###############
	lw 	a0, buffer_entrada
	jal 	myfree

	############### ELIMINO EL BUFFER DE SALIDA ###############
	lw 	a0, buffer_salida
	jal 	myfree

	############### ELIMINO EL BUFFER DE PROCESAMIENTO ###############
	lw 	a0, buffer_procesamiento
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

buffer_salida:	.word 	0
obyte:		.word	1
offset_salida:	.word	0

buffer_procesamiento: .word 0
offset_procesamiento: .word 0
