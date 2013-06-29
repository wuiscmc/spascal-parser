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
//  Finds an entry in the table and returns its index in the table, otherwise returns -1
//
int table_find(table t, table_entry entry)
{
    int index;

    switch(entry.entry_type)
    {
        case CUSTOM:
            index = table_find_custom(t, entry.name);break;
        case CONSTANT: 
            index = table_find_constant(t, entry);   break;
        default: 
            index = table_find_symbol(t, entry);
    }

    return index;
}

table_entry table_find_by_name(table t, char* name)
{
    int i = t->size-1, index = -1;
    table_entry e = table_entry_new();
    
    while(t->entries[i].entry_type != MARK)
    {        
        if(strcmp(t->entries[i].name, name) == 0 ) 
        {
            e = t->entries[i];            
            break;
        }
        i--;
    }  
    return e; 
}

table_entry table_find_by_name_unscoped(table t, char* name)
{
    int i = t->size-1, index = -1;
    table_entry e = table_entry_new();
    while(i>0)
    {        
        if(strcmp(t->entries[i].name, name) == 0 ) 
        {
            e = t->entries[i];            
            break;
        }
        i--;
    }  
    return e; 
}

table_entry table_find_by_name_unscoped_not_parameter(table t, char* name)
{
    int i = t->size-1, index = -1;
    table_entry e = table_entry_new();
    while(i>0)
    {        
        if(strcmp(t->entries[i].name, name) == 0 && t->entries[i].entry_type != PARAMETER ) 
        {
            e = t->entries[i];            
            break;
        }
        i--;
    }  
    return e; 
}

table_entry table_get(table t, int index)
{
    return t->entries[index];
}
table_entry table_top(table t)
{
    return t->entries[t->size-1];
}


int table_update_unassigned_types_with_custom(table t, char* name)
{
    
    table_entry tmp = table_entry_new_type_alias(name, ALIAS, 0);

    int index = table_find(t, tmp);
    if(index < 0)
    {
        return index;
    }
    else
    {
        return table_update_unassigned_types(t, table_get(t, index).data_type);
    }
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
    while(table_top(t).entry_type != MARK)table_pop(t); //removing the scope elements
    table_pop(t); //to remove the begin of scope mark 
}


void table_reset(table *t)
{
    table_destroy(t);
    *t = table_new();
}

void table_destroy(table *t)
{
    (*t)->size = 0;    
    free(*t);
    t = NULL;
}

//
//  It just displays the table
//
void table_display(table t)
{
    int i;
    for(i = 0; i < t->size; i++)
    {
        table_entry_display(t->entries[i]);
    }
    
    printf("\n");
}

// HELPERS

int table_find_custom(table t, char* entry_name)
{
    int i = t->size -1, index = -1;
    while(i>=0)
    {
        if(t->entries[i].entry_type == CUSTOM && strcmp(t->entries[i].name, entry_name) == 0)
        {
            index = i;
            break;
        }
        i--;
    }
    return index;
}

int table_find_constant(table t, table_entry entry)
{
    int i = t->size -1, index = -1;
    while(i>=0)
    {
        if(table_entry_compatible_entry_type(t->entries[i], entry))
        {
            index = i;
            break;
        }
        i--;
    }
    return index;
}

int table_find_symbol(table t, table_entry entry)
{
    int i = t->size -1, index = -1;
    while(t->entries[i].entry_type != MARK)
    {
        if(table_entry_compatible_entry_type(t->entries[i], entry))
        {
            index = i;
            break;
        }
        i--;
    }
    return index;
}
