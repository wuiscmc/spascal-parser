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
void table_push(table t,table_entry dato);
table_entry table_pop(table p);
int table_size(table t);
int table_empty(table p);
void table_display(table t);
void table_destroy(table *t);
void table_pop_scope(table t);
int table_update_unassigned_types(table t, type_data type);

#endif
