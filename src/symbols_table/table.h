//
//  table.h
//  symbols table
//
//  Created by luizcarlos on 4/15/13.
//  Copyright (c) 2013 luizcarlos. All rights reserved.
//

#ifndef TABLE_H
#define TABLE_H
#include "table_entry.h"

//#define DEBUG

typedef struct __table_* table;

table table_new();

void table_push(table t, table_entry entry);

table_entry table_pop(table p);

int table_size(table t);

int table_empty(table p);

void table_reset(table *t);

int table_find(table p, table_entry entry);

table_entry table_find_by_name(table t, char* name);

table_entry table_find_by_name_unscoped(table t, char* name);

table_entry table_find_by_name_unscoped_not_parameter(table t, char* name);

void table_display(table t);

void table_destroy(table *t);

void table_pop_scope(table t);

int table_update_unassigned_types(table t, type_data type);

int table_update_unassigned_types_with_custom(table t, char* name);

table_entry table_get(table t,int index);

#endif

