//
//  table.c
//  symbols table
//
//  Created by luizcarlos on 4/15/13.
//  Copyright (c) 2013 luizcarlos. All rights reserved.
//
#include <stdlib.h>
#include <stdio.h>
#include "table.h"

struct __table_
{
    table_entry entries[1000];
    int size;
};

//
//  Creates a new instance of the table
//
table table_new()
{
	table t = (table) malloc(sizeof(struct __table_));
	t->size = 0;
	return t;
}


void table_push(table t, table_entry e)
{
    t->entries[t->size] = e;
    t->size++;
}

//
//  Returns the first element of the stack and removes it from the table
//
table_entry table_pop(table t)
{
    t->size--;
    return t->entries[t->size];
}

int table_size(table t)
{
    return t->size;
}

int table_empty(table t)
{
    return t->size == 0;
}

//
//  Finds an entry in the table and returns a copy, otherwise returns a dummy(NEW) symbol
//
table_entry table_find(table t, char* id)
{
    int i = 0;
    table_entry entry = table_entry_new();
    for(i = t->size; table_empty(t) || t->entries[i].entry_type != MARK; i--)
    {
        if(strcmp(t->entries[i].name, id) == 0)
        {
            entry = t->entries[i];
        }
    }
    return entry;
}

table_entry table_top(table t)
{
    return t->entries[t->size-1];
}

//
//  Updates the data types of those symbols with UNASSIGNED type
//
int table_update_unassigned_types(table t, type_data type)
{
    int i = 1;
    while(t->entries[t->size - i].data_type == UNASSIGNED)
    {
        t->entries[t->size - i].data_type = type;
        i++;
    }
    return i;
}

void table_pop_scope(table t)
{
    while(table_top(t).entry_type != MARK) table_pop(t); //removing the scope elements
    table_pop(t); //to remove the begin of scope mark 
}


void table_destroy(table *t)
{
    free(*t);
    t = NULL;
}

//
//  It just displays the table
//
void table_display(table t)
{
    table_entry entry;
    int i;
    printf("SIZE: %d\n", t->size);
    for(i = 0; i < t->size; i++)
        table_entry_display(t->entries[i]);
    
    printf("\n");
}
