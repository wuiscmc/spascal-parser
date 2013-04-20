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
        e.data_type = NEW,
        e.entry_type = UNKNOWN,
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
    
    table_entry e = table_entry_new();
    e.name = strdup(name);
    e.data_type = data_type;
    e.entry_type = FUNCTION;
    e.params = params;
    e.line = line;
    return e;
}

table_entry table_entry_new_parameter(char* name, type_data data_type, int line)
{
    table_entry e = table_entry_new();
    e.name = strdup(name);
    e.entry_type = PARAMETER;
    e.data_type = data_type;
    e.line = line;
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

int table_entry_valid(table_entry symbol)
{   
    return symbol.data_type == NEW ? 0 : 1;
}


void table_entry_display(table_entry symbol)
{
    printf("line %d: %s (%s, %s)\n", symbol.line, symbol.name, data_type_name(symbol.data_type), entry_type_name(symbol.entry_type));
}

int table_entry_begin_scope(table_entry symbol)
{
    return symbol.entry_type == MARK ? 1 : 0;
}

/* Helper methods */
char* data_type_name(type_data d)
{
    char* res; 
    switch(d){
        case BOOLEAN:    res = "boolean"; break;
        case INTEGER:    res = "integer"; break;
        case REAL:       res = "real";    break;
        case ARRAY:      res = "array";   break;
        case SET:        res = "set";     break;
        case STRING:     res = "string";  break;
        case CHARACTER:  res = "character"; break;
        case UNKNOWN:    res = "unknown"; break;
        case UNASSIGNED: res = "unassigned"; break;              
    };
    return res; 
}


char* entry_type_name(type_entry d)
{
    char* res; 
    switch(d){
        case MARK:      res = "mark"; break; 
        case PROCEDURE: res = "procedure"; break; 
        case FUNCTION:  res = "function"; break; 
        case VARIABLE:  res = "variable"; break; 
        case PARAMETER: res = "parameter"; break; 
        case RANGE:     res = "range"; break; 
        case NEW:   res = "NEW"; break; 
    };

    return res; 
}
    
