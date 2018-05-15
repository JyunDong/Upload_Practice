%{
#define Trace(t)        printf(t)
#include <stdio.h>
#include "symbols.h"
#include "asm.h"
#include <stdlib.h>

%}

%union
{
    int int_value;
    char* string_value;
    int symboltype;
    FuncRec* fmeta;
}

/* tokens */
%token <int_value> TOKINT
%token <string_value> TOKSTRING
%token <string_value> IDENTIFIER 

%type <int_value> expr_list
%type <int_value> return_expr
%token INTEGER
%token STRING
%token BOOLEAN
%token REAL

%type <symboltype> type
%type <string_value> identifier
%type <int_value> integer_literal
%type <int_value> boolean_literal
%type <string_value> string_literal
%type <int_value> func_dclr
%type <fmeta> arg_list

%token CONST LOCAL
%token FUNCTION PRINT PRINTLN READ RETURN 
%token IF END WHILE FOR  DO ELSE THEN REPEAT UNTIL 
%token TRUE FALSE NIL 
%token IMPORT IN 

%left OR
%left AND
%nonassoc NOT
%nonassoc GE LE NE EQ '=' '>' '<'

%left '+' '-' 
%left '*' '/' '%'
%left '^'
%%

program:        block 
                ;

block:          block stmt
                |   
                ;


stmt:           assignment      
                |variable_dclr
                |loop           
                |func_dclr      //
                |func_invoke    //
                |condition  
                //|READ IDENTIFIER
                |PRINT {write("getstatic java.io.PrintStream java.lang.System.out\n");} expr 
                {write("invokevirtual void java.io.PrintStream.print(int)\n");}
                |PRINT string_literal {write("getstatic java.io.PrintStream java.lang.System.out\nldc %s\n",$2);}  
                {write("invokevirtual void java.io.PrintStream.print(java.lang.String)\n");}
                |PRINTLN string_literal {write("getstatic java.io.PrintStream java.lang.System.out\nldc %s\n",$2);}  
                {write("invokevirtual void java.io.PrintStream.println(java.lang.String)\n");}
                |PRINTLN {write("getstatic java.io.PrintStream java.lang.System.out\n");}  expr
                {write("invokevirtual void java.io.PrintStream.println(int)\n");}               
                |RETURN return_expr    {write($2 ?"ireturn\n" : "return\n");}
                |stmt ';'
                ;

expr:           identifier      
                {
                    if(lookup($1)!=-1)
                    if(LRESULT.s->sflag == fCONST)
                    {
                        write("sipush %d\n",(int)LRESULT.s->data);
                    }
                    else
                        if(LRESULT.t->scope>0) 
                        {                 
                            write("iload %d\n",LRESULT.s->varid);
                        }    
                        else 
                        {
                            write("getstatic %s %s.%s\n",type_map(LRESULT.s->stype),classname,$1);
                        }   
                   
                }
                |integer_expr   
                |boolean_expr
                |func_invoke
              //  |array_subscript
                |'(' expr ')'     

                ;

return_expr:    expr        {$$ = 1;}
                |           {$$ = 0;}
                ;

integer_expr:   integer_literal  {write("sipush %d\n",$1);}
                |expr '+' expr   {write("iadd\n");}
                |expr '-' expr   {write("isub\n");}
                |expr '*' expr   {write("imul\n");}
                |expr '/' expr   {write("idiv\n");}
                |expr '%' expr   {write("irem\n");}
                |'-' expr      %prec  '^'  {write("ineg\n");}
                ;

