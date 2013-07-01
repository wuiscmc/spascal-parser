#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "symbols_table/table.h"

//#define DISPLAY_TABLE_AFTER_PUSH

/******************************************************************************************************************************/
/******************************************************************************************************************************/
/******************************************************************************************************************************/
/******************************************************************************************************************************/
char msg[1000];
/**
* Adds a symbol to the table. Displays error message in case of duplicity within the symbol scope.
* params: 
* 	e - table_entry, is the symbol being pushed
*
*/
void push_to_table(table ts, table_entry e)
{
	int index_table = table_find(ts, e);
	int index_alias = table_find(ts, table_entry_new_type_alias(e.name, ALIAS, 0));

	if( index_alias >= 0 )
	{
		sprintf(msg, "'%s' is a name of a type", e.name);
		yyerror(msg);
	}
	else if(index_table < 0)
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
	#ifdef DISPLAY_TABLE_AFTER_PUSH
		table_display(ts);
	#endif
}

//**************************************************************************************************//
// OPERATIONS HELPER METHODS
//

/**
* Checks parameters in arithmetic operations
*
*/
type_data check_arithmetic_operation(type_data tipo1, type_data tipo2, char* operation)
{
	int include_list = 0 ;
	if((tipo1 == LIST || tipo2 == LIST) && (strcmp(operation, "SUM") == 0 || strcmp(operation, "RESTA") == 0))
	{
		include_list = 1;
	}		

	if  (tipo1 == tipo2 && (tipo1 == INTEGER || tipo1 == REAL || include_list == 1) )
	{
		return tipo1;
	}
	else if ((tipo1 == INTEGER || tipo1 == REAL) && (tipo2 == INTEGER || tipo2 == REAL))
	{
		return REAL;
	}					
	else
	{		
		sprintf(msg, "%s: Incompatible types '%s' and '%s'", operation, data_type_name(tipo1), data_type_name(tipo2));
		yyerror(msg);
		return UNKNOWN;		
	}
}

/**
* Checks parameters in relational operations
*
*/
type_data check_relational_operation(type_data tipo1, type_data tipo2, char* operation)
{ 
	int skip_types = (strcmp(operation, "IGUAL") == 0 || strcmp(operation, "DIST") == 0);

	if(tipo1 == tipo2 && tipo1 != UNKNOWN)
	{		
	    if(skip_types) return BOOLEAN;
	    if(tipo1 == INTEGER || tipo1 == REAL || tipo1 == LIST) return BOOLEAN;	    

		return check_relational_operation(UNKNOWN, UNKNOWN, operation);
	}
	else if ((tipo1 == INTEGER || tipo1 == REAL) && (tipo2 == INTEGER || tipo2 == REAL))
	{
		return BOOLEAN;
	}					
	else
	{
		if(tipo1 == tipo2 == UNKNOWN) 
			sprintf(msg, "%s: Unsupported types", operation);
		else
			sprintf(msg, "%s: Incompatible types '%s' and '%s'", operation,data_type_name(tipo1), data_type_name(tipo2));
		yyerror(msg);
		return UNKNOWN;						
	}
} 



type_data check_logic_operation(type_data tipo1, type_data tipo2, char* operation)
{
	if(tipo1 == tipo2 && tipo1 == BOOLEAN) 
	{
		return BOOLEAN; 
	}
	else 
	{ 
		type_data d = tipo1 != BOOLEAN ? tipo1 : tipo2;
		sprintf(msg,"%s: Both operands expected to be %s.", operation, data_type_name(BOOLEAN)); 
		yyerror(msg);
		return UNKNOWN; 
	}  
}

type_data check_aritmetic_unitary_operation(type_data tipo, char* operacion)
{
	if (tipo == INTEGER || tipo == REAL)
	{
		return tipo;
	}					
	else
	{
		sprintf(msg, "%s: Incompatible type '%s' ", operacion, data_type_name(tipo));
		yyerror(msg);
		return UNKNOWN;
	}
}

//**************************************************************************************************//
// FUNCTION COMPARISON HELPER METHODS
//

/**
*	check_function_declaration_is_function
*
*	checks whether an entry is a function. 
*	params: 
*		function_declaration - entry found in the symbols table.
*		call_name - name of the function found in the code. 
*/
int check_function_declaration_is_function(table_entry function_declaration, char* call_name)
{
	if(function_declaration.entry_type != FUNCTION)
	{
		sprintf(msg, "%s: not a function", call_name);
		yyerror(msg);
		return 0;	
	}
	return 1;	
}

/**
*	check_function_call_number_parameters
*
*	checks the number of parameters passed in a function call. 
*	params: 
*		function_call - the function call in the code.
*		function_declaration - the function header definition from symbols table.
*/
int check_function_call_number_parameters(table_entry function_call, table_entry function_declaration)
{
	if(function_call.params != function_declaration.params)
	{
		sprintf(msg, "%s: expected %d params, received %d", function_declaration.name, function_declaration.params, function_call.params);
		yyerror(msg);
		return 0;	
	}
	return 1;						
}


/**
*	check_function_call_type_parameters
*
*	checks the type of the parameters passed in a function call. 
*	params: 
*		function_call - the function call in the code.
*		function_declaration - the function header definition from symbols table.
*		ts - the symbols table 
*		ts_parameters - symbols table used to store the parameters of the call.
*/
int check_function_call_type_parameters(table_entry function_call, table_entry function_declaration, table ts, table ts_parameters)
{
	int index = table_find(ts, function_declaration);
	int number_of_params = function_declaration.params;	
	int i = number_of_params;
	int param_index = -1;
	table_entry call_parameter;
	table_entry declaration_parameter;
	int types_are_compatible = 1;

	for(i = number_of_params; i >= 1; i--)
	{
		param_index = index + i;
		declaration_parameter = table_get(ts, param_index); // the param from the declaration (symbols table)
		call_parameter = table_pop(ts_parameters); 

		if(!table_entry_compatible_data_type(declaration_parameter.data_type, call_parameter.data_type))		
		{
			types_are_compatible = 0;
			sprintf(msg, "%s: parameter %d type missmatch, expected %s", function_declaration.name, i, 
			        data_type_name(declaration_parameter.data_type));
			yyerror(msg);			
		}
	}

	return types_are_compatible;	
}

/**
*	check_function_entries
*
*	checks whether the call of a function is correct. 
*	params: 
*		function_call - the function call in the code.
*		function_declaration - the function header definition from symbols table.
*		ts - the symbols table 
*		ts_parameters - symbols table used to store the parameters of the call.
*/
type_data check_function_entries(table_entry function_declaration, table_entry function_call, table ts, table ts_parameters)
{		
	
	if(!check_function_declaration_is_function(function_declaration, function_call.name))
	{
		return UNKNOWN;
	} 

	if(!check_function_call_number_parameters(function_call, function_declaration))
	{
		return UNKNOWN;
	}
	
	if(function_call.params == 0)
	{
		return function_call.data_type;
	}	
	else if(check_function_call_type_parameters(function_call, function_declaration, ts, ts_parameters))
	{
					
		return function_call.data_type;
	}
	else
	{
		return UNKNOWN;
	}

	
}

