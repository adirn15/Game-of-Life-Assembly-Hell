#format is target-name: target dependencies
#{-tab-}actions

# All Targets
all: ass3

# Tool invocations
# Executable "ass3" depends on the files ass3.o
ass3: cr.o printer.o scheduler.o ass3.o atoi.o
	gcc -m32 -g -Wall -o ass3 cr.o printer.o scheduler.o atoi.o ass3.o 

cr.o: coroutines.s
	nasm  -g -f elf -w+all -o cr.o coroutines.s

printer.o: printer.s
	nasm -g -f elf -w+all -o printer.o printer.s

scheduler.o: scheduler.s
	nasm -g -f elf -w+all -o scheduler.o scheduler.s

atoi.o: atoi.s
	nasm -g -f elf -w+all -o atoi.o atoi.s


ass3.o: ass3.c
	gcc -m32 -g -Wall -l -ansi -c -o ass3.o ass3.c


#tell make that "clean" is not a file name!
.PHONY: clean

#Clean the build directory
clean: 
	rm -f *.o ass3