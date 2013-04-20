%{
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "src/symbols_table/table.h"

int yylineno = 1;	

typedef struct {
	int entero;
	type_data tipo;
	char *lexema;
}atributos;

#define YYSTYPE atributos

table ts;

/* Se debe modificar la implementación la función yyerror. En este caso simplemente se escribe el
mensaje en pantalla, por lo que habrá que añadir previamente la declaración de la variable global asociada
al número de línea (declarada en la práctica anterior en el fichero fuente del flex) y modificar yyerror para
que se muestre dicho número de línea */
void yyerror (char *msg)
{
	fprintf(stderr, "\n");
	fprintf(stderr,"Linea %d => ",yylineno,"\n");
	fprintf(stderr,msg);
}
%}

/* A continuación declaramos los nombres simbólicos de los tokens, así como el símbolo inicial de la
gramática (axioma). Byacc se encarga de asociar a cada uno un código */
%start strt
%token NUM ASIG BOOL CAD CHAR COMA COMILLSIMPLE COMENT CONCAT CONST ENT ENTONC ESC FALSO FIN FUNC HASTA INIC LEE LONG NOM NOMCONS PDE PIZ PROG PTO PTOCOMA PTOS REAL REPIT SI SINO TIPO USAR VAR VERD CADTEXTO

//Precedencia de operaciones
%left 	SUM REST
%left 	MULT DIV
%left 	IGUAL DIST MAY MAYIG MEN MENIG
%left 	Y O
%left 	NO
%left 	UMENOS UMAS

//Tokens para el TDA Cadena
%token INS EXT BUSC BORR
%%

//*************************************************************
//*************************************************************
/* Sección de producciones que definen la gramática */

strt:			{ 
					ts = table_new(); 
					table_push(ts, table_entry_new_mark(yylineno)); 
				} 
				prog
				{ 
					table_display(ts); 
					table_destroy(&ts); 
				}
				;

prog: 			 PROG NOM PTOCOMA dec1 dec2 cuerpo
				|PROG NOM PTOCOMA dec1 cuerpo
				|PROG NOM PTOCOMA dec2 cuerpo
				|PROG NOM PTOCOMA cuerpo;

dec1:	 		 librerias constantes def_tipos
				|librerias def_tipos
				|constantes def_tipos
				|librerias
				|constantes
				|def_tipos;

dec2: 			funcs vars 
				|funcs
				|vars;

//*************************************************************
//*************************************************************
//Definicion de Uses
librerias: 		USAR nombres PTOCOMA;

nombres: 		nombres COMA NOM |NOM;


//*************************************************************
//*************************************************************
//Definicion de Constantes
constantes: 	CONST conss;

conss: 			conss cons
				|cons;

cons: 			NOMCONS IGUAL val_cons PTOCOMA;

val_cons: 		VERD
				|FALSO
				|NUM;


//*************************************************************
//*************************************************************
//Definicion de tipos
def_tipos: 		TIPO nombress
				;

nombress: 		nombress def_tipo
				|def_tipo
				;

def_tipo: 		NOM IGUAL tipo PTOCOMA
				;

tipo: 			ENT 	{ $$.tipo = INTEGER;} 
				|REAL 	{ $$.tipo = REAL; 	} 
				|BOOL 	{ $$.tipo = BOOLEAN;} 
				|CAD 	{ $$.tipo = STRING; } 
				|CHAR 	{ $$.tipo = CHARACTER;} 
				|NOM	{ $$.tipo = UNKNOWN;} 
				;


//*************************************************************
//*************************************************************
//Definición de Variables
vars: 			VAR decl_vars
				;

decl_vars: 		 decl_vars decl_var PTOCOMA 
				|decl_var PTOCOMA
				;

decl_var: 		nombre_dv PTOS tipo 
				{ 
					table_update_unassigned_types(ts, $3.tipo); 
				}
				;

nombre_dv: 		nombre_dv COMA NOM 
				{
					table_push(ts, table_entry_new_variable($3.lexema, UNASSIGNED, yylineno));
				}
				|NOM 
				{
					table_push(ts, table_entry_new_variable($1.lexema,UNASSIGNED,yylineno));
				}
				;


//*************************************************************
//*************************************************************
//Definición de función

funcs:			funcs func
				|func
				;

func:			func_header func_content
				|func_header PTOCOMA func_dec func_content
				;

func_dec:		vars func_nested
				|vars
				|func_nested
				;

func_nested: 	func
				|func_nested
				;

