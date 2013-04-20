#include <stdio.h>
#include <stdlib.h>

extern FILE *yyin;
extern FILE *yyout;
int yyparse(void);

FILE *abrir_entrada(int argc,char **argv)
{
	FILE *f=NULL;
	if (argc>1){
		f=fopen(argv[1],"r");
		if(f==NULL){
			fprintf(stderr,"Fichero '%s' no encontrado\n",argv[1]);
			exit(1);
		} 
		else printf("Leyendo fichero '%s'.\n",argv[1]);
	}
	else printf("Leyendo entrada estandar. \n");
	return f;
} 

FILE *abrir_salida()
{
	FILE *f=NULL;
	f=fopen("Salida.txt","w+");
	printf("Creando fichero 'Salida.txt'");
	return f;
}

int main(int argc,char **argv)
{
	int val;
	
	yyin=abrir_entrada(argc,argv);
	//yyout=abrir_salida();
       
	return yyparse();

}