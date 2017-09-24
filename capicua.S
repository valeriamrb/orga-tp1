# $Id : Capicua.S, hmasci Exp $

#include <mips/regdef.h>
#include <sys/syscall.h>

.text

.abicalls
.align 2

.globl Capicua
.ent Capicua

Capicua:
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

#ahora si arranca el codigo

	#hago un for para establecer la longitud de la palabra
	
	sw r1, a0 #guardo lo que tengo en a0 en R1
	and r2, a0, r2 # R2 va a ser el contador del loop asi que lo inicializo en 0
loop_long:	
	and zero, zero, r1
	beq ComprobarTamañao ##(el if de C) aca tengo que comparar contra dos registros? 
	#si no es igual a 0	
	#corro los bits a derecha completnado con 0, inclemento el contador y vuelvo a loopear	
	srl r1, r1, 8
	add r2, r2, 1	#en R2 queda guardado 
	loop_long

ComprobarTamaño: and r0, r2, r0 
		be : return 0  #no se de que me disfrazo en este return



#ahora el for que compara los carteres. Ver el dibujo 1 de cynthia

	sw r3, a0 #cargo la p6albra en R3
	sub(32,r2,r5) #R5 tengo la cantidad de lugares a correr a izquierda
	sll(r4, $r5, a0) #cargo la palabra en R4 y la pongo a la izquierda

loop_capicua: 

and(r2, r0, r0) 
be Return o #mismo return de antes que no se a donde va
and ( r3, 0x000001, r6) #r6 tiene un caracter en el bit menos significatvo
and (ra, 1x00000 , r7)  #r7 tiene un caracter en el bit mas significativo
sra (r7, 24, r7) # ahora R7 tiene el caracter en el bit menos significatio
sra(r3, 8, r3) #pierdo el caracter menos significativo
srl(r4, 8 ,r4) #pierdo el caracter mas significativo
subu(r2, 1, r2)#decremento en 1 el tamaño de la palabra 
and (r6,r7, r0) #compara el primer carater y el ultimo de las palabras en r3 y r4
be loop_capicua

return 1  #tampoco sabemos a donde va este return. 



