# $Id : descargarPalabra.S, hmasci Exp $

#include <mips/regdef.h>
#include <sys/syscall.h>

.text

.abicalls
.align 2

.globl descargarPalabra
.ent descargarPalabra

descargarPalabra:
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
	# 48	|		|	|
	#	+---------------+	|	ABA CALLER
	# 44	|		|	|
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
	# 20	|  t1 (Backup)	|	\
	# 	+---------------+	|	LTA
	# 16	|  t0 (Backup)	|	/
	# 	+---------------+
	# 12	|		|	\
	# 	+---------------+	|
	# 08	|		|	|
	# 	+---------------+	|	ABA CALLEE
	# 04	|		|	|
	# 	+---------------+	|
	# 00	|		|	/
	# 	+---------------+

	##################### DESCRIPCION #######################

	# Descarga el contenido desde buffer de procesamiento
	# hacia el buffer de salida utilizando putch. La descarga
	# se realiza de a caracteres.

	##################### ARGUMENTOS #######################
	sw	a0, 40($fp)	# a0:File desciptor de archivo de salida.

	############# GUARDAR CARACTER EN EL BUFFER ############
	# t0: puntero al primer caracter del buffser de procesamiento
	# t1: puntero al ultimo caracter del buffer de procesamiento

	# RETORNO:
	# Si ocurre un error fatal de escritura se devuelve un 0.
	# En caso de exito se devuelve un 1

	#################### PSEUDOCODIGO ###########################
	## while(t0 <= t1) {
	##	 v0 = putch(a1) //a1: caracter a guardar en archivo de salida
	##	 if(v0 = 0) {
	##		 //Si no se pudo guardar el caracter devuelvo 0
	##		 return 0
	##	 }
	##	 t0 = t0 + 1
	## }
	##	putch(caracter_fin_de_linea)
	##	return 1
	################# FIN BLOQUE DE PSEUDOCODIGO ###############

	lw t0, buffer_procesamiento
	lw t1, offset_procesamiento
	sub t1, t1, 1
	add t1, t1, t0
loop:
	# Llamo a funcion putch y escribo caracter en archivo de salida
	lw 	a0, 40($fp)	# a0: file descriptor archivo salida
	lb 	a1, 0(t0)	# a1: caracter a guardar

	# respaldo t0 y t1 antes de llamar a putch
	sw t0, 16($fp)
	sw t1, 20($fp)

	# Guardo caracter en buffer de salida
	jal 	putch

	############## COMPRUEBO ERROR EN PUTCH #############
	beq v0, zero, error

	# restauro t0 y t1
	lw t0, 16($fp)
	lw t1, 20($fp)

	############## AVANCE DE OFFSET #############
	add t0, t0, 1

	############## LOOPEO MIENTRAS QUE EL PUNTERO #############
	############ DE LECTURA NO SE SALGA DEL BUFFER ############
	ble t0, t1, loop

	############## AGREGO CARCTER DE FIN DE LINEA #############
	lw 	a0, 40($fp)	# a0: file descriptor archivo salida
	li 	a1, 10		# a1: caracter a guardar
	jal putch

	li v0, 1	# En caso de exito devuelvo 1

	b fin
error:
	li v0, 0	# En caso de error devuelvo 0

fin:

	######### RESETEO OFFSET DE PROCESAMIENTO A CERO ##########
	sw zero, offset_procesamiento

	# restauro callee-saved regs
	lw	gp, 24(sp)
	lw	$fp, 28(sp)
	lw	ra, 32(sp)
	# destruyo stack frame
	addu	sp, sp, 40
	# vuelvo a funcion llamante
	jr	ra

	.end	descargarPalabra
	.size	descargarPalabra,.-descargarPalabra

	.rdata
