Programa prueba4; {operaciones cadena}

Tipo 

linaresType = cadena;


Var  

cad1,cad2:cadena; 
l1:entero; 
l2:entero;
j:booleano;
linares:linaresType;
Inicio

Escribe('**Operaciones con cadenas**');

inserta ('pepe','linares',2);
borra ('pepe',2,1);

cad1:=extrae('linares',2,2);   
cad2:=concatena('pepe','linares');

l1:=longitud('pepe');
l2:=longitud('linares');

Si (l1>l2) Entonces
	Escribe(l1,' mayor que ', l2)
SiNo
	Escribe(l1,' menor que ',l2);
	
Si (busca(linares,cad2)=VERDADERO O busca(cad2,linares)=FALSO ) Entonces
	Escribe('Linares está contenido en cad2')
SiNo
	Escribe('Linares no está contenido en cad2');
	
Fin.