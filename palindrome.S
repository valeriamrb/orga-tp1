# $Id : Palindrome.S, hmasci Exp $

#include <mips/regdef.h>
#include <sys/syscall.h>

#define GETCH_EOF 256
#define GETCH_ERROR 257

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

	####################### STACK FRAME ######################
	#	+---------------+
	# 52	|	a3	|	\
	#	+---------------+	|
	# 48	|	a2	|	|
	#	+---------------+	|	ABA CALLER
	# 44	|	a1	|	|
	#	+---------------+	|
	# 40	|	a0	|	/
	# 	+---------------+
	# 36	|	s0	|	\
	# 	+---------------+	|
	# 32	|	ra	|	|
	# 	+---------------+	|	SRA
	# 28	|	fp	|	|
	# 	+---------------+	|
	# 24	|	gp	|	/
	# 	+---------------+
	# 20	|		|	\
	# 	+---------------+	|	LTA
	# 16	|  v0 (Backup)	|	/
	# 	+---------------+
	# 12	|		|	\
	# 	+---------------+	|
	# 08	|		|	|
	# 	+---------------+	|	ABA CALLEE
	# 04	|		|	|
	# 	+---------------+	|
	# 00	|		|	/
	# 	+---------------+

	####################### PARAMETROS #######################
	# Descripcion:
	# Localiza palabras palindromos en el archivo de entrada
	# y las coloca en el archivo de salida separadas por un
	# salto de linea

	# Argumentos:
	sw	a0, 40($fp)	# a0: File desciptor de archivo de entrada.
	sw	a1, 44($fp)	# a1: Tamanio en bytes del buffer de entrada.
	sw	a2, 48($fp)	# a2: File desciptor de archivo de salida.
	sw	a3, 52($fp)	# a3: Tamanio en bytes del buffer de salida.

	# Reserva de registro s0
	sw 	s0, 36($fp)	# Bandera para manejar error en mymalloc() y getch()
				# s0 = 1 OK
				# S0 = 0 ERROR

	# Retorno:
	# v0 : Devuelve 1 si el procesamiento fue finalizado
	# exitosamente, 0 en caso contrario

	###################### PSEUDOCODIGO ######################
	## s0 = 1 //Bandera para verificar error. Inicialmente no hay error.
	##
	## // Creo buffer de entrada
	## v0 = mymalloc(44($fp))
	## if(v0 != -1) {
	## 	// Creo buffer de salida
	##	v0 = mymalloc(52($fp))
	##	if(v0 != -1) {
	##		// Creo buffer de procesamiento
	##		v0 = mymalloc(*pbyte)
	##		if(v0 != -1) {
	##			// Leo todos los caracteres del archivo de
	##			// entrada
	##			while (true) {
	##				v0 = getch()    // Leo caracter en v0
	##				if(v0 == GETCH_ERROR) { // Verifico error
	##					s0 = 0	// Error en getch()
	##					break
	##				}
	##
	##				if(v0 == GETCH_EOF) // Verifico EOF
	##					break
	##
	##				// Si el caracter es valido lo guardo
	##				// en el buffer de procesamiento.
	##				if(esCaracterValido(v0)) {
	##					putchProcesamiento(v0)
	##				}
	##
	##				// Si llega un caracter invalido
	##				// compruebo si existe una palabra
	##				// en el buffer de procesamiento.
	##				// Si es capicua la descargo en el
	##				// buffer de salida.
	##				else if ( buffer_procesamiento != vacio ) {
	##					if(esCapicua())
	##						descargarPalabra()
	##					else
	##						// Se realiza un vaciado
	##						// logico de la palabra
	##						// alojada en el buffer de
	##						// procesamiento reseteando
	##						// su puntero de escritura
	##						// a la primer posicion.
	##						resetOffsetProcesamiento
	##				}
	##        		}
	##			// Si al buffer de procesamiento le queda
	##			// una palabra capicua entonces la decargo
	##			// en el buffer de salida.
	##			if (buffer_procesamiento != vacio)
	##				if(esCapicua())
	##					descargarPalabra()
	##
	##      		// Descargo del buffer de salida los
	##			// caracteres pendientes de
	##			// escribir en disco.
	##			flush()
	##			// Libero buffers
	##			myfree(buffer_procesamiento)
	##			myfree(buffer_salida)
	##			myfree(buffer_entrada)
	##		}
	##		else { // Error al crear buffer de procesamiento
	##			myfree(buffer_salida)
	##			myfree(buffer_entrada)
	##			s0 = 0 // Error en mymalloc
	##		}
	##	} else { // Error al crear buffer de salida
	##		myfree(buffer_entrada)
	##		s0 = 0 // Error en mymalloc
	##	}
	## } else {
	##	// Error al crear buffer de entrada
	##	s0 = 0 // Error en mymalloc
	## }
	##
	## # Compruebo que no haya habido error de mymalloc() o getch()
	## if(s0 = 0) {
	## 	// El procesamiento no fue realizado exitosamente
	## 	return 0
	## }
	##
	## // El procesamiento fue realizado exitosamente
	## return 1
	##


	######################### INICIO #########################
	li 	s0, 1 		# Inicialmente no hay error de mymalloc.
		 		# Si hay error se convierte en cero.
	sw 	a1, ibyte	# Guardo tamanio buffer entrada.

	################ CREO EL BUFFER DE ENTRADA ###############
	lw 	a0, 44($fp)	# a0: Tamanio de buffer en bytes.
	jal 	mymalloc

	########## COMPRUEBO QUE SE HAYA PODIDO ALLOCAR ##########
	li 	t3, -1
	bne	v0, t3, guardarpunteroentrada
	b 	error

