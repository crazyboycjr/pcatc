%{
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <errno.h>

extern FILE *yyout;
extern int yylineno;
extern char filename[];
int curcolumn = 1, lastline = 0;
int lineno = 1, column = 1;

void report(const char *type, char *text) {
	fprintf(yyout, "At (%d, %d) Found %s: %s\n", lineno, column, type, text);
}

void report_error(int lineno, int column, const char *msg) {
	fprintf(stderr, "\033[1;29m%s:%d:%d:\033[0m \033[1;31merror:\033[0m %s\n",
			filename, lineno, column, msg);
	//exit(0);
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
%x str
LETTER	[a-zA-Z]
DIGIT	[0-9]
WS		[ \t]+
INTEGER	{DIGIT}+
REAL	{DIGIT}+"."{DIGIT}*

%%
	char string_buf[256];
	char *string_buf_ptr;
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
<comment><<EOF>> {
	report_error(lineno, column, "unterminated comment");
	exit(1);
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
	// should in range [0, 2^31-1]
	long val;
	errno = 0;
	val = strtol(yytext, NULL, 10);
	if (errno == ERANGE || val < 0 || val > 0x7fffffff)
		report_error(lineno, column, "integer out of range");
	report("integer", yytext);
}
{REAL} {
	report("real", yytext);
}


\" {
	string_buf_ptr = string_buf;
	BEGIN(str);
}
<str>\" {
	BEGIN(INITIAL);
	*string_buf_ptr = '\0';
	int length = string_buf_ptr - string_buf;
	// STRING should be limited to 255 characters in length
	if (length > 255)
		report_error(lineno, column, "invalid string, length exceed 255");

	// STRING characters should be isprint,
	for (char *c = string_buf; *c != '\0'; c++)
		if (!(isascii(*c) && isprint(*c)))
			report_error(lineno, column, "invalid string, contains non printable ASCII characters");

	report("string", string_buf);
}
<str>\n {
	// error - unterminated string
	report_error(lineno, column, "unterminated string");

	// Let's continue to parse the token
	lineno++;
	BEGIN(INITIAL);
}
<str><<EOF>> {
	report_error(lineno, column, "unterminated string");
	exit(1);
}
<str>[^\\\n"]+ {
	// not backslash, not enter, not double quote
	char *yptr = yytext;

	while (*yptr)
		*string_buf_ptr++ = *yptr++;
}

{LETTER}({LETTER}|{DIGIT})* {
	// ID length should <= 255
	if (yyleng > 255)
		report_error(lineno, column, "identifier length too long");

	report("identifier", yytext);
}
. {
	// report unrecognized characters
	report_error(lineno, column, "unrecognized characters");
	;
}
%%
