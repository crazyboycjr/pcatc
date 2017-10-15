# PCAT Compiler

pcatc is a compiler of the PCAT(Pascal Clone with an ATtitude) programming language for Compilers course.

## Getting started
Put the testcases under `tests/`, with a suffix of `.pcat` for each PCAT source file.
```
mkdir obj
make
make test
```
As we can see, in stage 1, we implement
- the basic function to parse the token
- print every token with its line number and column number
- report the errors appered in `test20.pcat` with format like what gcc presents.
