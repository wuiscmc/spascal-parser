//
//  table_entry.h
//  symbols table
//
//  Created by luizcarlos on 4/16/13.
//  Copyright (c) 2013 luizcarlos. All rights reserved.
//

#ifndef table_entry_h
#define table_entry_h

typedef enum {
    MARK,
    PROCEDURE,
    FUNCTION,
    VARIABLE,
    PARAMETER,
    RANGE,
    NEW
} type_entry;

typedef enum {
    BOOLEAN,
    INTEGER,
    REAL,
    ARRAY,
    SET,
    CHARACTER,
    STRING,
    UNKNOWN,
    UNASSIGNED
} type_data;

typedef struct {
    char* name;
    type_data data_type;
    type_entry entry_type;
    int params;
    int dims;
    int min_range;
    int max_range;
    int line;
} table_entry;


table_entry table_entry_new();

table_entry table_entry_new_array(char* name, int dims, int min_range, int max_range, int line);

table_entry table_entry_new_mark(int line);

table_entry table_entry_new_function(char* name, int params, type_data d, int line);

table_entry table_entry_new_variable(char* name, type_data d, int line);

table_entry table_entry_new_parameter(char* name, type_data d, int line);

void table_entry_change_type_data(table_entry* symbol, type_data new_type_data);

void table_entry_display(table_entry symbol);

int table_entry_valid(table_entry symbol);

int table_entry_begin_scope(table_entry symbol);

char* data_type_name(type_data d);

char* entry_type_name(type_entry e);

#endif
