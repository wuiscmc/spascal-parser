%{ 

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

%}

letra   		[a-zA-Z]
letraMay 		[A-Z]	
digito  		[0-9]
alphanum 		[a-zA-Z0-9]
cadena 			[^'\n]             
otros   		.			

%x 				comentario

%%

"+"     	return SUM;
"-"     	return REST;
"/"     	return DIV;
"*"     	return MULT;
">"     	return MAY;
"<<"		return DMEN;
"<"     	return MEN;
">="   		return MAYIG;
"<="   		return MENIG;
"="     	return IGUAL;
"<>"    	return DIST;
":="    	return ASIG;
"("     	return PIZ;
")"     	return PDE;
","     	return COMA;
"'"			return COMILLSIMPLE;
":"     	return PTOS;
";"     	return PTOCOMA;
"."     	return PTO;
"?"			return QMARK;
"["			return BRACKIZ;
"]"			return BRACKDE;

[Pp][Rr][Oo][Gg][Rr][Aa][Mm][Aa]    	return PROG;
[Cc][Oo][Nn][Ss][Tt]  					return CONST;
[Uu][Ss][Aa][Rr]						return USAR;
[Tt][Ii][Pp][Oo]						return TIPO;
[Vv][Aa][Rr]        					return VAR;
[Ll][Ii][Ss][Tt][Aa]					return LISTA;
[Ee][Nn][Tt][Ee][Rr][Oo]            	return ENT;
[Cc][Aa][Rr][Aa][Cc][Tt][Ee][Rr]		return CHAR;
[Bb][Oo][Oo][Ll][Ee][Aa][Nn][Oo]    	return BOOL;
[Rr][Ee][Aa][Ll]						return DREAL;
[Cc][Aa][Dd][Ee][Nn][Aa]				return CAD;
[Ff][Uu][Nn][Cc][Ii][Oo][Nn]			return FUNC;
[Ii][Nn][Ii][Cc][Ii][Oo]            	return INIC;
[Ff][Ii][Nn]                        	return FIN;
[Ll][Ee][Ee]                        	return LEE;
[Ee][Ss][Cc][Rr][Ii][Bb][Ee]        	return ESC;
[Vv][Ee][Rr][Dd][Aa][Dd][Ee][Rr][Oo]    return VERD;
[Ff][Aa][Ll][Ss][Oo]             		return FALSO;
[Nn][Oo]                               	return NO;
[Yy]                                  	return Y;
[Oo]                                 	return O;
[Ss][Ii]                             	return SI;
[Ee][Nn][Tt][Oo][Nn][Cc][Ee][Ss]   		return ENTONC;
[Ss][Ii][Nn][Oo]                        return SINO;
[Rr][Ee][Pp][Ii][Tt][Ee]          	 	return REPIT;
[Hh][Aa][Ss][Tt][Aa]             		return HASTA;
[Ii][Nn][Ss][Ee][Rr][Tt][Aa]          	return INS;
[Bb][Oo][Rr][Rr][Aa]					return BORR;
[Bb][Uu][Ss][Cc][Aa]					return BUSC;
[Cc][Oo][Nn][Cc][Aa][Tt][Ee][Nn][Aa]	return CONCAT;
[Ee][Xx][Tt][Rr][Aa][Ee]				return EXT;
[Ll][Oo][Nn][Gg][Ii][Tt][Uu][Dd]		return LONG;

\'{alphanum}\'					yylval.lexema = strdup(yytext); return CAR;
{letraMay}({letraMay})*			yylval.lexema = strdup(yytext); return NOMCONS;
{letra}({digito}|{letra})*		yylval.lexema = strdup(yytext); return NOM;
{digito}+                       yylval.lexema = strdup(yytext); return NUM;
{digito}+\.{digito}+			yylval.lexema = strdup(yytext); return NUMREAL;

" "+ 	                        ;
\n                              yylineno++;
\t                              ;
"{"  							BEGIN(comentario);
<comentario>[^}\n]   			;
<comentario>\n   				yylineno++;
<comentario>"}"       			BEGIN (INITIAL);
\'{cadena}*\' 					return CADTEXTO; 
{otros}							yyerror("ERROR de lexico en la entrada");
%%
