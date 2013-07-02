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

//#define DISPLAY_TABLE_FUNCTION_SCOPE
//#define LOCK_NESTED_FUNCTION_SCOPE

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
	fprintf(stderr,"Line %d => ",yylineno,"\n");
	fprintf(stderr,msg);
}

%}

/* A continuación declaramos los nombres simbólicos de los tokens, así como el símbolo inicial de la
gramática (axioma). Byacc se encarga de asociar a cada uno un código */
%start strt

%token PROG USAR CONCAT CONST TIPO FUNC INIC FIN
%token LEE ESC

// symbols 
%token VAR ASIG PDE PIZ PTOCOMA PTO COMA PTOS COMILLSIMPLE COMENT 

//if-repeat statement
%token REPIT HASTA
%token SI SINO ENTONC

// raw types 
%token NUMREAL NOM NOMCONS CADTEXTO CAD CAR
%token FALSO VERD

// types
%token LONG DREAL BOOL CHAR ENT

//Precedencia de operaciones
%token NUM	
%left SUM REST
%left MULT DIV
%left Y O 	
%left IGUAL DIST MAY MAYIG MEN MENIG	
%left NO	
%left UMENOS UMAS

//Tokens para el TDA Cadena
%token INS EXT BUSC BORR

//Tokens para el TDA Lista de enteros
%token LISTA QMARK DMEN BRACKIZ BRACKDE

%%

//*************************************************************
//*************************************************************
/* Sección de producciones que definen la gramática */

strt:			{ ts = table_new(); ts_parameters = table_new(); table_push(ts, table_entry_new_mark(yylineno)); } 
			prog
				{ table_pop_scope(ts); table_destroy(&ts); table_destroy(&ts_parameters); }
			;

prog: 		PROG NOM PTOCOMA dec1 dec2 cuerpo
			|PROG NOM PTOCOMA dec1 cuerpo
			|PROG NOM PTOCOMA dec2 cuerpo
			|PROG NOM PTOCOMA cuerpo
			;

dec1:	 	 librerias constantes def_tipos
			|librerias def_tipos
			|constantes def_tipos
			|librerias
			|constantes
			|def_tipos
			;

dec2: 		funcs vars 
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
constantes: CONST conss
			;

conss: 		conss cons
			|cons
			;

cons:		NOMCONS IGUAL val_cons PTOCOMA
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

val_cons:	VERD 		{ $$.tipo = BOOLEAN; }
			|FALSO 		{ $$.tipo = BOOLEAN; }
			|NUM 		{ $$.tipo = INTEGER; }
			|NUMREAL	{ $$.tipo = REAL; }
			|CADTEXTO	{ $$.tipo = STRING; }
			|CAR		{ $$.tipo = CHARACTER; }			


//*************************************************************
//*************************************************************
//Definicion de tipos
def_tipos: 	TIPO nombress
			;

nombress: 	nombress def_tipo
			|def_tipo
			;

def_tipo: 	NOM IGUAL tipo PTOCOMA
				{
					table_entry alias = table_entry_new_type_alias($1.lexema, $3.tipo, yylineno);
					int index_alias = table_find(ts, alias);					
					if( index_alias < 0)
					{
						if( table_entry_is_basic_data_type(data_type_name($3.tipo)))
						{
							table_push(ts, alias);
						}
						else
						{
							sprintf(msg, "Type '%s' can not be an alias of '%s' since '%s' is not a base type", alias.name, $3.lexema, $3.lexema);
							yyerror(msg);	
						}

					}
					else
					{
						table_entry e = table_get(ts, index_alias);
						sprintf(msg, "Type %s is already defined here: line %d", e.name, e.line );
						yyerror(msg);
					}
				}
			;

tipo: 			ENT 	 { $$.tipo = INTEGER;  } 
				|DREAL 	 { $$.tipo = REAL; } 
				|BOOL 	 { $$.tipo = BOOLEAN;  } 
				|CAD 	 { $$.tipo = STRING;   } 
				|CHAR 	 { $$.tipo = CHARACTER;} 				
				|LISTA 	 { $$.tipo = LIST; }
				|NOM	 { $$.tipo = ALIAS; $$.lexema = strdup($1.lexema); }   
				;


//*************************************************************
//*************************************************************
//Definición de Variables
vars: 		VAR decl_vars
			;

decl_vars: 	 decl_vars decl_var PTOCOMA 
			|decl_var PTOCOMA
			;