guardarpunteroentrada:
	########### GUARDO PUNTERO A BUFFER DE ENTRADA ###########
	sw 	v0, buffer_entrada	# Guardo puntero a memoria alocada
					# en la variable global buffer_entrada

	################ CREO EL BUFFER DE SALIDA ################

	lw 	t4, 52($fp)		# 52($fp): Tamanio en bytes del buffer de salida.
	sw 	t4, obyte		# Guardo tamanio buffer entrada
	 				# en la variable global obyte

	lw 	a0, 52($fp)		# 52($fp): Tamanio en bytes del buffer de salida.
	jal 	mymalloc

	########### COMPRUEBO QUE SE HAYA PODIDO ALLOCAR #########
	li 	t3, -1
	bne	v0, t3, guardarpunterosalida
	li 	s0, 0 # Si hay error seteo en cero
	b 	borrarbufferentrada

guardarpunterosalida:
	########### GUARDO PUNTERO A BUFFER DE SALIDA ############
	sw 	v0, buffer_salida	# Guardo puntero a memoria alocada
					# en variable global

	############ CREO EL BUFFER DE PROCESAMIENTO #############
	lw 	a0, pbyte		# a0: Tamanio de buffer en bytes
	jal 	mymalloc

	########## COMPRUEBO QUE SE HAYA PODIDO ALLOCAR ##########
	li 	t3, -1
	bne	v0, t3, guardarpunteroprocesamiento
	li 	s0, 0 # Si hay error seteo en cero
	b 	borrarbuffersalida

guardarpunteroprocesamiento:
	########### GUARDO PUNTERO A BUFFER DE SALIDA ############
	sw 	v0, buffer_procesamiento	# Guardo puntero a memoria alocada
						# en variable global

	##### LEO TODOS LOS CARACTERES DEL ARCHIVO DE ENTRADA #####
	########## Y LOS IMPRIMO EN EL ARCHIVO DE SALIDA ##########
loop:
	###### LLAMO A FUNCION GETCH Y RECIBO CARACTER EN V0 ######
	lw 	a0, 40($fp)	# 40($fp): File desciptor de archivo de entrada.
	jal 	getch		#Recibo caracter leido en v0

	################ COMPRUEBO ERROR DE GETCH #################
	# Si v0 == GETCH_ERROR => Hubo un error de lectura en getch.
	li 	t2, GETCH_ERROR
	beq 	v0, t2, error

	# Backapeo el caracter que recibi en 16($fp)
	sw 	v0, 16($fp)		#16($fp): Caracter leido

	################ CONTROLO FIN DE ARCHIVO ##################
	# Si v0 == GETCH_EOF entonces se acabo el archivo. Pero antes de finalizar
	# el programa tengo que verificar si quedo una ultima palabra
	# pendiente de procesar en el buffer de procesamiento.
	li 	t1, GETCH_EOF
	beq	v0, t1, ultimaPalabra

	########### VERIFICO SI EL CARACTER ES VALIDO ############
	lw 	a0, 16($fp)		# 16($fp): caracter leido a comprobar
	jal 	esCaracterValido
	beqz 	v0, esInvalido		# v0: valido=1 invalido=0

	####### GUARDO CARACTER EN BUFFER DE PROCESAMIENTO #######
	lw 	a0, buffer_procesamiento	# a0: puntero al buffer de procesamiento
	lw 	a1, 16($fp)			# 16($fp): caracter leido a guardar
	jal 	putchProcesamiento

	# VERIFICO SI PUTCHPROCESAMIENTO SE REALIZO EXITOSAMENTE #
	bnez 	v0, siguienteCaracter
	b 	error 			# Si putchProcesamiento no fue
					# exitoso devuelvo 0 y
					# finaliza el programa.

