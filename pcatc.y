%{
#include <stdio.h>
#include <string.h>

#include "ast.h"

extern int yylex();
extern int yyparse();
void yyerror(const char *msg) {
	fprintf(stderr, "%s\n", msg);
}

#define YYPRINT

%}

%token-table

%union {
	struct ast_node *val;
}

%token ARRAY BEGINN BY DO ELSE ELSIF END EXIT FOR IF IN IS LOOP NOT OF OUT PROCEDURE PROGRAM READ RECORD RETURN THEN TO TYPE VAR WHILE WRITE
%token <val> INTEGER REAL

/* binary-op */
%token <val> ADD '+'
%token <val> SUB '-'
%token <val> MUL '*'
%token <val> DIV2 '/'
%token <val> DIV
%token <val> MOD
%token <val> OR
%token <val> AND
%token <val> GT '>'
%token <val> LT '<'
%token <val> EQ '='
%token <val> GE ">="
%token <val> LE "<="
%token <val> NE "<>"

%type <val> program
%type <val> body
%type <val> expression
%type <val> number
%type <val> binary_op

%%
program:
PROGRAM IS body ';' {
	printf("happy\n");
	fflush(stdout);
	$$ = new_node("program");
	insert($$, $3);
	ast_print_structure($$, 0);
}
;
body:
BEGINN expression END {
	$$ = new_node("body");
	insert($$, $2);
}
;
expression:
number binary_op number {
	$$ = new_node("expression");
	insert($$, $1);
	insert($$, $2);
	insert($$, $3);
}
;
number:
INTEGER { $$ = new_node("number"); insert($$, $1); }
| REAL { $$ = new_node("number"); insert($$, $1); }
;

binary_op:
'+'	{ $$ = new_node("binary-op"); insert($$, $1); }
| '-'	{ $$ = new_node("binary-op"); insert($$, $1); }
| '*'	{ $$ = new_node("binary-op"); insert($$, $1); }
| '/'	{ $$ = new_node("binary-op"); insert($$, $1); }
| DIV	{ $$ = new_node("binary-op"); insert($$, $1); }
| MOD	{ $$ = new_node("binary-op"); insert($$, $1); }
| OR	{ $$ = new_node("binary-op"); insert($$, $1); }
| AND	{ $$ = new_node("binary-op"); insert($$, $1); }
| '>'	{ $$ = new_node("binary-op"); insert($$, $1); }
| '<'	{ $$ = new_node("binary-op"); insert($$, $1); }
| '='	{ $$ = new_node("binary-op"); insert($$, $1); }
| ">="	{ $$ = new_node("binary-op"); insert($$, $1); }
| "<="	{ $$ = new_node("binary-op"); insert($$, $1); }
| "<>"	{ $$ = new_node("binary-op"); insert($$, $1); }
;
%%

int get_token_code(char *token, int isstr)
{
#define NR_TOKEN (sizeof(yytname) / sizeof(yytname[0]))

	int len = strlen(token);
	for (int i = 0; i < NR_TOKEN; i++) {

		if (!isstr && strcmp(token, yytname[i]) == 0)
			return yytoknum[i];

		if (isstr && yytname[i][0] == '"' &&
			strncmp(token, yytname[i] + 1, len) == 0 &&
			yytname[i][len + 1] == '"' && 
			yytname[i][len + 2] == '\0') {

			return yytoknum[i];
		}
	}

#undef NR_TOKEN
	return 2;
}
