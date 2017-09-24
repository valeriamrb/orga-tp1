# $Id : esCaracterValido.S, hmasci Exp $

#include <mips/regdef.h>
#include <sys/syscall.h>

.text

.abicalls
.align 2

.globl esCaracterValido
.ent esCaracterValido

esCaracterValido:
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


#expresion de decimales en binario
# 96 = 1100000
# 123 = 1111011
# 47 = 101111
# 45 = 1111011
# 95 = 1011111
caracterValido:
	#debugging info: descripcion del stack frame	
	.frame $fp, 40, ra		# ver que a lo mejor 40 no es un buen numero

	#bloque para codigo pic
	.set noreorder
	.cpload t9
	.set reorder

	#creo stack frame
	subu	sp, sp, 40

	#bloque para codigo pic
	.cpstore 24

	# salvando el callee
	sw	$fp, 28(sp)
	sw	ra, 32(sp)

	move $fp, sp

	sw	a0, 40($fp)

#hay que definir las mascaras pero no encontramos la sintaxis 
m96  : 0x0000 1100000
m123 : 0x0000 1111011
m47  : 0x0000 0101111
m45  : 0x0000 1111011
m95  : 0x0000 1011111

and(A0, m95, R0)  #esta contemplado el caracter 95 que quedo en el igual del c
ble siguiente mascara 
and (A0, m123, R0)
blt EsValido

siguiente_mascara:
and(A0, m47, R0)
ble siguiente_mascara2 
and (A0, m58, R0)
blt EsValido

siguiente_mascara2:
and (a0, m45, r0)
be esValido
and (a0, la rayita, r0)
be esValido

	####################### FIN ESCARACTERVALIDO #####################

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
