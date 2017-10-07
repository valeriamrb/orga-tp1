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
.globl pbyte
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

	##################### PARAMETROS ####################
	#Descripcion:
	# Localiza palabras palindromes en el archivo de entrada
	# y las coloca en el archivo de salida separadas por un
	# salto de linea

	# Argumentos:
	sw	a0, 40($fp)	# a0: File desciptor de archivo de entrada.
	sw	a1, 44($fp)	# a1: Tamanio en bytes del buffer de entrada.
	sw	a2, 48($fp)	# a2: File desciptor de archivo de salida.
	sw	a3, 52($fp)	# a3: Tamanio en bytes del buffer de salida.

	# Reserva de registro s0
	sw 	s0, 36($fp)


	# Retorno:
	# v0 : Devuelve 1 si el procesamiento fue finalizado
	# exitosamente, 0 en caso contrario

	################ INICIO #################
	li s0, 1 # inicialmente no hay error de mymalloc
		 # si hay error se convierte en cero

	################ CREO EL BUFFER DE ENTRADA #################
	sw 	a1, ibyte		# Guardo tamanio buffer entrada
	 				# en variable global

	lw 	a0, 44($fp)		# a0: Tamanio de buffer en bytes
	jal 	mymalloc

	########### COMPRUEBO QUE SE HAYA PODIDO ALLOCAR ############
	bne	v0, zero, guardarpunteroentrada  // TODO: Comparar contra -1 !!!!!!
	b 	error

guardarpunteroentrada:
	########### GUARDO PUNTERO A BUFFER DE ENTRADA ############
	sw 	v0, buffer_entrada	# Guardo puntero a memoria alocada
					# en variable global

	################ CREO EL BUFFER DE SALIDA #################

	lw 	t4, 52($fp)		# 52($fp): Tamanio en bytes del buffer de salida.
	sw 	t4, obyte		# Guardo tamanio buffer entrada
	 				# en variable global

	lw 	a0, 52($fp)		# 52($fp): Tamanio en bytes del buffer de salida.
	jal 	mymalloc

	########### COMPRUEBO QUE SE HAYA PODIDO ALLOCAR ############
	bne	v0, zero, guardarpunterosalida   // TODO: Comparar contra -1 !!!!!!
	li 	s0, 0 # Si hay error seteo en cero
	b 	borrarbufferentrada

guardarpunterosalida:
	########### GUARDO PUNTERO A BUFFER DE SALIDA ############
	sw 	v0, buffer_salida	# Guardo puntero a memoria alocada
					# en variable global

	################ CREO EL BUFFER DE PROCESAMIENTO #################
	lw 	a0, pbyte			# a0: Tamanio de buffer en bytes
	jal 	mymalloc

	########### COMPRUEBO QUE SE HAYA PODIDO ALLOCAR ############
	bne	v0, zero, guardarpunteroprocesamiento    // TODO: Comparar contra -1 !!!!!!
	li 	s0, 0 # Si hay error seteo en cero
	b 	borrarbuffersalida

guardarpunteroprocesamiento:
		########### GUARDO PUNTERO A BUFFER DE SALIDA ############
	sw 	v0, buffer_procesamiento	# Guardo puntero a memoria alocada
						# en variable global

	###### LEO TODOS LOS CARACTERES DEL ARCHIVO DE ENTRADA #####
	########### Y LOS IMPRIMO EN EL ARCHIVO DE SALIDA ##########
loop:
	# Llamo a funcion getch y recibo caracter en v0
	lw 	a0, 40($fp)	# 40($fp): File desciptor de archivo de entrada.
	jal 	getch		#Recibo caracter leido en v0

	###### COMPRUEBO ERROR DE GETCH #####
	li t2, 257
	beq v0, t2, error

	# Backapeo el caracter que recibi en 16($fp)
	sw v0, 16($fp)		#16($fp): Caracter leido

	# Si v0 == 256 entonces se acabo el archivo. Por lo tanto
	# proceso la ultima palabra que quedo pendiente en el buffer de procesamiento
	li 	t1, 256
	beq	v0, t1, ultimaPalabra


	############# VERIFICO SI EL CARACTER ES VALIDO ##############
	lw a0, 16($fp)		# 16($fp): caracter leido a comprobar
	jal esCaracterValido
	beqz v0, esInvalido	# v0: valido=1 invalido=0


	# Guardo caracter en buffer_procesamiento
	lw 	a0, buffer_procesamiento	# a0: puntero al buffer de procesamiento
	lw 	a1, 16($fp)			# 16($fp): caracter leido a guardar
	jal 	putchProcesamiento

	########## VERIFICO PUTCHPROCESAMIENTO SE REALIZO ############
	######################## EXITOSAMENTE ########################
	bnez v0, siguienteCaracter


	b error # Si putchProcesamiento no fue exitoso devuelvo 0 y finaliza el programa


siguienteCaracter:
	# Nueva iteracion
	b	loop


esInvalido:
	#Si el buffer no esta vacio, llamo a esCapicua:
	lw t5, offset_procesamiento

	beqz t5, loop #TODO: controlar errores


	jal esCapicua
	# chequeo v0
	beqz v0 , resetOffsetProcesamiento

	#Si es capicua llama a descargar palabra

	lw a0, 48($fp)
	jal descargarPalabra

	####### VERIFICO ERROR EN DESCARGARPALABRA ########
	beq v0, zero, error

resetOffsetProcesamiento:
	sw  zero, offset_procesamiento

	#loopea cargando la siguiente palabra en el buffer de procesamiento
	b loop


	b fin


ultimaPalabra:
	# Si el buffer no esta vacio => fin del programa
	# Sino => llamo a esCapicua

	# Si el buffer de procesamiento esta vacio => fin del programa
	# Sino => Verificar se el contenido del buffer de procesamiento es capicua
	lw t5, offset_procesamiento
	beqz t5, fin

	# capicua = 1, no capicua = 0
	jal esCapicua
	#Si no es capicua termina el programa
	beqz v0 , fin

	#Si es capicua se descarga la palabra al buffer de salida
	lw a0, 48($fp)		# a0: File desciptor de archivo de salida.
	jal descargarPalabra

fin:
	# Descargo de buffer de salida lo que quede pendiente de escribir
	# en disco.
	lw 	a0, 48($fp)	# a0: File desciptor de archivo de salida.
	jal 	flush


	############### ELIMINO EL BUFFER DE PROCESAMIENTO ###############
	lw 	a0, buffer_procesamiento
	jal 	myfree

borrarbuffersalida:
	############### ELIMINO EL BUFFER DE SALIDA ###############
	lw 	a0, buffer_salida
	jal 	myfree

borrarbufferentrada:
	############### ELIMINO EL BUFFER DE ENTRADA ###############
	lw 	a0, buffer_entrada
	jal 	myfree

	#Si hubo error de creacion de buffer de salida
	beqz 	s0, error

	# Si llegue hasta aca el procesamiento fue exitoso y devuelvo 1
	li v0, 1
	b salir

error:
	li v0, 0 # Si putchProcesamiento o si mymalloc no fue exitoso devuelvo 0 y finaliza el programa

salir:

	####################### FIN PALINDROME #####################

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
pbyte:		      .word 1	#Cantidad de bytes por defecto del buffer de procesamientos
offset_procesamiento: .word 0
