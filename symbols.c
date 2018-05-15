#include "symbols.h"
#include <stdio.h>
#include <stdlib.h>
#include "string.h"

SymbolTable* stptr;
int scope_depth;
FuncRec* meta;
void stinit()
{
	int i;
	stptr = (SymbolTable*)malloc(sizeof(SymbolTable));
	stptr->next=0;
	stptr->child=0;
	stptr->end=0;
	stptr->parent=0;
	stptr->varid=0;
	stptr->scope=0;
	stptr->head=0;
}
void stclr()
{
	while(stptr->parent!=0)
	{
		stptr=stptr->parent;
	}
	destroy(stptr);
	free(stptr);
}
void destroy(SymbolTable* s)
{
	SymbolTable* ss;
	ss = s->child;
	for(;ss!=0;ss=ss->next)
	{
		destroy(ss);
		free(ss);
	}
}	

SymbolTable* scope_enter()
{
	++scope_depth;
	if(stptr->child==0)
	{
		stptr->child = (SymbolTable*)malloc(sizeof(SymbolTable));
		stptr->end=stptr->child;
		stptr->end->parent = stptr;
	}
	else
	{
		stptr->end->next = (SymbolTable*)malloc(sizeof(SymbolTable));
		stptr->end = stptr->end->next;
		stptr->end->parent = stptr;
	}
	stptr = stptr->end;
	stptr->next=0;
	stptr->child=0;
	stptr->end=0;
	stptr->varid=0;
	stptr->scope = scope_depth;
	stptr->head=0;
	//memset(stptr->symbols,0,sizeof(Symrec*)*hsize);
	return stptr;
}
SymbolTable* scope_leave()
{
	--scope_depth;
	stptr = stptr->parent;
	return stptr;
}
SymbolTable* root()
{

	int i;
	SymbolTable* rt = stptr;

	while(rt->parent!=0)
	{
		//printf("-->%d",rt->parent);
		rt=rt->parent;
	}

	
	return rt;
}


void print_symbol(Symrec* s)
{

	static char* t[] = {" ","integer","string","real","boolean"};
	static char* f[] = {"const","array"," ","function"};
	printf("%x::%s--> %s %s ,local=%d ,value=%d\n",s,s->symbol,t[s->stype],f[s->sflag],s->varid,s->data);
}
void print(SymbolTable* s,int depth)
{
	int i,j;
	Symrec* sr = s->head;
	for(j=0;j<depth;++j)
		printf("     ");
	printf("------------------\n");


	while(sr!=0)
	{
		for(j=0;j<depth;++j)
				printf("     ");
		if(sr->symbol !=0 && sr->stype!=0)
		print_symbol(sr);
		sr=sr->next;
	}
}
void print_subtree(SymbolTable* st,int depth)
{
	SymbolTable* s = st->child;
	print(st,depth);
	while(s!=0)
	{		
		print_subtree(s,depth+1);
		s=s->next;
	}
}

lresult LRESULT;
Symrec* lookup(char* indentifier)
{
	SymbolTable* s = stptr;
	Symrec* pos;
	while(1)
	{
		pos = hash_search(s,indentifier);
		if(pos!=-1)
		{
			LRESULT.t=s;
			LRESULT.s=pos;
			return pos;
		}
		if(s->parent!=0)s=s->parent;
		else return -1;
	}
	return -1;
}
int getid(char* indentifier)
{
	Symrec* sr =lookup(indentifier);
	if(sr!=-1)
	{
		return sr->varid;
	}
}
Symrec* hash_search(SymbolTable* s, char* key)
{
	Symrec* sr = s->head;
	while(sr!=0)
	{
		if(strcmp(sr->symbol,key)==0)
		{
			return sr;
		}
		sr=sr->next;
	}
	return -1;

}
Symrec* hash_insert(SymbolTable* s, char* key,Symtype type,Symflag flag,void* data)
{
	int i,t;
	Symrec* index;
	if((index=hash_search(s,key))!=-1)
	{
		return index;
	}
	else
	{
		Symrec* cr = (Symrec*)malloc(sizeof(Symrec));
		cr->symbol = key;
		cr->stype = type;
		cr->sflag = flag;
		cr->data=data;
		cr->next=0;
		cr->varid = s->varid;
		s->varid++;

		if(s->head == 0)
		{
			s->head = cr;
		}
		else
		{
			Symrec* sr = s->head;
			while(sr->next!=0)
				sr=sr->next;
			sr->next = cr;

		}
	}
	return -1;
}

