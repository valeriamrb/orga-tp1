# $Id : getch.S, hmasci Exp $

#include <mips/regdef.h>
#include <sys/syscall.h>

#define GETCH_EOF 256
#define GETCH_ERROR 257

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

	####################### STACK FRAME ######################
	# En base a mipsabi.pdf pagina 27, tomamos a las syscalls
	# como funciones ordinarias. Por lo que necesitamos
	# reservar ra en el SRA y crear el ABA del callee.

	#	+---------------+
	# 52	|		|	\
	#	+---------------+	|
	# 48	|		|	|
	#	+---------------+	|	ABA CALLER
	# 44	|		|	|
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
	# 16	|  t2(Backup)	|	/
	# 	+---------------+
	# 12	|		|	\
	# 	+---------------+	|
	# 08	|		|	|
	# 	+---------------+	|	ABA CALLEE
	# 04	|		|	|
	# 	+---------------+	|
	# 00	|		|	/
	# 	+---------------+

	#################### PSEUDOCODIGO ###########################
	##	 // Si el buffer de entrada no esta vacio...
	##	if (offset_entrada != 0) {
	##		GOTO: LEER_CARACTER_DESDE_BUFFER
	##	}
	##	// Si el buffer de entrada esta vacio...
	##	else {
	##		s0 = ibyte // Cantidad a leer en cada iteracion
	##		t2 = 0  // Acumulador de cantidad de caracteres
	##			// cargados a buffer de entrada.
	##		while (true) {
	##			[v0, a3] = read(40($fp), buffer_entrada, s0)
	##			// Si hay un error fatal de lectura
	##			if (a3 == 0)
	##				return GETCH_ERROR
	##			// Si se alcanza EOF
	##			if (v0 == 0) {
	##				 // Si el buffer de entrada no esta vacio
	##				if (t2 != 0) {
	##					// REVISO SI EL BUFFER SE LLENO:
	##					if (buffer_completamente_lleno) {
	##						GOTO: LEER_CARACTER_DESDE_BUFFER
	##					} else
	##						// Reducir tamanio
	##						// logico de buffer
	##						ibyte = t2
	##
	##						GOTO: LEER_CARACTER_DESDE_BUFFER
	##					}
	##				// Si el buffer de entrada esta vacio
	##				} else {
	##					// Alcanzado fin de archivo
	##					// con buffer vacio.
	##					return 256
	##				}
	##			} // Si no se alcanza EOF
	##			else {
	##				// Acumulo cantidad de caracteres leidos
	##				t2 = t2 + v0
	##				// Si la cantidad leida es menor a
	##				// la cantidad pedida...
	##				if (v0 < s0) {
	##					s0 = s0 - v0
	##				} else {
	##					// REVISO SI EL BUFFER SE LLENO:
	##					if (buffer_completamente_lleno) {
	##						GOTO: LEER_CARACTER_DESDE_BUFFER
	##					} else
	##						// Reducir tamanio
	##						// logico de buffer
	##						ibyte = t2
	##
	##						GOTO: LEER_CARACTER_DESDE_BUFFER
	##					}
	##				}
	##			}
	##		}
	##	}
	##
	##	LEER_CARACTER_DESDE_BUFFER:
	##		t0 = buffer_entrada
	##		t1 = offset_entrada
	##		v0 = t0[offset_entrada]
	##		offset_entrada++
	##
	##		// Si se leyeron todos
	##		los caracteres del buffer...
	##		if (offset_entrada == ibyte)
	##		offset_entrada = 0
	##
	##		return v0
	##
	################# FIN BLOQUE DE PSEUDOCODIGO ###############


	###################### DESCRIPCION #######################
	# Lee un caracter del bufer de entrada. Si el buffer esta
	# vacio, se carga dicho buffer desde disco.

	# PARAMETROS:
	sw	a0, 40($fp)	# a0: File desciptor de archivo de entrada.

	# RETORNO:
	# v0: Caracter leido desde el buffer.
	# Si se alcanza un EOF se devuelve un GETCH_EOF.
	# Si ocurre un error fatal de lectura se devuelve un GETCH_ERROR.

	################## DECIDO SI CARGO BUFFER ##################
	# Si (offset_entrada == 0) => CARGA DE BUFFER DESDE ARCHIVO.
	# 		      Sino => LEER CARACTER DESDE EL BUFFER
	lw 	t4, offset_entrada
	bnez 	t4, leer_caracter_desde_buffer

	################### INCIO CARGA DE BUFFER #################
	lw 	s0, ibyte	#Cantidad de bytes a leer en cada iteracion de loop
	li 	t2, 0		#Cantidad total de bytes cargados a buffer_entrada

