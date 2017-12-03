%{
#include <stdio.h>
#include <string.h>

#include "ast.h"

extern int yylex();
extern int yyparse();
void yyerror(const char *msg) {
	fprintf(stderr, "%s\n", msg);
}

/* YYPRINT is defined for use yytoknum[] */
#define YYPRINT

/* some macros for compress code */
#define WORK(name, p, ...) p = new_node(name); insert(p, __VA_ARGS__)

%}

%token-table

%union {
	struct ast_node *val;
}

%token ARRAY BEGINN BY DO ELSE ELSIF END EXIT FOR IF IN IS LOOP OF OUT PROCEDURE PROGRAM READ RECORD RETURN THEN TO TYPE VAR WHILE WRITE
%token <val> INTEGER REAL

/* binary-op */
%left <val> '+' '-' OR
%left <val> '*' '/' DIV MOD AND
%left <val> '>' '<' '=' ">=" "<=" "<>"
%precedence <val> UNARY NOT

%type <val> program
%type <val> body
%type <val> expression
%type <val> number
%type <val> unary_op
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
  number		{ WORK("expression", $$, $1); }
| '(' expression ')'	{ WORK("expression", $$, $2); } /* put away the '()' */
| unary_op expression	{ WORK("expression", $$, $1, $2); }
| expression binary_op expression { WORK("expression", $$, $1, $2, $3); }
;


number: /* done */
INTEGER	{ WORK("number", $$, $1); }
| REAL	{ WORK("number", $$, $1); }
;

unary_op:
  '+' %prec UNARY { WORK("unary-op", $$, $1); }
| '-' %prec UNARY { WORK("unary-op", $$, $1); }
| NOT		{ WORK("unary-op", $$, $1); }
;

binary_op: /* done */
  '+'	{ WORK("binary-op", $$, $1); }
| '-'	{ WORK("binary-op", $$, $1); }
| '*'	{ WORK("binary-op", $$, $1); }
| '/'	{ WORK("binary-op", $$, $1); }
| DIV	{ WORK("binary-op", $$, $1); }
| MOD	{ WORK("binary-op", $$, $1); }
| OR	{ WORK("binary-op", $$, $1); }
| AND	{ WORK("binary-op", $$, $1); }
| '>'	{ WORK("binary-op", $$, $1); }
| '<'	{ WORK("binary-op", $$, $1); }
| '='	{ WORK("binary-op", $$, $1); }
| ">="	{ WORK("binary-op", $$, $1); }
| "<="	{ WORK("binary-op", $$, $1); }
| "<>"	{ WORK("binary-op", $$, $1); }
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
