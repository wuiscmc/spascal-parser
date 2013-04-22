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
    CUSTOM,
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

typedef enum {
    TE_DIFFERENT_NAMES,
    TE_DIFFERENT_DATA,
    TE_DIFFERENT_ENTRY,
    TE_DIFFERENT_ARGS,
    TE_DIFFERENT_DIMS,
    TE_SAME_ENTRY
} table_entry_error_code;

table_entry table_entry_new();

table_entry table_entry_new_array(char* name, int dims, int min_range, int max_range, int line);

table_entry table_entry_new_mark(int line);

table_entry table_entry_new_function(char* name, int params, type_data d, int line);

table_entry table_entry_new_variable(char* name, type_data d, int line);

table_entry table_entry_new_parameter(char* name, type_data d, int line);

table_entry table_entry_as_variable(table_entry entry);

int table_entry_compatible_entry_type(table_entry entry1, table_entry entry2);

table_entry_error_code table_entry_compare(table_entry entry1, table_entry entry2);

void table_entry_change_type_data(table_entry* symbol, type_data new_type_data);

void table_entry_display(table_entry symbol);

int table_entry_valid(table_entry symbol);

int table_entry_begin_scope(table_entry symbol);

int table_entry_compatible_data_type(type_data d1, type_data d2);

char* data_type_name(type_data d);

char* entry_type_name(type_entry e);

char* table_entry_error_code_message(table_entry_error_code code);

#endif
