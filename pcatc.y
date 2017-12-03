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
#define WORK(name, p, ...) p = new_node(name); insert(p, ##__VA_ARGS__)

%}

%token-table

%union {
	struct ast_node *val;
}

%token ARRAY BEGINN BY DO ELSE ELSIF END FOR IF IN IS LOOP OF OUT PROCEDURE PROGRAM RECORD THEN TO TYPE VAR WHILE
%token <val> INTEGER REAL
%token <val> ID STRING
%token <val> EXIT RETURN
%token <val> READ WRITE

/* binary-op */
%left <val> '>' '<' '=' ">=" "<=" "<>"
%left <val> '+' '-' OR
%left <val> '*' '/' DIV MOD AND
%precedence <val> UNARY NOT

%left "OF"

%type <val> program
%type <val> body
%type <val> statement statement_seq
%type <val> write_params write_expr write_expr_comma_seq
%type <val> expression
%type <val> l_value l_value_comma_seq
%type <val> actual_params expression_comma_seq
%type <val> comp_values comp_value comp_value_semicolon_seq
%type <val> array_values array_value array_value_comma_seq
%type <val> number
%type <val> unary_op
%type <val> binary_op1 binary_op2 binary_op3

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
BEGINN statement_seq END {
	$$ = new_node("body");
	insert($$, $2);
}
;

statement:
  l_value ":=" expression ';'		{ WORK("statement", $$, $1, $3); }
| ID actual_params ';'			{ WORK("statement", $$, $1, $2); }
| READ '(' l_value l_value_comma_seq ')' ';'	{ WORK("statement", $$, $1, $3, $4); }
| WRITE write_params ';'		{ WORK("statement", $$, $1, $2); }
| EXIT ';'				{ WORK("statement", $$, $1); }
| RETURN ';'				{ WORK("statement", $$, $1); }
| RETURN expression ';'			{ WORK("statement", $$, $1, $2); }
;

statement_seq:				{ $$ = NULL; }
| statement statement_seq		{ append($1, $2); }
;

write_params: /* TODO(cjr) do not build extra node */
  '(' write_expr write_expr_comma_seq ')'	{ WORK("write-params", $$, $2, $3); }
| '(' ')'	{ struct ast_node *p = new_node("()"); WORK("write-params", $$, p); }
;

write_expr:
  STRING				{ WORK("write-expr", $$, $1); }
| expression				{ WORK("write-expr", $$, $1); }
;

write_expr_comma_seq:			{ $$ = NULL; }
| ',' write_expr write_expr_comma_seq	{ append($2, $3); $$ = $2; }

expression:
  number		{ WORK("expression", $$, $1); }
| l_value		{ WORK("expression", $$, $1); }
| '(' expression ')'	{ WORK("expression", $$, $2); } /* put away the '()' */
| unary_op expression %prec UNARY { WORK("expression", $$, $1, $2); }
/* expand binary_op */
| expression binary_op1 expression %prec '>' { WORK("expression", $$, $1, $2, $3); }
| expression binary_op2 expression %prec '+' { WORK("expression", $$, $1, $2, $3); }
| expression binary_op3 expression %prec '*' { WORK("expression", $$, $1, $2, $3); }
| ID actual_params	{ WORK("expression", $$, $1, $2); }
| ID comp_values	{ WORK("expression", $$, $1, $2); }
| ID array_values	{ WORK("expression", $$, $1, $2); }
;

l_value:
  ID			{ WORK("l-value", $$, $1); }
| l_value '.' ID	{ WORK("l-value", $$, $1, $3); }
| l_value '[' expression ']' { WORK("l-value", $$, $1, $3); }
;

l_value_comma_seq:			{ $$ = NULL; }
| ',' l_value l_value_comma_seq		{ append($2, $3); $$ = $2; }

actual_params: /* done */
'(' expression expression_comma_seq ')' { WORK("actual-prarms", $$, $2, $3); }
| '(' ')'	{ struct ast_node *p = new_node("()"); WORK("actual-params", $$, p); }
;

expression_comma_seq: /* done */	{ $$ = NULL; }
| ',' expression expression_comma_seq	{ append($2, $3); $$ = $2; }
;

comp_values:
'{' comp_value comp_value_semicolon_seq '}'	{ WORK("comp-values", $$, $2, $3); }
;

comp_value_semicolon_seq:			{ $$ = NULL; }
| ';' comp_value comp_value_semicolon_seq	{ append($2, $3); $$ = $2; }
;

comp_value:
ID ":=" expression				{ WORK("comp-value", $$, $1, $3); }
;

array_values:
"[<" array_value array_value_comma_seq ">]"	{ WORK("array-values", $$, $2, $3); }
;

array_value_comma_seq:				{ $$ = NULL; }
| ',' array_value array_value_comma_seq		{ append($2, $3); $$ = $2; }
;

array_value:
expression			{ WORK("array-value", $$, $1); }
| expression "OF" expression	{ WORK("array-value", $$, $1, $3); }
;


number: /* done */
INTEGER	{ WORK("number", $$, $1); }
| REAL	{ WORK("number", $$, $1); }
;

unary_op: /* done */
  '+' %prec UNARY { WORK("unary-op", $$, $1); }
| '-' %prec UNARY { WORK("unary-op", $$, $1); }
| NOT		{ WORK("unary-op", $$, $1); }
;

/* binary_op done */
binary_op1:
  '>'	{ WORK("binary-op", $$, $1); }
| '<'	{ WORK("binary-op", $$, $1); }
| '='	{ WORK("binary-op", $$, $1); }
| ">="	{ WORK("binary-op", $$, $1); }
| "<="	{ WORK("binary-op", $$, $1); }
| "<>"	{ WORK("binary-op", $$, $1); }
;
binary_op2: 
  '+'	{ WORK("binary-op", $$, $1); }
| '-'	{ WORK("binary-op", $$, $1); }
| OR	{ WORK("binary-op", $$, $1); }
;
binary_op3:
  '*'	{ WORK("binary-op", $$, $1); }
| '/'	{ WORK("binary-op", $$, $1); }
| DIV	{ WORK("binary-op", $$, $1); }
| MOD	{ WORK("binary-op", $$, $1); }
| AND	{ WORK("binary-op", $$, $1); }
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
