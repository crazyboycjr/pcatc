%{
#include <stdio.h>
extern FILE *yyout;
extern int yylineno;
int curcolumn = 1, lastline = 0;
int lineno = 1, column = 1;
void report(const char *type, char *text) {
	fprintf(yyout, "At (%d, %d) Found %s: %s\n", lineno, column, type, text);
}
#define YY_USER_ACTION \
	do { \
		/* no multiple line keyword */ \
		if (lineno == lastline) { \
			column = curcolumn; \
			curcolumn += yyleng; \
		} else { \
			lastline = lineno; \
			column = 1; \
			curcolumn = yyleng + 1; \
		} \
	} while (0);
%}

%x comment
LETTER	[a-zA-Z]
DIGIT	[0-9]
WS		[ \t]+
INTEGER	{DIGIT}+
REAL	{DIGIT}+"."{DIGIT}*
STRING	\"[^\"]*\"

%%
"(*" {
	BEGIN(comment);
}
<comment>[^*\n]* {
	;
}
<comment>"*"+[^*)\n]* {
	;
}
<comment>\n {
	lineno++;
}
<comment>"*)" {
	BEGIN(INITIAL);
}
{WS} {
	;
}
\n {
	lineno++;
}
AND|ARRAY|BEGIN|BY|DIV|DO|ELSE|ELSIF|END|EXIT|FOR|IF|IN|IS|LOOP|MOD|NOT|OF|OR|OUT|PROCEDURE|PROGRAM|READ|RECORD|RETURN|THEN|TO|TYPE|VAR|WHILE|WRITE {
	report("reserved keyword", yytext);
}
":="|"+"|"-"|"*"|"/"|"<"|"<="|">"|">="|"="|"<>" {
	report("operator", yytext);
}
":"|";"|","|"."|"("|")"|"["|"]"|"{"|"}"|"[<"|">]"|"\\" {
	report("delimiter", yytext);
}
{INTEGER} {
	report("integer", yytext);
}
{REAL} {
	report("real", yytext);
}
{STRING} {
	// STRING characters should be isprint
	report("string", yytext);
}
{LETTER}({LETTER}|{DIGIT})* {
	// ID length should <= 255
	report("identifier", yytext);
}
. {
	// report unrecognized characters
	;
}
%%
