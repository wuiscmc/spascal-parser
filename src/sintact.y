%{
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "src/symbols_table/table.h"

#define DEBUG_Y

int yylineno = 1;	

typedef struct {
	int entero;
	type_data tipo;
	char *lexema;
}atributos;

#define YYSTYPE atributos

table ts;
table ts_parameters;
char msg[1000];

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

void push_to_table(table_entry e)
{
	int index_table = table_find(ts, e);
	if(index_table < 0)
	{
		table_push(ts, e);
	}
	else 
	{
		table_entry e = table_get(ts, index_table);
		if(e.entry_type != CONSTANT)
		{
			sprintf(msg, "'%s' previously declared here (line %d)", e.name, e.line);	
		}
		else
		{
			sprintf(msg, "'%s' is already declared as a constant. Cannot redefine it", e.name);
		}
		 
		yyerror(msg);
	}
}

type_data check_function_entries(table_entry efunction, table_entry efunction2)
{
	type_data t = efunction.data_type;
	if(table_entry_valid(efunction))
	{
		table_entry_error_code code = table_entry_compare(efunction, efunction2); 
		if(code != TE_SAME_ENTRY)
		{
			t = UNKNOWN;
			sprintf(msg, "Undefined call to function %s: %s",efunction.name, table_entry_error_code_message(code));
			yyerror(msg);
		}
	}
	else
	{
		t = UNKNOWN;
		sprintf(msg, "Undefined reference to function %s", efunction.name);
		yyerror(msg);
	}

	if( t != UNKNOWN && efunction.params > 0)
	{
		int index = table_find(ts, efunction);
		int i = efunction.params;
		table_entry expected, received;  
		while(!table_empty(ts_parameters))
		{
			expected = table_get(ts, index + i);
			received = table_pop(ts_parameters);
		
			if(!table_entry_compatible_data_type(expected.data_type, received.data_type))
			{
				sprintf(msg, "Function '%s' parameter '%d' type missmatch (expected: %s, got: %s)", 
					efunction.name, i , data_type_name(expected.data_type), data_type_name(received.data_type));
				t = UNKNOWN;
				yyerror(msg);
			}
			i--;
		}
	}


	return t;
}

type_data check_data_type(type_data type, type_data* accepted_types, int n_accepted_types)
{
	int i, index = -1;
	for(i = 0; i < n_accepted_types; i++)
	{
		if(type == accepted_types[i]) index = i;
	}
	if(index < 0)
	{
		sprintf(msg,"Incompatible types. Expected:");
		for(i = 0; i < n_accepted_types; i++)
		{
			sprintf(msg, "%s %s,", msg, data_type_name(accepted_types[i]));
		}

		sprintf(msg, "%s Got: %s",msg, data_type_name(type));
		yyerror(msg);

		return UNKNOWN;
	
	}
	else
	{
		return accepted_types[index];
	}
}
type_data check_data_types(type_data d1, type_data d2, type_data* accepted_types, int n_accepted_types, type_data expected_type)
{
	type_data res = expected_type;

	if( check_data_type(d1, accepted_types, n_accepted_types) == UNKNOWN
	 || check_data_type(d2, accepted_types, n_accepted_types) == UNKNOWN )
	{
		res = UNKNOWN;
	}
	return res;	
}


type_data check_data_types_operation(type_data d1, type_data d2 )
{
	type_data t = d1;
	if(!table_entry_compatible_data_type(d1, d2))
	{
		t = UNKNOWN;
	}
	return d1;
}


%}

/* A continuación declaramos los nombres simbólicos de los tokens, así como el símbolo inicial de la
gramática (axioma). Byacc se encarga de asociar a cada uno un código */
%start strt
%token NUM ASIG BOOL CAD CHAR COMA COMILLSIMPLE COMENT CONCAT CONST ENT ENTONC ESC FALSO FIN FUNC HASTA INIC LEE LONG NOM NOMCONS PDE PIZ PROG PTO PTOCOMA PTOS DREAL REPIT SI SINO TIPO USAR VAR VERD CADTEXTO

//Precedencia de operaciones
%left 	SUM REST
%left 	MULT DIV
%left 	IGUAL DIST MAY MAYIG MEN MENIG
%left 	Y O
%left 	NO
%left 	UMENOS UMAS

//Tokens para el TDA Cadena
%token INS EXT BUSC BORR

//Tokens para el TDA Lista de enteros
%token LISTA QMARK DMEN BRACKIZ BRACKDE

%%

//*************************************************************
//*************************************************************
/* Sección de producciones que definen la gramática */

