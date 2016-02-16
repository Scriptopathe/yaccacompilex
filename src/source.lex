%{
#include "y.tab.h"
#include <stdio.h>
int getMode();
#define p(x, s) if(getMode() == 0) printf(x, s)

%}
tNumber 	 (\+|\-)?([0-9]+)(e(\+|\-)[0-9]+)*
tID 		([a-zA-Z_]+[0-9a-zA-Z_]*)
tINT 		"int"
tPrint 		"print"
tIf 		"if"
tWhile 		"while"
tReturn 	"return"
tSemi 		";"
tComa 		","
tAffect 	"="
tEquals  	"=="
tPlus 		"+"
tMinus 		"-"
tMult 		"*"
tDiv 		"/"
tPO 		"("
tPC 		")"
tAO 		"{"
tAC 		"}"
tAnd		"&&"
tOr		"||"
tNot		"!"
tNotEquals 	"!="
%%

{tNumber} {
	yylval.number = atoi(yytext);
	p("Number{%s} ", yytext);
	return tNumber;
};
{tINT} 			{ p("INT{%s} ", yytext); 	return tINT; };
{tPrint} 		{ p("Print{%s} ", yytext); 	return tPrint; };
{tIf} 			{ p("If{%s} ", yytext); 	return tIf; };
{tWhile} 		{ p("While{%s} ", yytext); 	return tWhile; };
{tReturn} 		{ p("Return{%s} ", yytext); 	return tReturn; };
{tID} 			{ p("ID{%s} ", yytext); 	yylval.string = yytext; return tID; };
{tSemi} 		{ p("Semi{%s} ", yytext); 	return tSemi; };
{tComa} 		{ p("Coma{%s} ", yytext); 	return tComa; };
{tEquals}		{ p("Equals{%s} ", yytext);	return tEquals; };
{tNotEquals} 		{ p("Not Equals{%s} ", yytext);	return tNotEquals; };
{tAffect} 		{ p("Affect{%s} ", yytext); 	return tAffect; };
{tNot}			{ p("Not{%s} ", yytext);	return tNot; };
{tPlus} 		{ p("Plus{%s} ", yytext); 	return tPlus; };
{tMinus} 		{ p("Minus{%s} ", yytext); 	return tMinus;};
{tMult} 		{ p("Mult{%s} ", yytext); 	return tMult; };
{tDiv} 			{ p("Div{%s} ", yytext); 	return tDiv; };
{tPO} 			{ p("PO{%s} ", yytext); 	return tPO; };
{tPC} 			{ p("PC{%s} ", yytext); 	return tPC; };
{tAO} 			{ p("AO{%s} ", yytext); 	return tAO; };
{tAC} 			{ p("AC{%s} ", yytext); 	return tAC;};
{tAnd}			{ p("And{%s} ", yytext);	return tAnd;};
{tOr}			{ p("Or{%s} ", yytext);		return tOr;};

. ;
%%
