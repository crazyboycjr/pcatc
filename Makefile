
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
OBJS := $(SRCS:.c=.o)

all: $(pcatc_BIN)

$(pcatc_BIN): $(OBJS) pcatc.yy.c
	$(CC) -o $@ $^ $(LDFLAGS)

pcatc.yy.c: pcatc.l
	$(LEX) -o $@ $^

test: $(pcatc_BIN)
	@bash test.sh $(testcases)

clean:
	-rm -rf $(OBJS)
	-rm -rf pcatc.yy.c

dist-clean:
	-rm -f $(pcatc_BIN)
