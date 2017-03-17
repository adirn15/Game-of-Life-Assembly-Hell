#include <stdlib.h>
#include <stdio.h>

void init_life();
int my_atoi(char*);
extern int DEBUG,WorldWidth,WorldLength,Generations,Frequency; 
extern char* FILENAME;
extern char* state;
int debug=0;

int main (int argc, char** argv){
	if (argc!=6 && argc!=7){
		printf("Error: insufficient arguments\n");
		return 0;
	}
	int i;
	if (argc==6)
		i=1;
	else{
		DEBUG=1;
		i=2;
	}
	FILENAME = argv[i++];
	WorldLength = my_atoi(argv[i++]);
	WorldWidth = my_atoi(argv[i++]);
	Generations = my_atoi(argv[i++]);
	Frequency = my_atoi(argv[i++]);

	if (argv[1][0]=='-' && argv[1][1]=='d'){
		printf("file name: %s\nworld length: %d\nworld width: %d\nGenerations: %d\nFrequency: %d\n",FILENAME,WorldLength,WorldWidth,Generations,Frequency);
	}

	init_life();

	return 1;
}