decl_var: 	nombre_dv PTOS tipo 
				{ 
					if(table_entry_is_basic_data_type(data_type_name($3.tipo)))
					{
						table_update_unassigned_types(ts, $3.tipo); 	
					}
					else
					{
						int index = table_update_unassigned_types_with_custom(ts, $3.lexema);
						if(index < 0)
						{
							sprintf(msg, "'%s' is not a valid data type", $3.lexema);
							yyerror(msg);
						}
					}				
				}
			;
nombre_dv: 	nombre_dv COMA NOM 	{ push_to_table(ts, table_entry_new_variable($3.lexema, UNASSIGNED, yylineno));	}
			|NOM 				{ push_to_table(ts, table_entry_new_variable($1.lexema, UNASSIGNED, yylineno));	}
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

func_dec:		vars funcs_nested
				|vars
				|VAR funcs_nested
				;

funcs_nested: 	funcs_nested func
				|func
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

						push_to_table(ts, table_entry_new_function($2.lexema, $4.entero, $7.tipo, yylineno));	

						// push the function parameters again 
						while(!table_empty(tsf1)) 
							table_push(ts, table_pop(tsf1));
						
						table_push(ts, table_entry_new_mark(yylineno)); 

						// In case we don't want to allow variables called like the function within the function scope or 
						// nested functions named in the same way, uncomment this line.
						// We would then allow recursive calls to the function from the inside.
						table_push(ts, table_entry_new_function($2.lexema, $4.entero, $7.tipo, yylineno));

						// the function params are entered in the table as variables
						while(!table_empty(tsf2))
						{
							// we don't do any checks here since we check for it while adding the parameters
							table_push(ts, table_entry_as_variable(table_pop(tsf2)) ); 
						}
						table_destroy(&tsf1);
						table_destroy(&tsf2);							
						
						#ifdef DISPLAY_TABLE_FUNCTION_SCOPE
							table_display(ts);
						#endif
					}				
				|FUNC NOM PTOS tipo
					{
						push_to_table(ts, table_entry_new_function($2.lexema, 0, $4.tipo, yylineno));
						table_push(ts, table_entry_new_mark(yylineno));
						#ifdef DISPLAY_TABLE_FUNCTION_SCOPE
							table_display(ts);
						#endif
					}
				;

func_content: 	INIC sents FIN PTOCOMA  { table_pop_scope(ts); }
				|INIC FIN PTOCOMA 		{ table_pop_scope(ts);}
				;

sents: 			sents sent PTOCOMA
				|sent PTOCOMA
				;

params:			params COMA param  	{ $$.entero = $1.entero + 1; } 
				|param 				{ $$.entero = 1; }
				;

param: 			NOM PTOS tipo 
				{ 			
					table_entry new_param = table_entry_new_parameter($1.lexema, $3.tipo, yylineno);
					if(new_param.data_type == ALIAS)
					{
						
						sprintf(msg, "'%s'  is not a valid data type", $3.lexema);
						yyerror(msg);
					}
					else{
						push_to_table(ts, new_param); 	
					}
					
				}
				;

//*************************************************************
//*************************************************************
//Definición de cuerpo y tipos de sentencia

cuerpo: 		INIC FIN PTO
				|INIC sents FIN PTO
				;

sent:	 		asignacion
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
						if($3.tipo == entry.data_type)
						{
							$$.tipo = $3.tipo;
						}
						else if(($3.tipo == REAL || entry.data_type == REAL) && ($3.tipo == INTEGER || entry.data_type == INTEGER))
						{
							$$.tipo = REAL;
						}
						else
						{							
							$$.tipo = UNKNOWN;
							sprintf(msg, "Incompatible types in assignment statement of '%s'", $1.lexema);
							yyerror(msg);
						}					    	
					}
					else 
					{
						$$.tipo = UNKNOWN;
						sprintf(msg, "'%s' not defined", $1.lexema);
						yyerror(msg);
					}
				}
				;

//*************************************************************
//*************************************************************
// Entrada y salida 
entrada: 	LEE NOM
			;

salida: 	ESC PIZ e_salidas PDE
			;

e_salidas: 	e_salidas COMA e_salida 
			|e_salida
			;

e_salida: 	expr 
			;

//*************************************************************
//*************************************************************
// EXPRESIONES				
expr :	 	PIZ expr PDE { $$.tipo = $2.tipo; }

