
.PHONY: clean run test

CC := gcc
LEX := flex
YACC := bison

TEST_DIR := tests
testcases := $(TEST_DIR)/test01.pcat
#testcases := $(shell find $(TEST_DIR) -name "*.pcat")

OBJ_DIR := obj
pcatc_BIN = $(OBJ_DIR)/pcatc

all: $(pcatc_BIN)

$(pcatc_BIN): main.c $(OBJ_DIR)/pcatc.yy.c
	$(CC) -o $(pcatc_BIN) main.c $(OBJ_DIR)/pcatc.yy.c -lfl

$(OBJ_DIR)/pcatc.yy.c: pcatc.l
	$(LEX) -o $(OBJ_DIR)/pcatc.yy.c pcatc.l

test: $(pcatc_BIN)
	@bash test.sh $(testcases)

clean:
	-rm -rf obj/*
	-rm -rf pcatc.yy.c
