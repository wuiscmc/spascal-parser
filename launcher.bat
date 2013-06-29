@ECHO off

bin\flex -Sbin/flex.skl src/lexico.l
bin\byacc -v src/sintact.y
gcc y_tab.c src/symbols_table/table_entry.c src/symbols_table/table.c src/helpers.c src/main.c -o procsin.exe

procsin.exe test\doomstest

del procsin.exe lexyy.c y_tab.c y.out

pause
