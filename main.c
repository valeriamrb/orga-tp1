 #include <stdio.h>
 #include <stdlib.h>
 #include <string.h>
 #include <ctype.h>

 #include <unistd.h>
 #include <getopt.h>


#define VERSION "0.9.0"

int palindrome(int ifd, int ibytes, int ofd, int obytes);

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
	printf("\t-I --ibuf-bytes\tByte-count of the input buffer.\n");
	printf("\t-O --obuf-bytes\tByte-count of the output buffer.\n");
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
	fprintf(stderr, "Los parametros son incorrectos!\n");
	mostrar_usage();
	exit(EXIT_FAILURE);
}

void print_usage() {
	printf("Usage: rectangle [ap] -l num -b num\n");
}

int isnumber(char* str) {
	int i;
	if (strlen(str) == 0)
		return 0;
	for (i = 0; i < strlen(str); i++)
        	if (!isdigit((int)str[i]))
	        	return 0;
	return 1;
}

int main(int argc, char *argv[]) {
	int opt= 0;

	int version = 0;
	int help = 0;
	char* input = NULL;
	char* output = NULL;
	int ibuff = 0;
	int obuff = 0;
	FILE* input_handler = NULL;
	FILE* output_handler = NULL;

	int proceso_ok = 0;

	static struct option long_options[] = {
		{"version",	no_argument,		0,	'v' },
		{"help",	no_argument,		0,	'h' },
		{"input",	required_argument,	0,	'i' },
		{"output", 	required_argument,	0,	'o' },
		{"ibuf-bytes",	required_argument,	0,	'I' },
		{"obuf-bytes",	required_argument,	0,	'O' },
		{0,		0,                 	0,	 0  }
	};

	int long_index =0;
	while ((opt = getopt_long(argc, argv, "vhi:o:I:O:",
	long_options, &long_index )) != -1) {
		switch (opt) {
			case 'v' : version = 1;
			break;
			case 'h' : help = 1;
			break;
			case 'i' : input = optarg;
			break;
			case 'o' : output = optarg;
			break;
			case 'I' : if (isnumber(optarg) && atoi(optarg) > 0)
			 		ibuff = atoi(optarg);
				   else
				   	error_parametros_incorrectos();
			break;
			case 'O' : if (isnumber(optarg) && atoi(optarg) > 0)
			 		obuff = atoi(optarg);
				   else
				   	error_parametros_incorrectos();
			break;
			default: error_parametros_incorrectos();
		}
	}

	// Si alguna de las opciones elegidas es -h entonces
	// solo se muestra el usage y se finaliza el programa.
	if (help) {
		mostrar_usage();
		return 0;
	}

	// Si alguna de las opciones elegidas es -v entonces
	// solo se muestra la version y se finaliza el programa.
	if (version) {
		mostrar_version();
		return 0;
	}

	// Fijo el origen de datos del programa (input_handler)
	if (!input || (input && strcmp(input, "-")) == 0)
		input_handler = stdin;
	else {
		input_handler = fopen(input, "r");
		if (!input_handler) {
			fprintf(stderr, "Error en apertura de entrada.\n");
			exit(EXIT_FAILURE);
		}
	}

	// Fijo el destino de datos del programa (output_handler)
	if (!output || (output && strcmp(output, "-")) == 0)
		output_handler = stdout;
	else {
		output_handler = fopen(output, "w");
		if (!input_handler) {
			fprintf(stderr, "Error en apertura de salida.\n");
			if (input_handler && input_handler != stdin)
				fclose(input_handler);
			exit(EXIT_FAILURE);
		}
	}

	// Si no se especifica el tamanio del buffer de entrada este
	// es 1 por defecto
	if (!ibuff)
		ibuff = 1;

	// Si no se especifica el tamanio del buffer de salida este
	// es 1 por defecto
	if (!obuff)
		obuff = 1;

	proceso_ok = palindrome(fileno(input_handler), ibuff, fileno(output_handler), obuff);

	if (!proceso_ok)
		fprintf(stderr, "Hubo un error en el procesamiento\n");

	//Cierro los archivos que no sean entrada o salida estandar
	if (input_handler && input_handler != stdin)
		fclose(input_handler);

	if (output_handler && output_handler != stdout)
		fclose(output_handler);

	return 0;
}