loop:	# Este loop se repite hasta que se pueda leer la cantidad total
	# de caracteres solicitados a getch.

	sw t2, 16($fp) # Backup de t2

	############### CARGA DE BUFFER DESDE ARCHIVO ##############
	li 	v0, SYS_read		#v0: Nombre syscall.
	lw 	a0, 40($fp)		#a0: File descriptor.
	lw 	a1, buffer_entrada	#a1: Puntero donde guardar datos leidos.
	move 	a2, s0			#a2: Cantidad de bytes a leer.
	syscall

	lw t2, 16($fp) # Recupero t2

	############# COMPRUEBO ERROR FATAL DE LECTURA ###########
	bne a3, zero, error

	###################### CONTROL DE EOF ####################
	# Si v0 es cero entonces se alcanzo el EOF...
	bnez v0, no_eof

	#################### EN CASO DE EOF... ###################
	# Si al alcanzar el EOF tengo el buffer_entrada con algun contenido
	# tengo que ver si se lleno completamente.
	bnez t2, verificar_si_buffer_se_lleno_completamente

	# Si se alcanzo el EOF y el buffer_entrada esta vacio devuelvo
	# el codigo de fin de archivo GETCH_EOF por que no tengo ningun
	# caracter que devolver.
	li 	v0, GETCH_EOF			# devuelvo GETCH_EOF en caso de alcanzar eof
	b fin

no_eof:
	############## ACUMULO LA CANTIDAD DE BYTES LEIDOS #############
	add t2, t2, v0	# t2: cantidad de caracteres cargados al buffer de entrada

	#### VERIFICO QUE SE HAYAN LEIDO LA CANTIDAD DE BYTES PEDIDOS ####
	# Si no se leyo la cantidad pedida leo la cantidad que falta...
	blt v0, s0, decrementar_cantidad_a_leer
	# Si se leyo la cantidad pedida tengo que verificar si el buffer se
	# lleno completamente.
	b verificar_si_buffer_se_lleno_completamente

decrementar_cantidad_a_leer:
	sub s0, s0, v0		# Si no se leyo la cantidad de bytes pedida
	b loop			# leo la cantidad restante.

verificar_si_buffer_se_lleno_completamente:
	lw  	t5, ibyte		# t5: Longitud buffer.

	# Si el buffer se carga completamente devuelvo el primer caracter
	# de este normalmente.
	# t2: Cantidad de caracteres cargados en el buffer_entrada
	beq 	t5, t2, leer_caracter_desde_buffer

	######### REDUCCION DE TAMANIO LOGICO DEL BUFFER ########
	# Si el buffer no se carga completamente reduzco su tamanio logico
	# a la cantidad de caracteres leidos de disco.
	# Esto puede ocurrir solo en la ultima lectura desde disco. Ya que
	# en el caso de que SYS_READ no pueda leer la cantidad pedida,
	# se reintenta hasta lograr leer la cantidad deseada.
	# Esto se hace debido a que la condicion para limpiar el buffer
	# de entrada es haber leido todos los caracteres de dicho buffer.
	# EL TAMANIO FISICO DEL BUFFER DE ENTRADA NO ES MODIFICADO.
	sw 	t2, ibyte		# Reduccion logica de buffer.


leer_caracter_desde_buffer:
	############### LEER CARACTER DESDE EL BUFFER ##############
	lw 	t0, buffer_entrada	# t0: Puntero al inicio del buffer.
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
error:
	li 	v0, GETCH_ERROR		# Devuelvo GETCH_ERROR en caso
					# de error fatal de lectura.
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
