/*
 * $Id: main.c,v 1.1 2008/04/22 03:11:50 hmasci Exp $
 *
 * 66.20 - Ejercicio A.8 (Patterson - Hennessy)
 */

#include <stdio.h>

int getch(int fd_entrada);

int putch(int fd_salida, int caracter);

int main(void)
{
	// int n;
	int v0;
	FILE* archivo_entrada;
	archivo_entrada = fopen("entrada","r");

	FILE* archivo_salida;
	archivo_salida = fopen("salida","w");

	//v0 = getch(fileno(archivo_entrada));
	//printf("%c\n", v0);

	putch(fileno(archivo_salida) ,'a');

	fclose(archivo_entrada);
	fclose(archivo_salida);
	return 0;
}
