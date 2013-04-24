bin\flex -Sbin/flex.skl src/lexico.l
bin\byacc src/sintact.y
gcc y_tab.c src/symbols_table/table_entry.c src/symbols_table/table.c src/main.c -o procsin.exe
del lexyy.c y_tab.c

procsin.exe test\doomstest

del procsin.exe

pause
