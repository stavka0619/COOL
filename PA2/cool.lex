/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

void comment();
void scan_str();
%}

/*
 * Define names for regular expressions here.
 */

DARROW          =>
delim [ \t\n\f\r\v]
Digit			[0-9]
Letter			[a-zA-Z_]
Char			[a-fA-F0-9_]   
ws {delim}+
id {letter}({letter}|{digit})*

%%

 /*
  *  Nested comments
  */
\-\-(.)*\n  {}

"(*" {  comment(); }

"*)" {  cool_yylval.symbol= inttable.add_string("Unmatched *)");
      return (ERROR); }

 /*
  *  The multiple-character operators
  */
{DARROW}		{ return (DARROW); }
{ws} {}

 

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
[Cc][Lc][Aa][Ss][Ss]  { return (CLASS); }
[Ee][Ll][Ss][Ee]  { return (ELSE); }
[Ff][Ii] { return (FI); }
[Ii][Ff] { return (IF); }
[Ii][Nn] { return (IN); }
[Ii][Nn][Hh][Ee][Rr][Ii][Tt][Ss] { return (INHERITS); }
[Ll][Ee][Tt]  { return (LET); }
[Ll][Oo][Oo][Pp] { return (LOOP); }
[Po][Oo][Oo][Lp] { return (POOL); }
[Tt][Hh][Ee][Nn] { return (THEN); }
[Ww][Hh][Ii][Ll][Ee] { return (WHILE); }
[Cc][Aa][Ss][Ee] { return (CASE); }
[Ee][Ss][Aa][Cc] { return (ESAC); }
[Oo][Ff] { return (OF); }
[Nn][Ee][Ww] { return (NEW); }
[Ii][Ss][Vv][Oo][Ii][Dd] { return (ISVOID); }
[Nn][Oo][Tt] { return (NOT); }
f[Aa][Ll][Ss][Ee] { cool_yylval.boolean = 1;
                    return (BOOL_CONST); }
t[Rr][Uu][Ee] { cool_yylval.boolean = 0;
                    return (BOOL_CONST); }


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
\"(\\.|[^\\"])*\"  {
  scan_str();   
  cool_yylval.symbol= inttable.add_string(yytext);
                    return (STR_CONST);  }

 /*
  *  Interger, Identifiers and Special Notation
  */

[0-9]+  {  cool_yylval.symbol= inttable.add_string(yytext);
   return (INT_CONST); 
}

[A-Z][a-zA-Z]* {
   cool_yylval.symbol= inttable.add_string(yytext);
   return (TYPEID); 
}  

[a-zA-Z0-9]+ {
   cool_yylval.symbol= inttable.add_string(yytext);
   return (OBJECTID); 
}

%%

void comment() {
  char c, c1;
  int next_end = 0;
  int next_nested = 0;
  while (1) 
  {
    c = input();
    putchar(c);
    if (c == '*')
    {
      c1 = input();
      if (c1==')')
        break;  //matched *) found
      else
        unput(c1);
    }
    else if (c == '(')
    {
      c1 = input();
      if (c1=='*')
        comment();  //nested comment
      else
        unput(c1);
    }
  }
}

void scan_str() {
  int i = 0;
  int cur = 0;
  for (i=0; yytext[i] != '\"'; i++) {
    if  (yytext[i] = '\0')
    {
      cool_yylval.symbol= inttable.add_string("String contains null chracter");
      return (ERROR);
    }
    if  (yytext[i] = '\n')
    {
      cool_yylval.symbol= inttable.add_string("Unterminated string constant");
      return (ERROR);
    }
    if (cur>=MAX_STR_CONST)
    {
      cool_yylval.symbol= inttable.add_string("String constant too long");
      return (ERROR);
    }
    if (yytext[i]='\\')
    {
      if (yytext[i+1]=='b')
        yytext[cur] = '\b';
      else if (yytext[i+1]=='t')
        yytext[cur] = '\t';
      else if (yytext[i+1]=='n')
        yytext[cur] = '\n';
      else if (yytext[i+1]=='f')
        yytext[cur] = '\f';
      else
        yytext[cur] = yytext[i+1];
      cur++;
      i = i+1;
    }
    else
    {
      yytext[cur] = yytext[i];
      cur++;
    }
  }
}
