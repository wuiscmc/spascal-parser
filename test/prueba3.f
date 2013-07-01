Programa prueba3;

Usar pantalla;

Const AUX=3;

Tipo genero = entero;


Var 
	i, num:entero; 

	sexo: genero;

	numero:real; 

Inicio  {Inicio cuerpo}

	Lee numero;
	num:=2;

	Repite
	    num:= num + AUX;
	Hasta (i=3);

	Lee sexo;

	Si (NO(sexo=1)) Entonces
	     Inicio	    
		Escribe('Hola señora');
			Si (sexo=2 O sexo=3 Y num=3) Entonces
				Escribe('PDL1')
			SiNo
				Escribe('PDL2');
	     Fin;
Fin.
