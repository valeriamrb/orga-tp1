# $Id : esCapicua.S, hmasci Exp $
# Devuelve 1 si la palabra es capicua, 0 en caso contrario.
# Precondicion: los caracteres deben ser validos.
#		la cadena no debe estar vacia.
#include <mips/regdef.h>
#include <sys/syscall.h>

.text

.abicalls
.align 2

.globl esCapicua
.ent esCapicua

esCapicua:
	#debugging info: descripcion del stack frame
	.frame $fp, 8, ra		# ver que a lo mejor 40 no es un buen numero

	#bloque para codigo pic
	.set noreorder
	.cpload t9
	.set reorder

	#creo stack frame
	subu	sp, sp, 8

	#bloque para codigo pic
	.cprestore 0

	# salvando el callee
	sw	$fp, 4(sp)

	move 	$fp, sp

	####################### STACK FRAME ######################

	# 	+---------------+
	# 04	|	fp	|	\
	# 	+---------------+	|	SRA
	# 00	|	gp	|	/
	# 	+---------------+

	##################### DESCRIPCION #######################
	# Determina si la pabra alojada en el buffer de procesamiento
	# es capicua.

	# Variables locales:
	# t0: puntero al primer caracter del buffer de procesamiento
	# t1: puntero al ultimo caracter del buffer de procesamiento
	# t3: primer caracter del buffer de procesamiento
	# t4: ultimo caracter del buffer de procesamiento

	# RETORNO:
	# 1 si es capicua, o en caso contrario

	#################### PSEUDOCODIGO ###########################
	##	t2 = t2 - 1
	##	t1 = t1 + t2
	##	while (t0 <= t1) {
	##		t0[0] = t3
	##		t1[0] = t4
	##		if(t3 != t4) {
	##		//La palabra no es capicua//
	##			return 0
	##		}
	##		t0 = t0 + 1
	##		t1 = t1 - 1
	##	}
	##	//La palabra es capicua//
	##	return 1
	################# FIN BLOQUE DE PSEUDOCODIGO ###############

	lw t0, buffer_procesamiento
	lw t1, buffer_procesamiento
	lw t2, offset_procesamiento
	sub t2, t2, 1
	add t1, t1, t2

loop:
	#Guardo los caracteres
	lb t3, 0(t0)
	lb t4, 0(t1)

	bne t3, t4, noEsCapicua

	add t0, t0, 1
	sub t1, t1, 1

	ble t0, t1, loop
	li v0, 1
	b fin

noEsCapicua:
	li v0, 0

fin:
	# restauro callee-saved regs
	lw	gp, 0(sp)
	lw	$fp, 4(sp)
	# destruyo stack frame
	addu	sp, sp, 8
	# vuelvo a funcion llamante
	jr	ra

	.end	esCapicua
	.size	esCapicua,.-esCapicua
