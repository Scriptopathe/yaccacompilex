%token tINT tCHAR
%token tAnd tOr tEquals tNotEquals tNot
%token tPrint tIf tWhile tReturn 
%token tSemi tComa tAffect tPlus tMinus tMult tDiv
%token tPO tPC tAO tAC
%token <number> tNumber 
%token <string> tID
%type  <expression> Expr
%type  <expression> Affect
%type  <expression> FuncCallExpr
%type  <type> Type
%type  <type> PrimType
%type  <type> VarDeclType
%type  <type> PtrType
%type  <type> FuncType

%error-verbose

%right tAffect
%left  tAnd tOr
%left  tEquals tNotEquals
%left  tPlus tMinus
%left  tMult tDiv
 
%start Input 

%{
	#include <stdio.h>
	#include "compiler.h"
	void yyerror(char const * errorText);
%}

%union 
{	
        int number;
        char *string;
	type_t* type;
	expression_t expression;
}


%%

Input 		: 	FuncDecl Input
			| FuncDecl ;

FuncDecl 	:	Type tID tPO TypedParams tPC Body;


Body 		: 	tAO InstList tAC
			| tAO tAC;

InstList	: 	Inst InstList
			| Inst;

Inst		:  	IVarDecl 
			| IVarDeclAff 
			| IVarAff
			| IFuncCall
			| If 	
			| While		
			| Return
			| Print;

IFuncCall	: 	FuncCallExpr tSemi;

IVarDeclAff	: 	VarDecl tAffect Expr tSemi {
	for(int i = 0; i < idbuffer_size(); i++)
	{
		const char* symbol = (const char*)idbuffer_get(i);
		do_affect(symbol, $3, 1);
	}
};

IVarDecl	:	VarDecl tSemi;

VarDecl		: 	VarDeclType IDList { 
	for(int i = 0; i < idbuffer_size(); i++)
	{
		// TODO : 0xDODO => size ou type
		printf("stable_add %s %p\n", (char*)idbuffer_get(i), idbuffer_get(i));
		stable_add(symbols, (char*)idbuffer_get(i), -1, ctx.depth, $1);
	}
};

IDList 		: 	VarDeclID SIDList 
			| VarDeclID;

SIDList  	: 	tComa VarDeclID SIDList
			| tComa VarDeclID 
			;

VarDeclID	:	tID {
	idbuffer_addstr($1);
};

VarDeclType	:	Type {
	idbuffer_init();
	$$ = $1;
};

IVarAff 	: 	Affect tSemi;


Cond 		: 	Expr ;
If		: 	tIf tPO Cond tPC Body;
While		: 	tWhile tPO Cond tPC Body;
Return		: 	tReturn Expr tSemi;
Print		: 	tPrint tPO Expr tPC tSemi;
Affect		: 	tID tAffect Expr {
	do_affect($1, $3, 0);
	$$.address = $3.address;
};

Expr 		:	Affect {  } 
			| tPO Expr tPC 		{ $$ = $2;}
			| Expr tEquals Expr 	{ do_operation($1, $3, &$$, "EQ"); }
			| Expr tNotEquals Expr 	{ do_operation($1, $3, &$$, "NEQ"); }
			| Expr tAnd Expr 	{ do_operation($1, $3, &$$, "AND"); }
			| Expr tOr Expr 	{ do_operation($1, $3, &$$, "OR"); }
			| Expr tPlus Expr  	{ do_operation($1, $3, &$$, "ADD"); }
			| Expr tMinus Expr 	{ do_operation($1, $3, &$$, "SUB"); }
			| Expr tMult Expr 	{ do_operation($1, $3, &$$, "MUL"); }
			| Expr tDiv Expr 	{ do_operation($1, $3, &$$, "DIV"); }
			| FuncCallExpr
			| tNumber {
  int addr = tempaddr_lock();
  printf("AFC %d %d\n", addr, $1);
  $$.address = addr;
  $$.type = type_create_primitive("int");
}
			| tID {  
  symbol_t* sym = stable_find(symbols, $1);
  $$.type = sym->type;
  $$.address = sym->address;
} 
			;
FuncCallExpr	: 	tID tPO Params tPC {

};

TypedParams 	:	TypedParam STypedParams
			| ;

STypedParams	:	tComa TypedParam STypedParams 
			| tComa TypedParam;

TypedParam	:	Type tID;

Params 		: 	Expr SParams
			| ;

SParams 	: 	tComa Expr SParams
			| tComa Expr;

Type 		:   	PrimType
			| PtrType
			| FuncType; 

FuncType	:	Type tPO tMult tPC tPO TypeList tPC {
  type_t** args = (type_t**)malloc(sizeof(type_t*)*idbuffer_size());
  for(int i = 0; i < idbuffer_size(); i++)
  {
    args[idbuffer_size() - i - 1] = idbuffer_get(i);
  }
  type_t* func = type_create_func($1, args, idbuffer_size()); 
  $$ = func;
};

TypeList	:	STypeList {  }
			| { };

STypeList	: 	Type tComa STypeList { idbuffer_add($1); }
			| Type { idbuffer_init(); idbuffer_add($1); };
			

PtrType 	:	Type tMult {
  $$ = type_create_ptr($1);
};

PrimType	:	tINT 	{ $$ = type_create_primitive("int"); }
			| tCHAR { $$ = type_create_primitive("char"); }

%%

void yyerror(char const * errorText) { }
int getMode();

int main(int argc, char** argv) 
{
	ctx_init();
	if(getMode() == 0)
		while(1) { yylex(); }

	if(getMode() == 1)
		while(1)
		{ 
			yyparse();
			stable_print(symbols);
			printf("New parse...\n");
		}

	return 0;
}
