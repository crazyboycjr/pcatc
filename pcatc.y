%{
#include <stdio.h>
#include <string.h>

#include "ast.h"

extern int yylex();
extern int yyparse();
extern char filename[];

extern void yyerror(const char *);
/* YYPRINT is defined for use yytoknum[] */
#define YYPRINT

/* some macros for compress code */
#define WORK(name, p, ...) p = new_node(name); insert(p, ##__VA_ARGS__)

%}

%define parse.error verbose
%locations
%token-table

%union {
	struct ast_node *val;
}

%token <val> ARRAY BEGINN BY DO END FOR IN IS LOOP OUT PROCEDURE PROGRAM RECORD TO TYPE VAR WHILE
%token <val> INTEGER REAL
%token <val> ID STRING
%token <val> EXIT RETURN
%token <val> READ WRITE

/* binary-op */
%left <val> '>' '<' '=' ">=" "<=" "<>"
%left <val> '+' '-' OR
%left <val> '*' '/' DIV MOD AND
%precedence <val> UNARY NOT

//%right IF THEN ELSE ELSIF

%precedence <val> IF
%precedence <val> THEN
%precedence <val> ELSIF
%precedence <val> ELSE

%left <val> OF "OF"

%type <val> program
%type <val> body
%type <val> declaration declaration_seq
%type <val> var_decl var_decl_seq id_comma_seq
%type <val> type_decl type_decl_seq
%type <val> procedure_decl procedure_decl_seq
%type <val> type
%type <val> component component_seq
%type <val> formal_params
%type <val> fp_section fp_section_semicolon_seq
%type <val> statement statement_seq
%type <val> write_params write_expr write_expr_comma_seq
%type <val> if_statement elsif_statement elsif_statement_seq
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
	WORK("program", $$, $3);
	ast_print_structure($$, 0);
}
;

body:
declaration_seq BEGINN statement_seq END	{ WORK("body", $$, $1, $2, $3); }
;

declaration: /* done */
  VAR var_decl_seq			{ WORK("var declaration", $$, $1, $2); }
| TYPE type_decl_seq			{ WORK("type declaration", $$, $1, $2); }
| PROCEDURE procedure_decl_seq		{ WORK("procedure declaration", $$, $1, $2); }
;

declaration_seq:			{ $$ = NULL; }
| declaration declaration_seq		{ append($1, $2); $$ = $1; }
;

var_decl:
  ID id_comma_seq ":=" expression ';'	{ WORK("var-decl", $$, $1, $2, $4); }
| ID id_comma_seq ':' type ":=" expression ';' { WORK("var-decl", $$, $1, $2, $4, $6); }
;

var_decl_seq:				{ $$ = NULL; }
| var_decl var_decl_seq			{ append($1, $2); $$ = $1; }
;

id_comma_seq:				{ $$ = NULL; }
| ',' ID id_comma_seq			{ append($2, $3); $$ = $2; }
;

type_decl:
ID IS type ';'				{ WORK("type-decl", $$, $1, $3); }
;

type_decl_seq:				{ $$ = NULL; }
| type_decl type_decl_seq		{ append($1, $2); $$ = $1; }
;

procedure_decl:
  ID formal_params IS body ';'		{ WORK("procedure-decl", $$, $1, $2, $4); }
| ID formal_params ':' type IS body ';'	{ WORK("procedure-decl", $$, $1, $2, $4, $6); }
;

procedure_decl_seq:			{ $$ = NULL; }
| procedure_decl procedure_decl_seq	{ append($1, $2); $$ = $1; }
;

type:
  ID					{ WORK("type", $$, $1); }
| ARRAY OF type				{ WORK("array type", $$, $3); }
| RECORD component component_seq END	{ WORK("record type", $$, $1, $2, $3); }
;

component:
ID ':' type ';'				{ WORK("component", $$, $1, $3); }
;

component_seq:				{ $$ = NULL; }
| component component_seq		{ append($1, $2); $$ = $1; }
;

formal_params:
  '(' fp_section fp_section_semicolon_seq ')'	{ WORK("formal_params", $$, $2, $3); }
| '(' ')'	{ struct ast_node *p = new_node("()"); WORK("formal-params", $$, p); }
;

fp_section:
ID id_comma_seq ':' type		{ WORK("fp-section", $$, $1, $2, $4); }
;

fp_section_semicolon_seq:		{ $$ = NULL; }
| ';' fp_section fp_section_semicolon_seq	{ append($2, $3); $$ = $2; }
;


statement: /* done */
  l_value ":=" expression ';'		{ WORK("assignment statement", $$, $1, $3); }
| ID actual_params ';'			{ WORK("procedure call statement", $$, $1, $2); }
| READ '(' l_value l_value_comma_seq ')' ';'	{ WORK("read statement", $$, $1, $3, $4); }
| WRITE write_params ';'		{ WORK("write statement", $$, $1, $2); }
| if_statement
| WHILE expression DO statement_seq END ';'	{ WORK("while statement", $$, $1, $2, $3, $4); }
| LOOP statement_seq END ';'		{ WORK("loop statement", $$, $1, $2); }
| FOR ID ":=" expression TO expression
  DO statement_seq END ';'		{ WORK("for statement", $$, $2, $4, $5, $6, $7, $8); }
| FOR ID ":=" expression TO expression
  BY expression DO statement_seq END ';'{ WORK("for statement", $$, $2, $4, $5, $6, $7, $8, $9, $10); }
| EXIT ';'				{ WORK("exit statement", $$, $1); }
| RETURN ';'				{ WORK("return etatement", $$, $1); }
| RETURN expression ';'			{ WORK("return statement", $$, $1, $2); }
;

statement_seq:				{ $$ = NULL; }
| statement statement_seq		{ append($1, $2); $$ = $1; }
;

/* if-then-else-statement */
if_statement:
  IF expression THEN statement_seq
  elsif_statement_seq END ';'		{ WORK("if-then statement", $$, $1, $2, $3, $4, $5); }
| IF expression THEN statement_seq
  elsif_statement_seq
  ELSE statement_seq END ';'		{ WORK("if-then-else statement", $$, $1, $2, $3, $4, $5, $6, $7); }

elsif_statement:
ELSIF expression THEN statement_seq	{ WORK("elsif-statement", $$, $2, $4); }

elsif_statement_seq:			{ $$ = NULL; }
| elsif_statement elsif_statement_seq	{ append($1, $2); $$ = $1; }

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
  number		{ WORK("simple expression", $$, $1); }
| l_value		{ WORK("simple expression", $$, $1); }
| '(' expression ')'	{ WORK("simple expression", $$, $2); } /* put away the '()' */
| unary_op expression %prec UNARY { WORK("unary-op expression", $$, $1, $2); }
/* expand binary_op */
| expression binary_op1 expression %prec '>' { WORK("binary-op expression", $$, $1, $2, $3); }
| expression binary_op2 expression %prec '+' { WORK("binary-op expression", $$, $1, $2, $3); }
| expression binary_op3 expression %prec '*' { WORK("binary-op expression", $$, $1, $2, $3); }
| ID actual_params	{ WORK("procedure call expression", $$, $1, $2); }
| ID comp_values	{ WORK("record construction expression", $$, $1, $2); }
| ID array_values	{ WORK("array construction expression", $$, $1, $2); }
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
| expression OF expression	{ WORK("array-value", $$, $1, $3); }
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

void yyerror(const char *msg) {
	fprintf(stderr, "\033[1;29m%s:%d:%d:\033[0m \033[1;31merror:\033[0m %s\n",
			filename, yylloc.first_line, yylloc.first_column, msg);
}