func_header: 	FUNC NOM PIZ params PDE PTOS tipo 
				{ 
					int i = $4.entero;
					table tsf1 = table_new(), tsf2 = table_new();
					while((i--) > 0)
					{
						table_entry e = table_pop(ts);
						table_push(tsf1, e);
						table_push(tsf2, e);
					}

					table_push(ts, table_entry_new_function($2.lexema, $4.entero, $7.tipo, yylineno)); 
					while(!table_empty(tsf1)) table_push(ts, table_pop(tsf1));

					table_push(ts, table_entry_new_mark(yylineno)); 
					while(!table_empty(tsf2))table_push(ts, table_pop(tsf2));

					table_destroy(&tsf1);
					table_destroy(&tsf2);
							
				}
				|FUNC NOM PTOS tipo
				{
					table_push(ts, table_entry_new_function($2.lexema, 0, $4.tipo, yylineno));
					table_push(ts, table_entry_new_mark(yylineno));
				}
				;

func_content: 	INIC sents FIN PTOCOMA 
				{
					table_pop_scope(ts);
				}
				|INIC FIN PTOCOMA 
				{
					table_pop_scope(ts);
				}
				;

sents: 			sents sent PTOCOMA
				|sent PTOCOMA
				;

params:			params COMA param { $$.entero++; } 
				|param {$$.entero = 1; }
				;

param: 			NOM PTOS tipo 
				{ 
					table_push(ts, table_entry_new_parameter($1.lexema, $3.tipo, yylineno)); 
				}
				;

/* He añadido soporte para una zona de declaracion de variables despues de la cabecera 
	func_header 
	func_content
*/


//*************************************************************
//*************************************************************
//Definición de cuerpo
cuerpo: 		INIC FIN PTO
				|INIC sents FIN PTO
				;

sent: 			asignacion
				|entrada
				|salida
				|expr
				|insertar_c
				|borrar_c
				|bucle
				|condicion
				;

asignacion: 	NOM ASIG expr;

entrada: 		LEE NOM;

salida: 		ESC PIZ e_salidas PDE;

e_salidas: 		e_salidas COMA e_salida |e_salida;

e_salida: 		CADTEXTO |expr;

expr :	 		expr SUM expr
				|expr REST expr
				|expr MULT expr
				|expr DIV expr
				|expr Y expr
				|expr O expr
				|expr MAYIG expr
				|expr MENIG expr
				|expr MAY expr
				|expr MEN expr
				|expr DIST expr
				|expr IGUAL expr
				|REST expr %prec UMENOS /*REST toma la precedencia de UMINUS*/
				|SUM expr %prec UMAS /*SUM toma la precedencia de UMAS*/
				|NO expr
				|VERD
				|FALSO
				|llamada_funcion
				|PIZ expr PDE
				|NUM
				|NOMCONS
				|busca_c
				|extrae_c
				|concat_c
				|long_c
				; 

llamada_funcion: NOM PIZ exprs PDE
				|NOM
				;

exprs: 			exprs COMA expr
				|expr;

//*************************************************************
//*************************************************************
//Bucle REPEAT UNTIL
bucle: 			REPIT sents HASTA expr
				|REPIT HASTA expr;


//*************************************************************
//*************************************************************
//Sentencia condicional
condicion: 		SI expr ENTONC bloque_c 
				|SI expr ENTONC bloque_c SINO bloque_c 
				;

bloque_c: 		sent
				|INIC sents FIN;


//*************************************************************
//*************************************************************
//#####Operaciones asociadas al TDA Cadena

//Inserta una subcadena en una cadena a partir de una posicion  inserta(cadena,subcadena,pos)
insertar_c: 	INS PIZ param_cadena COMA param_cadena COMA expr PDE;

//Borra a partir de una posicion P, N caracteres borra("pepe",2,1);
borrar_c: 		BORR PIZ param_cadena COMA expr COMA expr PDE;

//Buscar en una cadena, una subcadena
busca_c: 		BUSC PIZ param_cadena COMA param_cadena PDE;

//Extrae N caracteres desde la posicion P en la cadena C     extrae(C,N,P)
extrae_c: 		EXT  PIZ param_cadena COMA expr COMA expr PDE;

//Concatena dos cadenas
concat_c: 		CONCAT PIZ param_cadena COMA param_cadena PDE;

//Devuelve la longitud de la cadena
long_c: 		LONG PIZ param_cadena PDE;

//Definición de los parámetros que se aceptarán
param_cadena:  	llamada_funcion
				|concat_c
				|extrae_c
				|CADTEXTO
				;
%%

/* Aquí incluimos el fichero generado por el Flex, que implementa la función yylex() */
#include "lexyy.c"
