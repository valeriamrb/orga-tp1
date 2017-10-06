# $Id : esCaracterValido.S, hmasci Exp $
# Devuelve 1 en v0 si el carater esta dentro del rango o 0 si el carater es invalido
#include <mips/regdef.h>
#include <sys/syscall.h>

.text

.abicalls
.align 2

.globl esCaracterValido
.ent esCaracterValido

#expresion de decimales en binario
# 96 = 1100000
# 123 = 1111011
# 47 = 101111
# 45 = 1111011
# 95 = 1011111
esCaracterValido:
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

	sw	a0, 40($fp)

	#hay que definir las mascaras pero no encontramos la sintaxis
	#m96  : 1100000
	#m123 : 1111011
	#m47  : 0x0000 0101111
	#m45  : 0x0000 1111011
	#m95  : 0x0000 1011111

	li t1, 96
	li t2, 123
	li t3, 47
	li t4, 45
	li t5, 58
	li t6, 95
	li t7, 64
	li t8, 91

	#Validar Letras Minusculas
	ble a0, t1, ValidarNumeros
	
	blt a0, t2, esValido
	

ValidarNumeros:
	blt a0, t3, ValidarMayusculas
	
	blt a0, t5, esValido
	

ValidarMayusculas:
	ble a0, t7, ValidarGuiones
	
	blt a0, t8, esValido
	

ValidarGuiones:
	beq a0, t4, esValido
	
	beq a0, t6, esValido
	

	#Si paso por todas las validaciones sin saltar a es Valido devuelvo 0
	li v0, 0
	j fin

esValido:
	li v0, 1

		####################### FIN ESCARACTERVALIDO #####################
fin:
	# restauro callee-saved regs
	lw	gp, 24(sp)
	lw	$fp, 28(sp)
	lw	ra, 32(sp)
	# destruyo stack frame
	addu	sp, sp, 40
	# vuelvo a funcion llamante
	jr	ra

	.end	esCaracterValido
	.size	esCaracterValido,.-esCaracterValido
