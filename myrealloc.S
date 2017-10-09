# $Id : myrealloc.S, hmasci Exp $

#include <mips/regdef.h>
#include <sys/syscall.h>

.text

.abicalls
.align 2

.globl myrealloc
.ent myrealloc

myrealloc:

	################# CREACION DE STACK FRAME ###################

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

	move 	$fp, sp

	####################### STACK FRAME ######################
	#	+---------------+
	# 52	|		|	\
	#	+---------------+	|
	# 48	|	a2	|	|
	#	+---------------+	|	ABA CALLER
	# 44	|	a1	|	|
	#	+---------------+	|
	# 40	|	a0	|	/
	# 	+---------------+
	# 36	|		|	\
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

	######################## PARAMETROS #########################
	# Descripcion:
	# Crea un nuevo bloque de memoria con los datos del bloque
	# de memoria apuntado por a0 que fue previamente asignado
	# por mymalloc.

	# Argumentos:
	sw	a0, 40($fp)	# a0: Puntero al bloque de memoria previamente reservado
	sw 	a1, 44($fp)	# a1: Tamanio del bloque de memoria previamente reservado
	sw	a2, 48($fp)	# a2: Tamanio de nuevo bloque de memoria a reservar

	# Retorno:
	# v0 : Puntero al nuevo bloque de memoria reservada. Si no se puede
	# reallocar se devuelve un -1

	#################### PSEUDOCODIGO ########################
	##	// Si el tamanio nuevo es menor al viejo
	##	if (a2 < a1) {
	##		return -1
	##	} else {
	##		vo = mymalloc(48($fp))
	##		*16($fp) = v0
	##		// Si hay un error al allocar
	##		if (v0 == -1) {
	##			return -1
	##		} else {
	##			t0 = *40($fp) // Puntero al bloque viejo.
	##			t1 = *16($fp) // Puntero al bloque nuevo.
	##			t2 = *44($fp) + t0 // Puntero al siguiente del
	##					   // ultimo caracter del
	##					   // bloque viejo.
	##			// Copio caracteres...
	##			do {
	##				t4 = *t0
	##				*t1 = t4
	##				t0++
	##				t1++
	##			} while (t0 < t2)
	##			// Devuelvo puntero al bloque nuevo...
	##			myfree(40($fp))
	##			v0 = *16($fp)
	##			return v0
	##		}
	##	}

	################# COMPRUEBO QUE A2 >= A1 #################
	# Si la nueva longitud a2 no es suficiente para reallocar se devuelve un 0
	bge 	a2, a1, reservarMemoria

	li 	v0, -1	#No es posible reallocar => retorno -1
	b fin


	############### RESERVO NUEVO BLOQUE DE MEMORIA #############
reservarMemoria:
	lw 	a0, 48($fp)	# 48($fp): Tamanio de nuevo bloque de memoria a reservar
	jal 	mymalloc

	# Backup de v0
	sw 	v0, 16($fp)	# 16($fp): Puntero al nuevo bloque de memoria reservado

	########### COMPRUEBO QUE SE HAYA PODIDO ALLOCAR ############
	li 	t5, -1
	bne	v0, t5, copiarContenido

	li 	v0, -1		#No es posible reallocar => retorno -1
	b fin

	#### COPIO EL CONTENIDO DEL BLOQUE DE MEMORIA ANTERIOR  #####
	################### EN EL NUEVO BLOQUE ######################
copiarContenido:
	lw 	t0, 40($fp)	# t0 = 16($fp): Puntero al primer byte del bloque de memoria previamente reservado
	lw 	t1, 16($fp)	# t1 = 16($fp): Puntero al primer byte del nuevo bloque de memoria a reservado

	lw 	t2, 44($fp)	#      44($fp): Tamanio del bloque de memoria previamente reservado
	add 	t2, t2, t0	# t1 = 44($fp): Puntero al siguiente del ultimo byte del bloque de memoria previamente reservado

loop:
	# Copio un byte del bloque viejo al nuevo
	lb 	t4, 0(t0)
	sb 	t4, 0(t1)

	# Incremento los punteros de ambos bloques
	add 	t0, t0, 1
	add 	t1, t1, 1

	blt 	t0, t2, loop

	######### ELIMINO EL BLOQUE PREVIAMENTE RESERVADO ###########
	lw 	a0, 40($fp)	# 40($fp): Puntero al bloque de memoria previamente reservado
	jal 	myfree

	########## DEVUELVO EL PUNTERO AL NUEVO BLOQUE ##############
	################## DE MEMORIA RESERVADO #####################
	lw 	v0, 16($fp)	# 16($fp): Puntero al nuevo bloque de memoria reservado

	###################### FIN MYREALLOC ########################
fin:
	############### ELIMINACION DE STACK FRAME ##################

	# restauro callee-saved regs
	lw	gp, 24(sp)
	lw	$fp, 28(sp)
	lw	ra, 32(sp)
	# destruyo stack frame
	addu	sp, sp, 40
	# vuelvo a funcion llamante
	jr	ra

	.end	myrealloc
	.size	myrealloc,.-myrealloc