siguienteCaracter:
	##### NUEVA ITERACION PARA LEER EL SIGUIENTE CARACTER ####
	b	loop

esInvalido:
	########### SI EL BUFFER CONTIENE ALGUNA PALABRA #########
	#################### LLAMO A ESCAPICUA ###################
	lw 	t5, offset_procesamiento# Compruebo si hay alguna palabra
					# en el buffer de procesamiento
	beqz 	t5, loop		# Si no hay ninguna palabra vuelvo
					# a loopear para seguir cargando
					# el buffer de procesamiento.
					# Este caso ocurre cuando vienen
					# dos caracteres invalidos seguidos.

	############ COMPRUEBO SI LA PALABRA ES CAPICUA ##########
	jal 	esCapicua		# capicua = 1, no capicua = 0

	### SI NO ES CAPICUA LIMPIO EL BUFFER DE PROCESAMIENTO ###
	beqz 	v0 , resetOffsetProcesamiento

	########## SI ES CAPICUA SE DESCARGA LA PALABRA ##########
	lw 	a0, 48($fp)		# 48($fp): File desciptor de archivo de salida.
	jal 	descargarPalabra	# Se descarga la palabra capicua desde el
					# buffer de procesamiento hacia el buffer
					# de salida.

	########### VERIFICO ERROR EN DESCARGARPALABRA ###########
	beq 	v0, zero, error		# Si hubo error devuelvo 0 y finalizo
	 				# el programa.

resetOffsetProcesamiento:
	########## LIMPIEZA DEL BUFFER DE PROCESAMIENTO ##########
	# En realidad se realiza una limpieza logica del buffer
	# de procesamiento reseteando su puntero de escritura
	# a la primer posicion de dicho buffer.
	sw  zero, offset_procesamiento

	##### NUEVA ITERACION PARA LEER EL SIGUIENTE CARACTER ####
	# Ahora que el buffer de procesamiento esta limpio
	# sigo leyendo caracteres de la siguiente palabra
	# a procesar.
	b loop

	# Fin del programa
	b fin

ultimaPalabra:
	### PROCESO ULTIMA PALABRA DEL BUFFER DE PROCESAMIENTO ###
	# Antes de finalizar el programa tengo que verificar
	# si quedo una ultima palabra pendiente de procesar
	# en el buffer de procesamiento.

	# Si el buffer de procesamiento esta vacio => Fin del programa.
	# Sino => Verificar si la palabra en el buffer de procesamiento es capicua.
	lw 	t5, offset_procesamiento
	beqz 	t5, fin

	############ COMPRUEBO SI LA PALABRA ES CAPICUA ##########
	jal 	esCapicua	# capicua = 1, no capicua = 0

	# Si la palabra no es capicua termina el programa
	beqz 	v0 , fin

	# Si la palabra es capicua se descarga al buffer de salida
	lw 	a0, 48($fp)		# a0: File desciptor de archivo de salida.
	jal 	descargarPalabra

fin:
	############### FLUSH DEL BUFFER DE SALIDA ###############
	# Descargo de buffer de salida los caracteres que queden
	# pendiente de escribir en disco.
	lw 	a0, 48($fp)	# a0: File desciptor de archivo de salida.
	jal 	flush

	########### ELIMINO EL BUFFER DE PROCESAMIENTO ###########
	lw 	a0, buffer_procesamiento
	jal 	myfree

borrarbuffersalida:
	################ ELIMINO EL BUFFER DE SALIDA #############
	lw 	a0, buffer_salida
	jal 	myfree

borrarbufferentrada:
	############### ELIMINO EL BUFFER DE ENTRADA #############
	lw 	a0, buffer_entrada
	jal 	myfree

	#Si hubo error de creacion de buffer de salida
	beqz 	s0, error

	################ FIN EXITOSO DEL PROGRAMA ################
	# Si llegue hasta aca el procesamiento fue exitoso y devuelvo 1
	li v0, 1
	b salir

error:
	############## FIN NO EXITOSO DEL PROGRAMA ###############
	li v0, 0 	# Si putchProcesamiento o si mymalloc no fue exitoso
	 		# devuelvo 0 y finaliza el programa

salir:

	####################### FIN PALINDROME ###################

	# Restauro registro s0
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
