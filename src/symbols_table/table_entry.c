//
//  table_entry.c
//  symbols table
//
//  Created by luizcarlos on 4/16/13.
//  Copyright (c) 2013 luizcarlos. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "table_entry.h"


table_entry table_entry_new()
{
    table_entry e = {
        e.name = NULL,
        e.data_type = UNKNOWN,
        e.entry_type = NEW,
        e.params = -1,
        e.dims = -1,
        e.min_range = -1,
        e.max_range = -1,
        e.line = -1
    };
    return e;
}

table_entry table_entry_new_variable(char* name, type_data data_type, int line)
{
    table_entry e = table_entry_new();
    e.name = strdup(name);
    e.data_type = data_type;
    e.entry_type = VARIABLE;
    e.line = line;
    return e;
}

table_entry table_entry_new_function(char* name, int params, type_data data_type, int line)
{
    table_entry e = table_entry_new_variable(name, data_type, line);
    e.entry_type = FUNCTION;
    e.params = params;
    return e;
}

table_entry table_entry_new_parameter(char* name, type_data data_type, int line)
{
    table_entry e = table_entry_new_variable(name, data_type, line);
    e.entry_type = PARAMETER;
    return e;
} 

table_entry table_entry_new_constant(char*name, type_data data_type, int line)
{
    table_entry e = table_entry_new_variable(name, data_type, line);
    e.entry_type = CONSTANT;
    return e;
}

table_entry table_entry_new_type_alias(char* name, type_data data_type, int line)
{
    table_entry e = table_entry_new_variable(name, data_type, line);
    e.entry_type = CUSTOM;
    return e;
}

table_entry table_entry_new_type(char* name, char* data_type_name)
{
    table_entry e = table_entry_new();
    e.name = strdup(data_type_name);
    e.entry_type = CUSTOM;
    e.data_type = CUSTOM;
    return e;
} 

table_entry table_entry_new_mark(int line)
{
    table_entry e = table_entry_new();
    e.name = "$MARK$";
    e.entry_type = MARK;
    e.line = line;
    return e;
}


table_entry table_entry_new_array(char* name, int dims, int min_range, int max_range, int line)
{
    table_entry e = table_entry_new();
    e.name = strdup(name);
    e.data_type = ARRAY;
    e.entry_type = VARIABLE;
    e.dims = dims;
    e.min_range = min_range;
    e.max_range = max_range;
    e.line = line;
    return e;
}

int table_entry_compatible_entry_type(table_entry entry1, table_entry entry2)
{
    int equals = 0;
    if( (entry1.entry_type == entry2.entry_type) 
        || !((entry1.entry_type == PARAMETER || entry2.entry_type == PARAMETER) && 
        (entry1.entry_type != PARAMETER || entry2.entry_type != PARAMETER))
    )
    {
        if(strcmp(entry1.name, entry2.name) == 0)
        {
            equals = 1;
        }
    }
    return equals;
}

table_entry table_entry_as_variable(table_entry entry)
{
    entry.entry_type = VARIABLE;
    return entry;
}


int table_entry_valid(table_entry symbol)
{   
    return symbol.data_type == UNKNOWN ? 0 : 1;
}


void table_entry_display(table_entry symbol)
{
    printf("line %d: %s (%s, %s)\n", symbol.line, symbol.name, data_type_name(symbol.data_type), entry_type_name(symbol.entry_type));
}

int table_entry_begin_scope(table_entry symbol)
{
    return symbol.entry_type == MARK ? 1 : 0;
}

int table_entry_is_basic_data_type(char* name)
{
    
    if ( strcmp(data_type_name(INTEGER)  , name) == 0 ) return 1;
    if ( strcmp(data_type_name(REAL)     , name) == 0 ) return 1;     
    if ( strcmp(data_type_name(BOOLEAN)  , name) == 0 ) return 1;
    if ( strcmp(data_type_name(STRING)   , name) == 0 ) return 1; 
    if ( strcmp(data_type_name(CHARACTER), name) == 0 ) return 1;
    if ( strcmp(data_type_name(LIST)     , name) == 0 ) return 1;


    return 0;
}

table_entry_error_code table_entry_compare(table_entry entry1, table_entry entry2)
{
    
    if(strcmp(entry1.name, entry2.name) != 0)
    {
        return TE_DIFFERENT_NAMES;
    }
    
    if(entry1.entry_type != entry2.entry_type)
    {
     //   printf("%s VS %s\n", entry_type_name(entry1.entry_type), entry_type_name(entry2.entry_type));
        return TE_DIFFERENT_ENTRY;
    }

    if(entry1.data_type != entry2.data_type)
    {

    //    printf("%s VS %s\n", data_type_name(entry1.data_type), data_type_name(entry2.data_type));
        return TE_DIFFERENT_DATA;
    }

    if(entry1.params != entry2.params)
    {
        return TE_DIFFERENT_ARGS;
    }
    
    if(entry1.dims != entry2.dims)
    {
        return TE_DIFFERENT_DIMS;
    }

    return TE_SAME_ENTRY;
}

int table_entry_compatible_data_type(type_data d1, type_data d2)
{
    if((d1 == d2) || ((d1 == REAL || d2 == REAL) && (d1 == INTEGER || d2 == INTEGER)) )
    {
        return 1;
    }
    else
    {
        return 0;
    }
}


/* Helper methods */
char* data_type_name(type_data d)
{
    char* res; 
    switch(d){
        case BOOLEAN:    res = "booleano";    break;
        case INTEGER:    res = "entero";      break;
        case REAL:       res = "real";        break;
        case ARRAY:      res = "array";       break;
        case SET:        res = "conjunto";    break;
        case STRING:     res = "cadena";      break;
        case LIST:       res = "lista";       break;
        case CHARACTER:  res = "caracter";    break;
        case UNKNOWN:    res = "desconocido"; break;
        case UNASSIGNED: res = "no asignado"; break;
        case ALIAS:      res = "alias"; break;              
    };
    return res; 
}


char* entry_type_name(type_entry d)
{
    char* res; 
    switch(d){
        case MARK:      res = "marca";        break; 
        case PROCEDURE: res = "procedimiento";break; 
        case FUNCTION:  res = "funcion";      break; 
        case VARIABLE:  res = "variable";     break; 
        case PARAMETER: res = "parametro";    break; 
        case RANGE:     res = "rango";        break; 
        case CONSTANT:  res = "constante";    break;
        case NEW:       res = "nuevo";        break; 
        case CUSTOM:    res = "personalizado";break;
    };

    return res; 
}
    


char* table_entry_error_code_message(table_entry_error_code code)
{
    char* res; 
    switch(code){
        case TE_DIFFERENT_NAMES: res = "different names"; break;
        case TE_DIFFERENT_DATA:  res = "different type data"; break;
        case TE_DIFFERENT_ENTRY: res = "different entry"; break;
        case TE_DIFFERENT_ARGS:  res = "different number of arguments"; break;
        case TE_DIFFERENT_DIMS:  res = "different dimensions"; break; 
        case TE_SAME_ENTRY:      res = "same entry"; break;
    };

    return res; 
}