//*************************
// operaciones relacionales		
			|expr IGUAL expr { $$.tipo = check_relational_operation($1.tipo, $3.tipo, "IGUAL"); }
			|expr DIST expr  { $$.tipo = check_relational_operation($1.tipo, $3.tipo, "DIST");  }				
			|expr MAY expr 	 { $$.tipo = check_relational_operation($1.tipo, $3.tipo, "MAY");   } 
			|expr MAYIG expr { $$.tipo = check_relational_operation($1.tipo, $3.tipo, "MAYIG"); } 			
			|expr MEN expr 	 { $$.tipo = check_relational_operation($1.tipo, $3.tipo, "MEN");	}  
			|expr MENIG expr { $$.tipo = check_relational_operation($1.tipo, $3.tipo, "MENIG"); } 				

//*************************
// operaciones aritmeticas		
			|expr SUM expr 	 { $$.tipo = check_arithmetic_operation($1.tipo, $3.tipo, "SUM"); 	}		
			|expr REST expr  { $$.tipo = check_arithmetic_operation($1.tipo, $3.tipo, "RESTA"); }		
			|expr MULT expr  { $$.tipo = check_arithmetic_operation($1.tipo, $3.tipo, "MULT"); 	}
			|expr DIV expr 	 { $$.tipo = check_arithmetic_operation($1.tipo, $3.tipo, "DIV"); 	}

//*************************
// operaciones logicas
			|expr Y expr 	{ $$.tipo = check_logic_operation($1.tipo, $3.tipo, "Y"); }
			|expr O expr 	{ $$.tipo = check_logic_operation($1.tipo, $3.tipo, "O"); }
			|NO expr 		{ $$.tipo = check_logic_operation($2.tipo, BOOLEAN, "NO");}

//*************************
// operaciones aritmeticas unitarias
			|REST expr %prec UMENOS { $$.tipo = check_aritmetic_unitary_operation($2.tipo, "-"); }													
			|SUM expr %prec UMAS 	{ $$.tipo = check_aritmetic_unitary_operation($2.tipo, "+"); }



//*************************
// misc
			|llamada_funcion	{ $$.tipo = $1.tipo; }
			|VERD			  	{ $$.tipo = BOOLEAN; }
			|FALSO				{ $$.tipo = BOOLEAN; }			
			|NUM				{ $$.tipo = INTEGER; }
			|NUMREAL			{ $$.tipo = REAL; }
			|CAR				{ $$.tipo = CHARACTER; }
			|CADTEXTO			{ $$.tipo = STRING; }
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

//*************************
// lista
			|get_item_lista		  	{ $$.tipo = $1.tipo; }
			|add_item_lista		  	{ $$.tipo = $1.tipo; }
			|inclusion_item_lista 	{ $$.tipo = $1.tipo; }
			|esta_vacia_lista		{ $$.tipo = $1.tipo; }

//*************************
// cadena
			|busca_c 
			|extrae_c
			|concat_c
			|long_c
			; 

// ******************************************************
// ******************************************************
// Llamada de funcion				
llamada_funcion: NOM PIZ exprs PDE
					{													
						table_entry function_declaration = table_find_by_name_unscoped(ts, $1.lexema);											
						table_entry function_call = table_entry_new_function($1.lexema, $3.entero, function_declaration.data_type, 0);
						$$.tipo = check_function_entries(function_declaration, function_call, ts, ts_parameters);
						table_reset(&ts_parameters);
					}
				|NOM PIZ PDE
					{												
						table_entry function_declaration = table_find_by_name_unscoped(ts, $1.lexema);											
						table_entry function_call = table_entry_new_function($1.lexema, 0, function_declaration.data_type, 0);
						$$.tipo = check_function_entries(function_declaration, function_call, ts, ts_parameters);
						table_reset(&ts_parameters);
					}
				|NOM
					{											
						table_entry entry = table_find_by_name_unscoped_not_parameter(ts, $1.lexema);
						if(table_entry_valid(entry))
						{
							if(entry.entry_type == FUNCTION)
							{
								table_entry fentry = table_entry_new_function($1.lexema, 0, entry.data_type, 0);
								$$.tipo = check_function_entries(entry, fentry, ts, ts_parameters);
								table_reset(&ts_parameters);
							}
							else
							{
								$$.tipo = entry.data_type;
							}
						}
						else
						{
							sprintf(msg,"Undeclared '%s'", $1.lexema);
							yyerror(msg);
							$$.tipo = UNKNOWN;
						}
					}	
				;

