# PCAT Compiler

pcatc is a compiler of the PCAT(Pascal Clone with an ATtitude) programming language for Compilers course.

Currently the project is on stage 2, which uses `bison` to parse the syntax and print corresponding abstract syntax tree.

## Getting started
Put the testcases under `tests/`, with a suffix of `.pcat` for each PCAT source file.
```
make
make test
```
The program also support read source code from stdin if executed without extra arguments.
As we can see, in stage 1, we implement
- the basic function to parse the token
- print every token with its line number and column number
- report the errors appered in `test20.pcat` with format like what gcc presents.

## Stage 2
```
make test
```
The AST will be printed to stdout. If syntax error happens, the program will print the verbose error information as well as the error location.

The `test19.pcat` will fail to 'compile' because missing ';' at the end of WHILE statement.

In stage 2, we implement
- building the abstract syntax tree, and print it out to the screen
- basic syntax error report (with error locations).

What I still want to improve is to provide more language relevant scanner messages. I found a [webpage](https://www.freepascal.org/docs-html/user/userse61.html) lists some Free Pascal compiling error messages.

## Stage 3
```
make test
```
will display the test result.

```
./pcatc [input]
```
will output the AST to stdout and the LLVM IR code to stderr, we can type
```
$pcatc $file 2>&1 >&- >/dev/null | lli
```
to directly execute programs from LLVM bitcode.

![screenshot](http://github.com/crazyboycjr/pcatc/screenshot.png)

Currently, the code can pass `test01.pcat` and `test03.pcat`.