boolean_expr:   boolean_literal  {write("sipush %d\n",$1);}
                |expr GE expr    {write("isub\nifge L0%1$d\niconst_0\ngoto L1%1$d\nL0%1$d:\niconst_1\nL1%1$d:\n",++bl);}
                |expr LE expr    {write("isub\nifle L0%1$d\niconst_0\ngoto L1%1$d\nL0%1$d:\niconst_1\nL1%1$d:\n",++bl);}
                |expr NE expr    {write("isub\nifne L0%1$d\niconst_0\ngoto L1%1$d\nL0%1$d:\niconst_1\nL1%1$d:\n",++bl);}
                |expr EQ expr    {write("isub\nifeq L0%1$d\niconst_0\ngoto L1%1$d\nL0%1$d:\niconst_1\nL1%1$d:\n",++bl);}
                |expr '>' expr   {write("isub\nifgt L0%1$d\niconst_0\ngoto L1%1$d\nL0%1$d:\niconst_1\nL1%1$d:\n",++bl);}
                |expr '<' expr   {write("isub\niflt L0%1$d\niconst_0\ngoto L1%1$d\nL0%1$d:\niconst_1\nL1%1$d:\n",++bl);}
                |expr '^' expr   {write("ixor\n");}
                |NOT expr        {write("iconst_1\nixor\n");}
                |expr AND expr   {write("iand\n");}
                |expr OR expr    {write("ior\n");}
 
                ;

assignment:     identifier '=' expr         
                {
                    if(lookup($1)!=-1)
                    if(LRESULT.t->scope>0) 
                    {
                        if(LRESULT.s->sflag!=fCONST)
                        {
                            write("istore %d\n",LRESULT.s->varid);
                        }
                        else
                        {
                            printf("Line %d: error: cannot assign to variable %s with const-qualified type const\n",lnn,$1);
                            exit(1);
                        }                      
                    }    
                    else 
                    {
                        if(LRESULT.s->sflag!=fCONST)
                        {
                            write("putstatic %s %s.%s\n",type_map(LRESULT.s->stype),classname,$1);
                        }
                        else
                        {
                            printf("Line %d: error: cannot assign to variable %s with const-qualified type const\n",lnn,$1);
                            exit(1);
                        }    
                        
                    }    
                }                
                //|array_subscript '=' expr
                ;

//array_subscript:IDENTIFIER '[' integer_expr ']'

variable_dclr:  CONST type IDENTIFIER '=' boolean_literal   { insert($3,$2,fCONST,(void*)$5);}
                |CONST type IDENTIFIER '=' integer_literal  { insert($3,$2,fCONST,(void*)$5);}
                |CONST type IDENTIFIER '=' string_literal   { insert($3,$2,fCONST,(void*)$5);}
                |type IDENTIFIER '=' boolean_literal        { insert($2,$1,fVAR,(void*)$4);if(LRESULT.t->scope>0) write("sipush %d\nistore %d\n",$4,getid($2));}
                |type IDENTIFIER '=' integer_literal        { insert($2,$1,fVAR,(void*)$4);if(LRESULT.t->scope>0) write("sipush %d\nistore %d\n",$4,getid($2));}
                //|type IDENTIFIER '=' string_literal         { insert($2,$1,fVAR,(void*)0);}
                |type IDENTIFIER                            { insert($2,$1,fVAR,(void*)0);}
                //|type IDENTIFIER '[' integer_literal ']'    { insert($2,$1,fARRAY,(void*)0);}
                ;

func_dclr:      {scope_enter();focus(FUNC);}                 
                FUNCTION type IDENTIFIER  
                {write("method public static %s %s(",type_map($3),$4);} 
                '(' arg_list ')' 
                {write(")\nmax_stack 15\nmax_locals 15\n{\n")}
                block 
                END 
                { 
                    write("\n}\n")
                    scope_leave();
                    focus(MAIN);
                    insert($4,$3,fFUNC,(void*)$7);
                }
                ;
//variable declaration


//Literals
boolean_literal:TRUE        {$$ = 1;}
                |FALSE      {$$ = 0;}
                ; 
string_literal: TOKSTRING   {$$ = $1;}
                |NIL        {$$ = "";}
                ;
integer_literal:TOKINT      {$$ = $1;}
                ;

//types
type:           INTEGER             {$$=tINTEGER;}
                |REAL               {$$=tREAL;}
                |STRING             {$$=tSTRING;}
                |BOOLEAN            {$$=tBOOLEAN;}


//functions



