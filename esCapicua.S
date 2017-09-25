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

	move $fp, sp

	#sw	a0, 40($fp)
	#variables locales:
	# t0: puntero al primer caracter del buffer de procesamiento
	# t1: puntero al ultimo caracter del buffer de procesamiento
	# t3: primer caracter del buffer de procesamiento
	# t4: ultimo caracter del buffer de procesamiento

	lw t0, buffer_procesamiento
	lw t1, buffer_procesamiento
	lw t2, offset_procesamiento
	sub t2, t2, 1    #TODO; VERRRRRRRR
	add t1, t1, t2

loop:
	#Guardo los caracteres
	lb t3, 0(t0)
	lb t4, 0(t1)

	bne t3, t4, noEsCapicua
	nop
	add t0, t0, 1
	sub t1, t1, 1

	ble t0, t1, loop
	li v0, 1
	b fin

noEsCapicua:
	li v0, 0

fin:
	# restauro callee-saved regs
	lw	gp, 24(sp)
	lw	$fp, 28(sp)
	lw	ra, 32(sp)
	# destruyo stack frame
	addu	sp, sp, 40
	# vuelvo a funcion llamante
	jr	ra

	.end	esCapicua
	.size	esCapicua,.-esCapicua
