#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex();
extern FILE *yyin;
char filename[256] = "stdin";

int main(int argc, char *argv[]) {
	if (argc > 1) {
		yyin = fopen(argv[1], "r");
		if (!yyin) {
			fprintf(stderr, "cannot open file\n");
			return -1;
		}
		strncpy(filename, argv[1], sizeof filename);
	}

	while (yylex() > 0) {}
	return 0;
}
