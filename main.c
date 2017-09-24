/*
 * $Id: main.c,v 1.1 2008/04/22 03:11:50 hmasci Exp $
 *
 * 66.20 - Ejercicio A.8 (Patterson - Hennessy)
 */

#include <stdio.h>

int getch(int ifd);
int putch(int ofd, int caracter);
int palindrome(int ifd, int ibytes);

int main(void)
{
	// int n;
	// int v0;
	FILE* archivo_entrada;
	archivo_entrada = fopen("entrada","r");

	FILE* archivo_salida;
	archivo_salida = fopen("salida","w");

	palindrome(fileno(archivo_entrada), 16);

	// while ((v0 = getch(fileno(archivo_entrada))) != 256)
	// 	printf("%c\n", v0);
	//
	// if (v0 == 256) printf("FIN DE ARCHIVO\n");

	//putch(fileno(archivo_salida) ,'a');

	fclose(archivo_entrada);
	fclose(archivo_salida);
	return 0;
}