func_invoke:    identifier '(' expr_list ')'  
                {
                    int i;
                    write("invokestatic %s %s.%s(",type_map(lookup($1)->stype),classname,$1);
                    FuncRec* fr = (FuncRec*)lookup($1)->data;
                    if($3>fr->paramCount)
                    {
                        printf("Line %d: error: too few arguments to function call, expected %d, have %d\n",lnn,fr->paramCount,$3);
                        exit(1);
                    }
                    else if($3<fr->paramCount)
                    {
                        printf("Line %d: error: too many arguments to function call, expected %d, have %d\n",lnn,fr->paramCount,$3);
                        exit(1);
                    }
                    else
                    {
                        for(i=0;i<(fr->paramCount-1);++i)
                        {
                            write("%s,",type_map(fr->paramTypes[i]));
                        }
                        write("%s)\n",type_map(fr->paramTypes[fr->paramCount-1]));
                    }
                    
                }
                ;

//structures

condition:      IF {++depth;} '(' boolean_expr ')' THEN
                {write("ifeq F%d_%d\n",requestLabel('F'),depth);} 
                block  {write("goto T%d_%d\nF%d_%d:\n",requestLabel('T'),depth,label('F'),depth);}
                ELSE block {write("T%d_%d:\nnop\n",label('T'),depth);--depth;}
                END
                |IF {++depth;} '(' boolean_expr ')' THEN
                {write("ifeq F%d_%d\n",requestLabel('F'),depth);}  block {write("F%d_%d:\nnop\n",label('F'),depth);--depth;}  END
                ;

loop:           WHILE 
                { ++depth;write("W%d_%d:\n",requestLabel('W'),depth);}
                '(' boolean_expr ')' 
                { write("ifeq F%d_%d\n",requestLabel('F'),depth);}
                DO 
                block 
                END
                {write("goto W%d_%d\nF%d_%d:\nnop\n",label('W'),depth,label('F'),depth);--depth;}
                |FOR 
                { ++depth;write("x%d_%d:\nnop\n",requestLabel('x'),depth);}
                IDENTIFIER '=' expr ',' expr 
                DO 
                block 
                END 
                {write("goto x%d_%d",label('x'),depth);--depth;}
                ;

//comma lists
expr_list:      expr                    {$$ = 1;}                   
               // |string_literal
                |expr_list ',' expr     {$$ += 1;}
               // |expr_list ',' string_literal
                |                       {$$ = 0;}
                ;

//
arg_list:       type IDENTIFIER                 
                { 
                    insert($2,$1,fVAR,(void*)0); 
                    write("%s",type_map($1));
                    $$=(FuncRec*)malloc(sizeof(FuncRec));
                    $$->paramCount=0;
                    $$->paramTypes[$$->paramCount] = $1;
                    $$->paramCount+=1;
                }
                |arg_list ',' type IDENTIFIER   
                { 
                    insert($4,$3,fVAR,(void*)0); 
                    write(",%s",type_map($3));
                    $$->paramTypes[$$->paramCount] = $3;
                    $$->paramCount+=1;
                }
                |   
                {
                    $$=(FuncRec*)malloc(sizeof(FuncRec));
                    $$->paramCount=0;
                }
                ;      

identifier:     IDENTIFIER      {
                                    if((int)lookup($1)==-1)
                                    {
                                        printf("Line %d: error: use of undeclared identifier %s\n",lnn+1,$1);
                                        exit(1);
                                    }
                                }
                ;

%%
extern FILE *yyin;
int yyerror(msg)
char *msg;
{
    fprintf(stderr, "%s\n", msg);
    return 0;
}

int main(int argc, char *argv[])
{
    stinit();
    jasm_begin(argv[2]);
    if (argc != 3) {
        printf ("Usage: sc filename output\n");
        exit(1);
    }
    yyin = fopen(argv[1], "r");         /* open input file */
    if (yyparse() == 1)                 /* parsing */
        yyerror("Parsing error !");     /* syntax error */

    dump;
    stclr();
    jasm_end();

    return 0;
}
