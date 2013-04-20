programa prueba2; 

{programa de prueba numero 2}


funcion multiplica (num1: entero, num2: entero): entero,
var 
	a, b: entero; 
	c, d: real;
inicio
		multiplica := num1 * num2;
fin;

var num1, num2 : entero;

inicio
	escribe ('1 - El resultado de ', num1,' * ', num2,' = ', multiplica(num1,num2));
	+num1;
	-num2;
	escribe ('2 - El resultado de ', num1,' * ', num2,' = ', multiplica(num1,num2));
fin.
