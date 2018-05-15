#ifndef SYMBOLS_H
#define SYMBOLS_H

//expose line number to analyser
extern int lnn;
typedef enum symtype{

	tINTEGER = 1,tSTRING = 2 ,tREAL = 3,tBOOLEAN =4

}Symtype;

typedef enum symflag{
	fCONST,fARRAY,fVAR,fFUNC
}Symflag;

//structure holding information associated with a symbol
typedef struct symrec
{
	char* symbol;
	Symtype stype;
	Symflag sflag;
	void* data;
	int varid;
	struct symrec* next;
}Symrec;

typedef struct symboltable
{

	//hash table
	//pointer to next scope in the list with same depth
	struct symboltable* next;
	//end of child scope list
	struct symboltable* end;
	//begin of child scope list
	struct symboltable* child;
	//pointer to parent scope
	struct symboltable* parent;
	int varid;
	int scope;
	Symrec* head;
}SymbolTable;

typedef struct tuple_symrec_symtable
{
	SymbolTable* t;
	Symrec* s;
}lresult;

typedef struct funcrec
{
	int paramTypes[10];
	int paramCount;

}FuncRec;


extern lresult LRESULT;

//pointer to symbol table associate with current scope
extern SymbolTable* stptr;
extern int scope_depth;


SymbolTable* scope_enter();//create and enter child scope
SymbolTable* scope_leave();//return to parent scope


//find root scope (global)
SymbolTable* root();



//initialize empty symbol table
void stinit();

//release symbol table resources
void stclr();
void destroy(SymbolTable*);

/*search for a identifier in current scope,
*this function will proceed to search parent scope if given symbol is not found,until root scope is reached
*/
Symrec* lookup(char*);

void print(SymbolTable*,int);

//print subtree
void print_subtree(SymbolTable* ,int);

Symrec* hash_search(SymbolTable*,char* key);
Symrec* hash_insert(SymbolTable*,char*,Symtype,Symflag,void*);
int getid(char* id);

#define dump print_subtree(root(),0)
#define insert(x,y,z,d) { hash_insert(stptr,x,y,z,d);lookup(x);}
#define global {return stptr==root();}
#endif