strt:			{ 
					ts = table_new(); 
					ts_parameters = table_new(); 
					table_push(ts, table_entry_new_mark(yylineno)); 
				} 
				prog
				{ 
					table_pop_scope(ts);
					table_destroy(&ts);
					table_destroy(&ts_parameters);
				}
				;

prog: 			 PROG NOM PTOCOMA dec1 dec2 cuerpo
				|PROG NOM PTOCOMA dec1 cuerpo
				|PROG NOM PTOCOMA dec2 cuerpo
				|PROG NOM PTOCOMA cuerpo
				;

dec1:	 		 librerias constantes def_tipos
				|librerias def_tipos
				|constantes def_tipos
				|librerias
				|constantes
				|def_tipos
				;

dec2: 			funcs vars 
				|funcs
				|vars
				;

//*************************************************************
//*************************************************************
//Definicion de Uses
librerias: 		USAR nombres PTOCOMA;

nombres: 		nombres COMA NOM |NOM;

//*************************************************************
//*************************************************************
//Definicion de Constantes
constantes: 	CONST conss
				;

conss: 			conss cons
				|cons
				;

cons: 			NOMCONS IGUAL val_cons PTOCOMA
				{
					table_entry const_entry = table_entry_new_constant($1.lexema, $3.tipo, yylineno);
					if( table_find(ts, const_entry) < 0 )
					{
						table_push(ts, const_entry);
					}
					else
					{
						sprintf(msg, "CONSTANT '%s' was already defined here: line %d", const_entry.name, const_entry.line);
						yyerror(msg);
					}	
				}
				;

val_cons: 		VERD 	{ $$.tipo = BOOLEAN; }
				|FALSO 	{ $$.tipo = BOOLEAN; }
				|NUM; 	{ $$.tipo = INTEGER; }


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

tipo: 			ENT 	{ $$.tipo = INTEGER;  } 
				|DREAL 	{ $$.tipo = REAL; 	  } 
				|BOOL 	{ $$.tipo = BOOLEAN;  } 
				|CAD 	{ $$.tipo = STRING;   } 
				|CHAR 	{ $$.tipo = CHARACTER;} 
				|LISTA 	{ $$.tipo = LIST; 	  }
				|NOM	{ $$.tipo = CUSTOM;   }
				;


//*************************************************************
//*************************************************************
//Definición de Variables
vars: 			VAR decl_vars
				;

decl_vars: 		 decl_vars decl_var PTOCOMA 
				|decl_var PTOCOMA
				;

decl_var: 		nombre_dv PTOS tipo { table_update_unassigned_types(ts, $3.tipo); }
				;
nombre_dv: 		nombre_dv COMA NOM 	{ push_to_table(table_entry_new_variable($3.lexema, UNASSIGNED, yylineno));	}
				|NOM 				{ push_to_table(table_entry_new_variable($1.lexema, UNASSIGNED, yylineno));	}
				;


//*************************************************************
//*************************************************************
//Definición de función

funcs:			funcs func
				|func
				;

func:			func_header func_content
				|func_header func_dec func_content
				;

func_dec:		vars func_nested
				|vars
				|func_nested
				;

func_nested: 	func
				|func_nested
				;

