

%x comment
%{
#include <stdio.h>
#include <stdlib.h>
#include "symbols.h"
#include "y.tab.h"
#define LIST strcat(buf,yytext)
#define token(t) {LIST; printf("<'%s'>\n",yytext);yylval.string_value = strdup(yytext); return t;}
#define tokenInteger(t,i) {LIST; printf("<%s:%s>\n",t,i);yylval.int_value = atoi(yytext); return TOKINT;}
#define tokenString(t,s) {LIST; printf("<%s:%s>\n",t,s); yylval.string_value = strdup(s); return TOKSTRING;}


int lnn=0;
char buf[255];
%}

mlcb    \/\*
slc      \/\/.*$
ws      [ \t]+
alpha   [A-Za-z]
dig     [0-9]
id      {alpha}+({dig}|{alpha})*
iid     {dig}+{id}
op      \+|\-|\*|\/|\%|\^|\<|\>|\=
deli    \,|\:|\(|\)|\[|\]|\{|\}|\;
integer [\-]?{dig}+
exp     [Ee][\+\-]?{dig}+
real    {integer}|{integer}\.{dig}+
number  {real}|{integer}|{real}{exp}
string \"[^\n\"]+\"
%%


{slc} ;   LIST; //strip single line comment
{mlcb}    { 
    BEGIN(comment);
    LIST;
}
<comment>[^*\n]*  LIST;
<comment>"*"+[^*/\n]* LIST;
<comment>\n       {
    lnn++;
    if(strlen(buf)>0)
      printf("%d: %s\n\r\n\r",lnn,buf);
    buf[0]='\0';
}
<comment>"*"+"/"  {
  LIST;
  BEGIN(INITIAL);
}

{ws}      LIST;
\n        {
    lnn++;
    if(strlen(buf)>0)
    printf("%d: %s\n\r\n\r",lnn,buf);
    buf[0]='\0';
}
{string}  tokenString("string",yytext);
{op}      token(yytext[0]);


\~\=      token(NE);
\=\=      token(EQ);
\>\=      token(GE);
\<\=      token(LE);
and       token(AND);
or        token(OR);
not       token(NOT);

{deli}    token(yytext[0]);

boolean   token(BOOLEAN);
const     token(CONST);
do        token(DO); 
else      token(ELSE);
end       token(END);
false     token(FALSE);
for       token(FOR);
function  token(FUNCTION);
if        token(IF); 
import    token(IMPORT);
in        token(IN);
integer   token(INTEGER);
local     token(LOCAL);
nil       token(NIL);
print     token(PRINT);
println   token(PRINTLN);
real      token(REAL);
repeat    token(REPEAT); 
return    token(RETURN);
string    token(STRING);
then      token(THEN);
true      token(TRUE);
while     token(WHILE);
until     token(UNTIL); 

{iid}     {
    printf("invalid identifier %s\n",yytext);
    exit(1);
}

{id}      {
    token(IDENTIFIER);
} 
{number}  tokenInteger("integer",yytext);

%%



int yywrap(void){
  return 1;
}

