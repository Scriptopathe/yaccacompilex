%token tINT tCHAR
%token tAnd tOr tEquals tNotEquals tNot
%token tPrint tIf tElse tWhile tReturn
%token tSemi tComa tAffect tPlus tMinus tMult tDiv tAmpersand
%token tPO tPC tAO tAC tCO tCC
%token <number> tNumber
%token <string> tID
%type  <expression> Expr
%type  <expression> Cond
%type  <expression> Affect
%type  <expression> FuncCallExpr
%type  <type> Type
%type  <type> PrimType
%type  <type> VarDeclType
%type  <type> FuncDeclType
%type  <type> PtrType
%type  <type> FuncType
%type  <string> FuncProto

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

Input           :      	GlobalDecls AreaSeparator FuncDecls;

AreaSeparator	:	tMinus tMinus { do_end_of_declarations(); };

GlobalDecls	:	IVarDecl GlobalDecls 
			| IVarDeclAff GlobalDecls
			| ;

FuncDecls	:	FuncDecl FuncDecls
			| ;

FuncDecl        :       FuncImplProto Body { do_end_of_function();  }
			| FuncProto tSemi;

FuncImplProto	:	FuncProto { do_func_implementation($1); };

FuncProto	:	FuncDeclType tID tPO TypedParams tPC { do_func_declaration($2, $1); $$ = $2; }

Body            :       BodyStart InstList BodyEnd
                        | BodyStart BodyEnd;

BodyStart       :       tAO { stable_block_enter(symbols); };
BodyEnd         :       tAC { stable_block_exit(symbols); };

InstList        :       Inst InstList
                        | Inst;

Inst            :       IVarDecl
                        | IVarDeclAff
                        | IVarAff
                        | IFuncCall
                        | If
                        | While
                        | Return
                        | Print
			| error tSemi { handle_syntax_error(); yyerrok; };

IFuncCall       :       FuncCallExpr tSemi { tempaddr_unlock(symbols, $1.address); };

IVarDeclAff     :       VarDecl tAffect Expr tSemi { do_variable_affectations(&$3); };
IVarDecl        :       VarDecl tSemi;

VarDecl         :       VarDeclType IDList { do_variable_declarations($1); }
			| VarDeclType tID tCO tNumber tCC { do_array_declaration($1, $2, $4); };

IDList          :       VarDeclID SIDList
                        | VarDeclID;

SIDList         :       tComa VarDeclID SIDList
                        | tComa VarDeclID
                        ;

VarDeclID       :       tID { idbuffer_addstr($1); };

VarDeclType     :       Type { idbuffer_init(); $$ = $1; };

IVarAff         :       Affect tSemi;


Cond            :       Expr {do_if($1);} 
If              :       tIf tPO Cond tPC Body { do_body(); }
                        | tIf tPO Cond tPC Body Else;
Else            :       tElse Body;
While           :       tWhile tPO Cond tPC Body;
Return          :       tReturn Expr tSemi { do_return($2); };
Print           :       tPrint tPO Expr tPC tSemi { do_print($3); };
Affect          :       tID tAffect Expr { do_affect($1, $3, DOAFFECT_NONE); $$.address = $3.address; }
			| tMult tID tAffect Expr { do_affect($2, $4, DOAFFECT_DEREFERENCE); $$.address = $4.address; };

Expr            :       Affect
                        | tPO Expr tPC          { $$ = $2;}
                        | Expr tCO Expr tCC     { do_indexing($1, $3, &$$); }
                        | tMult Expr            { do_unary_operation($2, &$$, "COPA"); }
                        | tAmpersand tID        { do_reference($2, &$$); }
                        | Expr tEquals Expr     { do_operation($1, $3, &$$, "EQ"); }
                        | Expr tNotEquals Expr  { do_operation($1, $3, &$$, "NEQ"); }
                        | Expr tAnd Expr        { do_operation($1, $3, &$$, "AND"); }
                        | Expr tOr Expr         { do_operation($1, $3, &$$, "OR"); }
                        | Expr tPlus Expr       { do_operation($1, $3, &$$, "ADD"); }
                        | Expr tMinus Expr      { do_operation($1, $3, &$$, "SUB"); }
                        | Expr tMult Expr       { do_operation($1, $3, &$$, "MUL"); }
                        | Expr tDiv Expr        { do_operation($1, $3, &$$, "DIV"); }
			| tPO Type tPC Expr	{ $4.type = $2; $$ = $4; }
                        | FuncCallExpr 		{ $$ = $1; }
                        | tNumber { do_loadliteral($1, &$$); }
                        | tID { do_loadsymbol($1, &$$); }
                        ;

FuncCallExpr    :       tID tPO Params tPC {
	do_func_call($1, &$$);
};

TypedParams     :       STypedParams
                        | ;

STypedParams    :       TypedParam tComa STypedParams
                        | TypedParam;
TypedParam      :       Type tID { idbuffer_add($1); idbuffer_add($2); };
FuncDeclType	:	Type { idbuffer_init(); };


Params          :       SParams
                        | { idbuffer_init(); };

SParams         :       Expr tComa SParams { idbuffer_add(&$1); }
                        | Expr { idbuffer_init(); idbuffer_add(&$1); };

Type            :       PrimType
                        | PtrType
                        | FuncType;

FuncType        :       Type tPO tMult tPC tPO TypeList tPC { $$ = do_makefunctype($1); };

TypeList        :       STypeList {  }
                        | { };

STypeList       :       Type tComa STypeList { idbuffer_add($1); }
                        | Type { idbuffer_init(); idbuffer_add($1); };


PtrType         :       Type tMult {
  $$ = type_create_ptr($1);
};

PrimType        :       tINT    { $$ = type_create_primitive("int"); }
                        | tCHAR { $$ = type_create_primitive("char"); }

%%

void yyerror(char const * errorText) { print_warning("%s\n", errorText); }
int getMode();

int main(int argc, char** argv)
{
	// test_stable(); return 0;
	if(getMode() == 0)
		while(1) { yylex(); }

	if(getMode() == 1)
	{
		ctx_init();
		yyparse();
		ctx_close();
	}

	return 0;
}
