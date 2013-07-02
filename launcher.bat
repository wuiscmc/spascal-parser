@ECHO off

bin\flex -Sbin/flex.skl src/lexico.l
bin\byacc -v -t src/sintact.y
gcc y_tab.c src/symbols_table/table_entry.c src/symbols_table/table.c src/helpers.c src/main.c -o procsin.exe

procsin.exe test\doomstest
rem procsin.exe test\prueba1.f
rem procsin.exe test\prueba2.f
rem procsin.exe test\prueba3.f
rem procsin.exe test\prueba4.f


del procsin.exe
del lexyy.c y_tab.c 
del y.out

pause
