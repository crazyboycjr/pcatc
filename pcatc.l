%{
#include <stdio.h>
extern FILE *yyout;
void report(const char *type, char *text) {
	fprintf(yyout, "Found %s: %s\n", type, text);
}
%}

%x comment
LETTER	[a-zA-Z]
DIGIT	[0-9]
WS		[ \t\n]+
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
<comment>"*)" {
	BEGIN(INITIAL);
}
{WS} {
	;
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
	report("string", yytext);
}
{LETTER}({LETTER}|{DIGIT}){0,254} {
	report("identifier", yytext);
}
. {
	;
}
%%
