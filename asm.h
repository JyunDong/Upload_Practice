#ifndef ASM_H
#define ASM_H
#include <stdio.h>

#define GLOBAL 1
#define MAIN 2
#define CLASS 3
#define FUNC 4

extern char classname[50];
extern FILE* jasm;
extern int ltable[30];
extern int depth;
extern int bl;
char* type_map(int);

void jasm_begin(char*);

void jasm_end();

//structure that store a assembly code segment, calling jasm_end() will write all code segment to output file
typedef struct codespace
{
	int id;
	char* content;
	int length;
	struct codespace* next;
}Space;

int requestLabel(char);
int label(char);

extern Space* Head;
extern Space* Focus;
Space* createSpace(int,int);
void focus(int);


//#define writeln(...) { code_length+=sprintf(code_space+code_length,__VA_ARGS__);code_length+=sprintf(code_space+code_length,"\n");}
#define write(...) { Focus->length+=sprintf(Focus->content+Focus->length,__VA_ARGS__);Focus->content[Focus->length]=0;}

#endif