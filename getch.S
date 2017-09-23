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

	#argumento
	sw	a0, 40($fp)

	###########################################################

	# a0: file desciptor de archivo de entrada
	# a2: ibyte

	lw  t4, offset_entrada
	bnez t4, leer_c
	nop

	############# CARGA DE BUFFER DESDE ARCHIVO ############
	li v0, SYS_read
	#li a0, FILE_DESCRIPTOR
	la a1, buffer_entrada
	#puntero al buffer donde guardar
	lw a2, ibyte		#ibyte: cantidad de bytes a leer
	syscall			#TODO: Verificar A3
	############# FIN CARGA DE BUFFER DESDE ARCHIVO ############

	lw t5, ibyte
	blt v0, t5, ultbuff
	j leer_c

ultbuff:
	sw v0, ibyte

	############# LEER CARACTER DESDE EL BUFFER ############
leer_c:
	la t0, buffer_entrada
	lw t1, offset_entrada
	add t3, t0, t1		#t3 = buffer_entrada + offset_entrada = puntero de lectura de buffer
	lb v0, 0(t3)		#devuelvo el caracter leido del buffer
	############# FIN LEER CARACTER DESDE EL BUFFER ############

	############## AVANCE DE OFFSET #############
	lw t0, offset_entrada
	add t0, t0, 1
	sw t0, offset_entrada
	############## FIN AVANCE DE OFFSET #############

	lw t8, offset_entrada
	lw t7, ibyte
	bne t8, t7, fin
	nop
	sw zero, offset_entrada
fin:

	###########################################################
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

