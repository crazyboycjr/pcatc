#include <stdio.h>
#include <stdlib.h>

int yylex();
extern FILE *yyin;

int main(int argc, char *argv[]) {
	if (argc > 1) {
		yyin = fopen(argv[1], "r");
		if (!yyin) {
			fprintf(stderr, "cannot open file\n");
			return -1;
		}
	}

	yylex();
	return 0;
}
