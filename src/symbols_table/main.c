//
//  main.c
//  symbols table
//
//  Created by luizcarlos on 4/15/13.
//  Copyright (c) 2013 luizcarlos. All rights reserved.
//

#include <stdio.h>
#include "table.h"

int main(int argc, const char * argv[])
{
    table t = table_new();
    
    table_entry e; 
    int i;
    for (i = 0; i < 1000; i++) {
        table_push(t, table_entry_new_mark(i));
    }
    
    
    table_display(t);
    
    table_entry e2 = table_pop(t);

    
    
    table_destroy(&t);
    
	return 0;
}

