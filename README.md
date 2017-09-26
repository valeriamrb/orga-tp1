# orga-tp1


Compilar con: gcc -Wall -g -o tp1 main.c mymalloc.S myrealloc.S esCaracterValido.S esCapicua.S flush.S getch.S putch.S putchProcesamiento.S descargarPalabra.S palindrome.S
Ejecutar con: ./tp1

Prueba que falla (-ne es para no dejar salto de linea al final aunque en este test no es necesario):

entrada: echo -ne 'asd ddd as@atata@ddd' > entrada
salida: ddd

FALTA PASAR TEST :
esperada03
toma apostrofe invertido y apostrofes como caracteres validos