func_header: 	FUNC NOM PIZ params PDE PTOS tipo COMA
				{ 
					int i = $4.entero;  
					table tsf1 = table_new(), tsf2 = table_new();
					while((i--) > 0)  
					{
						table_entry e = table_pop(ts);
						table_push(tsf1, e);
						table_push(tsf2, e);
					}

					push_to_table(table_entry_new_function($2.lexema, $4.entero, $7.tipo, yylineno));	

					// push the function parameters again 
					while(!table_empty(tsf1)) table_push(ts, table_pop(tsf1));
					
					table_push(ts, table_entry_new_mark(yylineno)); 

					// In case we don't want to allow variables called like the function within the function scope or 
					// nested functions named in the same way, uncomment this line.
					// We would then allow recursive calls to the function from the inside.
					// table_push(ts, table_entry_new_function($2.lexema, $4.entero, $7.tipo, yylineno));

					// the function params are entered in the table as variables
					while(!table_empty(tsf2))
					{
						// we don't do any checks here since we check for it while adding the parameters
						table_push(ts, table_entry_as_variable(table_pop(tsf2)) ); 
					}
					table_destroy(&tsf1);
					table_destroy(&tsf2);							
				}
				|FUNC NOM PTOS tipo
				{
					push_to_table(table_entry_new_function($2.lexema, 0, $4.tipo, yylineno));
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

params:			params COMA param 
				{ 
					$$.entero = $1.entero + 1; 
				} 
				|param 				
				{ 
					$$.entero = 1; 
				}
				;

param: 			NOM PTOS tipo 
				{ 
					push_to_table(table_entry_new_parameter($1.lexema, $3.tipo, yylineno)); 
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

asignacion: 	NOM ASIG expr
				{
					table_entry entry = table_find_by_name(ts, $1.lexema);
					if(table_entry_valid(entry))
					{
						$$.tipo = check_data_types_operation(entry.data_type, $3.tipo);
					}
					else 
					{
						$$.tipo = UNKNOWN;
						sprintf(msg, "'%s' not defined", $1.lexema);
						yyerror(msg);
					}
				}
				;

entrada: 		LEE NOM
				;

salida: 		ESC PIZ e_salidas PDE
				;

e_salidas: 		e_salidas COMA e_salida 
				|e_salida
				;

e_salida: 		CADTEXTO		
				|expr 
				;

expr :	 		 expr SUM expr 	 
				{ 
					if($1.tipo == LIST)
					{
						$$.tipo = $1.tipo;
						if($3.tipo != LIST)
						{
							$$.tipo = UNKNOWN;
							sprintf(msg, "%s", $1.tipo == LIST ? $3.lexema : $1.lexema );
							sprintf(msg, "%s Expected: %s Got: %s",msg, data_type_name(LIST), 
								data_type_name($1.tipo == LIST ? $3.tipo : $1.tipo));
							yyerror(msg);
						}
					}
					else
					{
						type_data at[2] = {INTEGER, REAL}; 
						$$.tipo = check_data_types($1.tipo, $3.tipo, at, 2, $1.tipo);
					}   
				}
				|expr REST expr  
				{ 
					if($1.tipo == LIST)
					{
						$$.tipo = $1.tipo;
						if($3.tipo != LIST)
						{
							$$.tipo = UNKNOWN;
							sprintf(msg, "%s", $1.tipo == LIST ? $3.lexema : $1.lexema );
							sprintf(msg, "%s Expected: %s Got: %s",msg, data_type_name(LIST), 
								data_type_name($1.tipo == LIST ? $3.tipo : $1.tipo));
							yyerror(msg);
						}
					}
					else
					{
						type_data at[2] = {INTEGER, REAL}; 
						$$.tipo = check_data_types($1.tipo, $3.tipo, at, 2, $1.tipo);
					}     
				}

				|expr MULT expr  { type_data at[2] = {INTEGER, REAL}; $$.tipo = check_data_types($1.tipo, $3.tipo, at, 2, $1.tipo); }
				|expr DIV expr 	 { type_data at[2] = {INTEGER, REAL}; $$.tipo = check_data_types($1.tipo, $3.tipo, at, 2, $1.tipo); }

				|expr Y expr 	 
				{ 
					if($1.tipo == $3.tipo == BOOLEAN) 
					{
						$$.tipo = BOOLEAN; 
					}
					else 
					{ 
						$$.tipo = UNKNOWN; 
						type_data d = $1.tipo != BOOLEAN ? $1.tipo : $3.tipo;
						sprintf(msg,"In 'Y' expression, both operands expected to be %s. Got: %s", 
							data_type_name(BOOLEAN), data_type_name(BOOLEAN), data_type_name(d)); 
						yyerror(msg); 					
					}  
				}
				|expr O expr
				{ 
					if($1.tipo == $3.tipo == BOOLEAN) 
					{
						$$.tipo = BOOLEAN; 
					}
					else 
					{ 
						$$.tipo = UNKNOWN; 
						type_data d = $1.tipo != BOOLEAN ? $1.tipo : $3.tipo;
						sprintf(msg,"In 'O' expression, both operands expected to be %s. Got: %s", 
							data_type_name(BOOLEAN), data_type_name(BOOLEAN), data_type_name(d)); 
						yyerror(msg);
					}  
				}
				|get_item_lista		  	{ $$.tipo = $1.tipo; }
				|add_item_lista		  	{ $$.tipo = $1.tipo; }
				|inclusion_item_lista 	{ $$.tipo = $1.tipo; }
				|esta_vacia_lista		{ $$.tipo = $1.tipo; }
				|expr MAYIG expr { type_data at[2] = {INTEGER, REAL}; $$.tipo = check_data_types($1.tipo, $3.tipo, at, 2, BOOLEAN);} 
				|expr MENIG expr { type_data at[2] = {INTEGER, REAL}; $$.tipo = check_data_types($1.tipo, $3.tipo, at, 2, BOOLEAN);}
				|expr MAY expr 	 { type_data at[2] = {INTEGER, REAL}; $$.tipo = check_data_types($1.tipo, $3.tipo, at, 2, BOOLEAN);} 	 
				|expr MEN expr 	 { type_data at[2] = {INTEGER, REAL}; $$.tipo = check_data_types($1.tipo, $3.tipo, at, 2, BOOLEAN);}
				|expr DIST expr  
				{ 
					if($1.tipo == LIST)
					{
						$$.tipo = BOOLEAN;
						if($3.tipo != LIST)
						{
							$$.tipo = UNKNOWN;
							sprintf(msg, "%s", $1.tipo == LIST ? $3.lexema : $1.lexema );
							sprintf(msg, "%s Expected: %s Got: %s",msg, data_type_name(LIST), 
								data_type_name($1.tipo == LIST ? $3.tipo : $1.tipo));
							yyerror(msg);
						}
					}
					else
					{
						type_data at[2] = {INTEGER, REAL}; 
						$$.tipo = check_data_types($1.tipo, $3.tipo, at, 2, BOOLEAN);
					} 
				}
				|expr IGUAL expr 
				{ 
					if($1.tipo != LIST)
					{
						type_data at[2] = {INTEGER, REAL}; 
						$$.tipo = check_data_types($1.tipo, $3.tipo, at, 2, BOOLEAN);
					}
					else
					{
						$$.tipo = BOOLEAN;
						if($3.tipo != LIST)
						{
							$$.tipo = UNKNOWN;
							sprintf(msg, "%s", $1.tipo == LIST ? $3.lexema : $1.lexema );
							sprintf(msg, "%s Expected: %s Got: %s",msg, data_type_name(LIST), 
								data_type_name($1.tipo == LIST ? $3.tipo : $1.tipo));
							yyerror(msg);
						}
					}  
				}
				
				|REST expr %prec UMENOS 
				{ 
					type_data at[2] = {INTEGER, REAL}; 
					$$.tipo = check_data_types($2.tipo, $2.tipo, at, 2, $2.tipo);
				}

				|SUM expr %prec UMAS 	
				{ 
					type_data at[2] = {INTEGER, REAL}; 
					$$.tipo = check_data_types($2.tipo, $2.tipo, at, 2, $2.tipo);
				}
				
				|NO expr 		
				{ 
					if($1.tipo == BOOLEAN)
					{
						$$.tipo = BOOLEAN; 
					}
					else 
					{ 
						$$.tipo = UNKNOWN; 
						sprintf(msg, "Expected: %s Got: %s", data_type_name(BOOLEAN), data_type_name($1.tipo)); 
						yyerror(msg);
					}  
				}
				
				|VERD				  	{ $$.tipo = BOOLEAN; }
				|FALSO				  	{ $$.tipo = BOOLEAN; }
				|llamada_funcion		{ $$.tipo = $1.tipo; }
				|PIZ expr PDE 			{ $$.tipo = $2.tipo; }
				|NUM					{ $$.tipo = INTEGER; }
				|NOMCONS				
				{ 
					table_entry const_entry = table_entry_new_constant($1.lexema, CONSTANT, 0);
					int index_const = table_find(ts, const_entry);
					if(index_const < 0)
					{
						$$.tipo = UNKNOWN;
						sprintf(msg,"Constant '%s' undefined",$1.lexema);
						yyerror(msg);
					}
					else
					{
						$$.tipo = table_get(ts, index_const).data_type;
					}	 
				}
				|busca_c 
				|extrae_c
				|concat_c
				|long_c
				; 

llamada_funcion: NOM PIZ exprs PDE
				{
					table_entry entry = table_find_by_name(ts, $1.lexema);
					table_entry fentry = table_entry_new_function($1.lexema, $3.entero, entry.data_type, 0);
					$$.tipo = check_function_entries(entry, fentry);

				}
				|NOM
				{
					table_entry entry = table_find_by_name(ts, $1.lexema);
					
					if(table_entry_valid(entry))
					{
						if(entry.entry_type == FUNCTION)
						{
							table_entry fentry = table_entry_new_function($1.lexema, 0, entry.data_type, 0);
							$$.tipo = check_function_entries(entry, fentry);
						}
						else
						{
							$$.tipo = entry.data_type;
						}
					}
					else
					{
						sprintf(msg,"Undefined reference to function '%s'", $1.lexema);
						yyerror(msg);
						$$.tipo = UNKNOWN;
					}
				}	
				;

exprs: 			exprs COMA expr
				{
					$$.entero = $1.entero + 1;
					table_push(ts_parameters, table_entry_new_parameter($3.lexema, $3.tipo, yylineno));
				}
				|expr 
				{
					$$.entero = 1;
					table_push(ts_parameters, table_entry_new_parameter($1.lexema, $1.tipo, yylineno));
				}
				;

//*************************************************************
//*************************************************************
//Bucle REPEAT UNTIL
bucle: 			REPIT sents HASTA expr 
				{
					$$.tipo = $4.tipo;
					if($4.tipo != BOOLEAN)
					{
						$$.tipo = UNKNOWN;
						sprintf(msg,"In 'REPITE' declaration. Expected: %s Got: '%s'", 
							data_type_name(BOOLEAN), data_type_name($4.tipo));
						yyerror(msg);
					}	
				}
				|REPIT HASTA expr
				{
					$$.tipo = $3.tipo;
					if($3.tipo != BOOLEAN)
					{
						$$.tipo = UNKNOWN;
						sprintf(msg,"In 'REPITE' declaration. Expected: %s Got: '%s'", 
							data_type_name(BOOLEAN), data_type_name($3.tipo));
						yyerror(msg);
					}
				}
				;


//*************************************************************
//*************************************************************
//Sentencia condicional
condicion: 		SI expr ENTONC bloque_c 
				{
					$$.tipo = $2.tipo;
					if($2.tipo != BOOLEAN)
					{
						$$.tipo = UNKNOWN;
						sprintf(msg,"In 'SI' declaration. Expected: %s Got: %s", 
							data_type_name(BOOLEAN), data_type_name($2.tipo));
						yyerror(msg);
					}
				}
				|SI expr ENTONC bloque_c SINO bloque_c 
				{
					$$.tipo = $2.tipo;
					if( $2.tipo != BOOLEAN )
					{
						$$.tipo = UNKNOWN;
						sprintf(msg,"In 'SI' declaration. Expected: %s Got: %s", 
							data_type_name(BOOLEAN), data_type_name($2.tipo));
						yyerror(msg);
					}
				}
				;

bloque_c: 		sent
				|INIC sents FIN
				;


//*************************************************************
//*************************************************************
//#####Operaciones asociadas al TDA Lista de enteros

//Recupera un elemento de la lista: variable_lista[entero_indice]
get_item_lista: 		expr BRACKIZ expr BRACKDE
						{
							$$.tipo = INTEGER;
							if($1.tipo != LIST)
							{
								$$.tipo = UNKNOWN;
								sprintf(msg, "In list operand []. Expected: %s Got: %s", 
									data_type_name(LIST), data_type_name($1.tipo));
								yyerror(msg);
							}
							if($3.tipo != INTEGER)
							{
								$$.tipo = UNKNOWN;
								sprintf(msg, "In list operand [] wrong index type. Expected: %s Got: %s", 
									data_type_name(INTEGER), data_type_name($3.tipo));
								yyerror(msg);		
							}		
						}
						;

//Añadir un elemento a la lista: variable_lista << elemento
add_item_lista: 		expr DMEN expr
						{
							$$.tipo = LIST;
							if($1.tipo != LIST)
							{
								$$.tipo = UNKNOWN;
								sprintf(msg, "In list << operand. Expected: %s Got: %s", 
									data_type_name(LIST), data_type_name($1.tipo));
								yyerror(msg);
							}
							if($3.tipo != INTEGER || $3.tipo != LIST)
							{
								$$.tipo = UNKNOWN;
								sprintf(msg, "In list << second operand. Expected: %s, %s Got: %s", 
									data_type_name(INTEGER), data_type_name(LIST), data_type_name($3.tipo));
								yyerror(msg);
							}
						}
						;

//Inclusion en lista: variable_lista?variable_elemento
inclusion_item_lista: 	expr QMARK PIZ expr PDE
						{
							$$.tipo = BOOLEAN;
							if($1.tipo != LIST)
							{
								$$.tipo = UNKNOWN;
								sprintf(msg, "In list operand ? (inclusion). Expected: %s Got: %s", 
									data_type_name(LIST), data_type_name($1.tipo));
								yyerror(msg);
							}
							if($4.tipo != INTEGER)
							{
								$$.tipo = UNKNOWN;
								sprintf(msg, "In list ? (inclusion) second operand. Expected: %s Got: %s", 
									data_type_name(INTEGER), data_type_name($4.tipo));
								yyerror(msg);
							}
						}

esta_vacia_lista: 		expr QMARK
						{
							$$.tipo = BOOLEAN;
							if($1.tipo != LIST)
							{
								$$.tipo = UNKNOWN;
								sprintf(msg, "In list operand ? (empty list?) Expected: %s Got: %s", 
									data_type_name(LIST), data_type_name($1.tipo));
								yyerror(msg);
							}
						}

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