exprs: 			exprs COMA expr { $$.entero = $1.entero + 1; table_push(ts_parameters, table_entry_new_parameter($3.lexema, $3.tipo, yylineno)); }
				|expr 			{ $$.entero = 1; table_push(ts_parameters, table_entry_new_parameter($1.lexema, $1.tipo, yylineno)); }
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
							sprintf(msg,"In 'REPITE' declaration. Expected: %s", 
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
							sprintf(msg,"In 'REPITE' declaration. Expected: %s", 
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
						if($2.tipo != BOOLEAN )
						{
							$$.tipo = UNKNOWN;
							sprintf(msg,"In 'SI' declaration. Expected: %s", 
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
							sprintf(msg,"In 'SI' declaration. Expected: %s", 
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
									sprintf(msg, "In list operand []. Expected: %s", 
										data_type_name(LIST), data_type_name($1.tipo));
									yyerror(msg);
								}
								if($3.tipo != INTEGER)
								{
									$$.tipo = UNKNOWN;
									sprintf(msg, "In list operand [] wrong index type. Expected: %s", 
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
									sprintf(msg, "In list << operand. Expected: %s", 
										data_type_name(LIST), data_type_name($1.tipo));
									yyerror(msg);
								}
								if($3.tipo != INTEGER && $3.tipo != LIST)
								{
									$$.tipo = UNKNOWN;
									sprintf(msg, "In list << second operand. Expected: %s, %s", 
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
									sprintf(msg, "In list operand ? (inclusion). Expected: %s", 
										data_type_name(LIST), data_type_name($1.tipo));
									yyerror(msg);
								}
								if($4.tipo != INTEGER)
								{
									$$.tipo = UNKNOWN;
									sprintf(msg, "In list ? (inclusion) second operand. Expected: %s", 
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
									sprintf(msg, "In list operand ? (empty list?) Expected: %s", 
										data_type_name(LIST), data_type_name($1.tipo));
									yyerror(msg);
								}
							}

//*************************************************************
//*************************************************************
//#####Operaciones asociadas al TDA Cadena

//Inserta una subcadena en una cadena a partir de una posicion  inserta(cadena,subcadena,pos)
insertar_c: 	INS PIZ param_cadena COMA param_cadena COMA expr PDE { $$.tipo = $3.tipo == $5.tipo && $3.tipo == STRING && $7.tipo == INTEGER ? STRING : UNKNOWN; }
				;

//Borra a partir de una posicion P, N caracteres borra("pepe",2,1);
borrar_c: 		BORR PIZ param_cadena COMA expr COMA expr PDE { $$.tipo = $3.tipo == STRING && $5.tipo == $7.tipo && $7.tipo == INTEGER ? STRING : UNKNOWN;}
				;

//Buscar en una cadena, una subcadena
busca_c: 		BUSC PIZ param_cadena COMA param_cadena PDE { $$.tipo = $3.tipo == $5.tipo && $5.tipo == STRING ? BOOLEAN : UNKNOWN;}
				;

//Extrae N caracteres desde la posicion P en la cadena C extrae(C,N,P)
extrae_c: 		EXT PIZ param_cadena COMA expr COMA expr PDE { $$.tipo = $3.tipo == STRING && $5.tipo == $7.tipo == INTEGER ? STRING : UNKNOWN;}				
				; 

//Concatena dos cadenas
concat_c: 		CONCAT PIZ param_cadena COMA param_cadena PDE { $$.tipo = $3.tipo == $5.tipo && $5.tipo == STRING ? STRING : UNKNOWN; }				
				;

//Devuelve la longitud de la cadena
long_c: 		LONG PIZ param_cadena PDE { $$.tipo = $3.tipo == STRING ? INTEGER : UNKNOWN; }
				;

//Definición de los parámetros que se aceptarán
param_cadena:  	llamada_funcion { $$.tipo = $1.tipo; }
				|concat_c		{ $$.tipo = $1.tipo; }
				|extrae_c		{ $$.tipo = $1.tipo; }
				|CADTEXTO		{ $$.tipo = STRING; }
				;
%%

/* Aquí incluimos el fichero generado por el Flex, que implementa la función yylex() */
#include "lexyy.c"
