scanner: lua.y scanner.l symbols.o asm.o y.tab.c lex.yy.c
	gcc lex.yy.c y.tab.c symbols.o asm.o -o scanner

y.tab.c: lua.y
	yacc -d lua.y

lex.yy.c: scanner.l
	lex scanner.l

symbols.o: symbols.c symbols.h
	gcc -std=c99 -g -c symbols.c -o symbols.o

asm.o: asm.c asm.h
	gcc -g -c asm.c -o asm.o

clean:
	rm -rf *.o *.jasm y.tab.c y.tab.h lex.yy.c scanner

example: scanner
	./scanner ../testcase/example.lua example.jasm
	./javaa example.jasm
	java example

fib: scanner
	./scanner ../testcase/fib.lua fib.jasm
	./javaa fib.jasm
	java fib


sigma: scanner
	./scanner ../testcase/sigma.lua sigma.jasm
	./javaa sigma.jasm
	java sigma