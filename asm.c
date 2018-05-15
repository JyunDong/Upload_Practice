#include "asm.h"
#include "string.h"
FILE* jasm;
Space* Head = 0;
Space* Focus = 0;
char classname[50];
char* type_map(int type)
{
	static char* map[] = {" ","int","double","int","boolean"};
	return map[type];
}
int ltable[30];
int depth=0;
int bl=0;
int requestLabel(char prefix)
{
	prefix-='A';
	++ltable[prefix];
	return ltable[prefix];
}
int label(char prefix)
{
	prefix-='A';
	return ltable[prefix];
}

Space* createSpace(int id,int size)
{
	Space* s = (Space*)malloc(sizeof(Space));
	s->content=(char*)malloc(size*sizeof(char));
	s->id=id;
	s->length=0;
	s->next=0;
	if(Head==0)Head=s;
	else 
	{
		Space* sp = Head;
		while(sp->next!=0)
		{
			sp=sp->next;
		}
		sp->next = s;
	}
	return s;
}

void focus(int id)
{
	Space* sp = Head;
	while(1)
	{
		if(sp->id == id )
		{
			Focus = sp;
			return;
		}
		sp=sp->next;
		if(sp == 0 )return;

	}



}
void jasm_begin(char* name)
{
	memset(ltable,0,30);

	jasm=fopen(name,"w");
	memcpy(classname,name,strlen(name));
	(*strchr(classname,'.')) = 0;
	Head = createSpace(CLASS,100);
	createSpace(GLOBAL,1000);
	createSpace(MAIN,3000);
	focus(MAIN);
	write("method public static void main(java.lang.String[])\nmax_stack 15\nmax_locals 15\n{\n");
	createSpace(FUNC,2000);
	focus(CLASS);
	write("class %s\n{\n",classname);
	focus(MAIN);

}
#include "symbols.h"

void jasm_end()
{
	focus(GLOBAL);

	SymbolTable* s = stptr;
	Symrec* sr=stptr->head;
	int i;
	while(sr!=0)
	{
		//printf("sr\n");
		if(sr->sflag ==fVAR)
		{
			write("field static %s %s = %d\n",type_map(sr->stype),sr->symbol,(int)(sr->data));
		}
		sr=sr->next;
	}

	focus(MAIN);
	write("return\n}\n");
	focus(FUNC);
	write("\n}");
	Space* sp = Head;
	Space* t;
	while(sp!=0)
	{
		fprintf(jasm, "%s\n", sp->content);
		t=sp;
		sp=sp->next;
		free(t);
	}
	fclose(jasm);

}

