 #include <stdio.h>
 #include <stdlib.h>
 #include <string.h>
 #include <ctype.h>

#define VERSION "0.1.0beta"
typedef enum {
	STDIN_STDOUT,
	ARCHIVO_STDOUT,
	STDIN_ARCHIVO,
	ARCHIVO_ARCHIVO
} modo_entrada_salida;

// int getch(int ifd);
// int putch(int ofd, int caracter);
int palindrome(int ifd, int ibytes, int ofd, int obytes);
// int esCaracterValido(int c);

void mostrar_usage()
{
	printf("Usage:\n");
	printf("\ttp0 -h\n");
	printf("\ttp0 -V\n");
	printf("\ttp0 [options]\n");
	printf("\n");
	printf("Options:\n");
	printf("\t-v --version\tPrint version and quit.\n");
	printf("\t-h --help\tPrint this information.\n");
	printf("\t-i --input\tLocation of the input file.\n");
	printf("\t-o --output\tLocation of the output file.\n");
	printf("\t-I --ibuff-bytes\tByte-count of the input buffer.\n");
	printf("\t-O --ibuff-bytes\tByte-count of the output buffer.\n");
	printf("\n");
	printf("Examples:\n");
	printf("\ttp0 -i ~/input -o ~/output -I 4 -O 4\n");
}

void mostrar_version()
{
	printf("tp0 version: %s\n", VERSION);
}

int error_parametros_incorrectos()
{
	fprintf(stderr, "erro fatal: Los parametros son incorrectos!\n");
	mostrar_usage();
	exit(1);
}

int main(int argc, char **argv)
{
	size_t i;
	int version = 0;
	int help = 0;
	int input = 0;
	int output = 0;
	char* input_path;
	char* output_path;

	int ibuff = 0;
	int obuff = 0;
	char* ibuff_size;
	char* obuff_size;
	int ibuff_size_number;
	int obuff_size_number;

	int error_en_palindrome;

	FILE* input_handler = NULL;
	FILE* output_handler = NULL;
	modo_entrada_salida entrada_salida = 0;

	for (i = 1; i < argc; i++) {
		if (strcmp(argv[i], "-v") == 0 || strcmp(argv[i], "--version") == 0) {
			version++;
		} else if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0) {
			help++;
		} else if (strcmp(argv[i], "-i") == 0 || strcmp(argv[i], "--input") == 0) {
			input++;
			if (i + 1 <= argc - 1) {
				i++;
				input_path = argv[i];
			} else {
				error_parametros_incorrectos();
			}
		} else if (strcmp(argv[i], "-o") == 0 || strcmp(argv[i], "--output") == 0) {
			output++;
			if (i + 1 <= argc - 1) {
				i++;
				output_path = argv[i];
			} else {
				error_parametros_incorrectos();
			}
		} else if (strcmp(argv[i], "-I") == 0 || strcmp(argv[i], "--ibuf-bytes") == 0) {
			ibuff++;
			if (i + 1 <= argc - 1) {
				i++;
				ibuff_size = argv[i];
			} else {
				error_parametros_incorrectos();
			}
		} else if (strcmp(argv[i], "-O") == 0 || strcmp(argv[i], "--obuf-bytes") == 0) {
			obuff++;
			if (i + 1 <= argc - 1) {
				i++;
				obuff_size = argv[i];
			} else {
				error_parametros_incorrectos();
			}
		}
		else {
			error_parametros_incorrectos();
		}
	}

	if (version > 1 || help > 1 || input > 1 || output > 1 || ibuff > 1 || obuff > 1) {
		error_parametros_incorrectos();
	}

	if (help == 1) {
		if (argc == 2) {
			mostrar_usage();
			exit(0);
		} else {
			error_parametros_incorrectos();
		}
	}

	if (version == 1) {
		if (argc == 2) {
			mostrar_version();
			exit(0);
		} else {
			error_parametros_incorrectos();
		}
	}

	if     ((input == 0 && output == 0) ||
		(input == 0 && output == 1 && strcmp(output_path, "-") == 0) ||
		(input == 1 && output == 0 && strcmp(input_path,  "-") == 0) ||
		(input == 1 && output == 1 && strcmp(input_path,  "-") == 0 &&
					      strcmp(output_path, "-") == 0))
			entrada_salida = STDIN_STDOUT;
	else
	if     ((input == 0 && output == 1 && strcmp(output_path, "-") != 0) ||
	 	(input == 1 && output == 1 && strcmp(input_path,  "-") == 0 &&
		 		              strcmp(output_path, "-") != 0))
			entrada_salida = STDIN_ARCHIVO;
	else
	if     ((input == 1 && output == 0 && strcmp(input_path,  "-") != 0) ||
	 	(input == 1 && output == 1 && strcmp(input_path,  "-") != 0 &&
					      strcmp(output_path, "-") == 0))
			entrada_salida = ARCHIVO_STDOUT;
	else
	if 	(input == 1 && output == 1 &&
		strcmp(input_path,  "-") != 0 &&
		strcmp(output_path,  "-") != 0)
		 	entrada_salida = ARCHIVO_ARCHIVO;
	else
		error_parametros_incorrectos();


	// Compruebo parametros de buffers

	if ((ibuff == 0) || strcmp(ibuff_size,  "") == 0)
		ibuff_size_number = 1;
	else {
		ibuff_size_number = atoi(ibuff_size);
		if (!ibuff_size_number)
			error_parametros_incorrectos();
	}


	if ((obuff == 0) || strcmp(obuff_size,  "") == 0)
		obuff_size_number = 1;
	else {
		obuff_size_number = atoi(obuff_size);
		if (!obuff_size_number)
			error_parametros_incorrectos();
	}

	switch (entrada_salida) {
		case STDIN_STDOUT:
			input_handler = stdin;
			output_handler = stdout;
			break;
		case ARCHIVO_STDOUT:
			input_handler = fopen(input_path, "r");
			output_handler = stdout;
			if (!input_handler) {
				fprintf(stderr, "Error en apertura de archivo");
				return 1;
			}
			break;
		case STDIN_ARCHIVO:
			input_handler = stdin;
			output_handler = fopen(output_path, "w");
			if (!output_handler) {
				fprintf(stderr, "Error en apertura de archivo");
				return 1;
			}
			break;
		case ARCHIVO_ARCHIVO:
			input_handler = fopen(input_path, "r");
			output_handler = fopen(output_path, "w");

			if (!input_handler || !output_handler) {
				if (input_handler) fclose(input_handler);
				if (output_handler) fclose(output_handler);
				fprintf(stderr, "Error en apertura de archivo");
				return 1;
			}
			break;
	}

	error_en_palindrome = palindrome(fileno(input_handler), ibuff_size_number, fileno(output_handler), obuff_size_number);

	if (!error_en_palindrome)
		fprintf(stderr, "Hubo un error en el procesamiento\n");

	switch (entrada_salida) {
		case STDIN_STDOUT:
			break;
		case ARCHIVO_STDOUT:
			fclose(input_handler);
			break;
		case STDIN_ARCHIVO:
			fclose(output_handler);
			break;
		case ARCHIVO_ARCHIVO:
			fclose(input_handler);
			fclose(output_handler);
			break;
	}

	return 0;
}
