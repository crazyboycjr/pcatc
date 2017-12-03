
.PHONY: clean run test

CC := gcc
LEX := flex
YACC := bison

TEST_DIR := tests
#testcases := $(TEST_DIR)/test20.pcat
testcases := $(shell find $(TEST_DIR) -name "*.pcat")

pcatc_BIN = pcatc

CFLAGS := -c -ggdb3
LDFLAGS := -lfl

SRCS := $(wildcard *.c)
OBJS := $(SRCS:.c=.o) \
		pcatc.yy.o \
		pcatc.tab.o

all: $(pcatc_BIN)

$(pcatc_BIN): $(OBJS)
	$(CC) -o $@ $^ $(LDFLAGS)

pcatc.yy.c: pcatc.l pcatc.tab.h
	$(LEX) -o $@ $^

pcatc.tab.h pcatc.tab.c: pcatc.y
	$(YACC) -d $^

pcatc.tab.o pcatc.yy.o: ast.h

test: $(pcatc_BIN)
	@bash test.sh $(testcases)

clean:
	-rm -rf $(OBJS)
	-rm -rf pcatc.yy.c
	-rm -rf pcatc.tab.c pcatc.tab.h
	-rm -rf *-log.txt

dist-clean: clean
	-rm -f $(pcatc_BIN)
