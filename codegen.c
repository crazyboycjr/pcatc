#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "ast.h"

#include <llvm-c/Core.h>

static LLVMModuleRef global_unique_module;
static LLVMBuilderRef global_unique_builder;

static void init()
{
	global_unique_module = LLVMModuleCreateWithName("PCAT Main Module");
	global_unique_builder = LLVMCreateBuilder();
}

static inline int eq(const char *s1, const char *s2)
{
	return strcmp(s1, s2) == 0;
}

static inline char *repeat(const char *str, int n)
{
	int len = strlen(str);
	char *ret = malloc(n * len + 1);
	for (int i = 0; i < n; i++)
		strncpy(ret + i * len, str, len);
	return ret;
}

#define handle(name, node) \
	static inline void handle_##name(struct ast_node *node)

handle(BEGIN, node)
{
	LLVMTypeRef main_function_t = LLVMFunctionType(
		LLVMInt32Type(), NULL, 0, 0
	);
	node->data.value = LLVMAddFunction(
		global_unique_module, "main", main_function_t
	);
	LLVMBasicBlockRef basic_block = LLVMAppendBasicBlock(
		node->data.value, "BEGIN"
	);
	LLVMPositionBuilderAtEnd(global_unique_builder, basic_block);
}

handle(write_statement, node)
{
	LLVMValueRef write_func = node->lc->data.value;

	int argc = node->lc->rb->data.len;
	char *format = repeat("%s", argc);
	format[argc * 2] = '\n';

	LLVMValueRef *args = node->data.value_list;
	args[0] = LLVMBuildGlobalStringPtr(
		global_unique_builder, format, "format"
	);

	memcpy(args + 1, node->lc->rb->data.value_list,
	       argc * sizeof(LLVMValueRef));

	LLVMBuildCall(global_unique_builder,
		      write_func, args, argc + 1, "WRITE");
}

handle(WRITE, node)
{
	LLVMValueRef write_function = LLVMGetNamedFunction(
		global_unique_module, "printf"
	);

	if (!write_function) {
		LLVMTypeRef write_args_t[] = { LLVMPointerType(LLVMInt8Type(), 0) };
		LLVMTypeRef write_function_t = LLVMFunctionType(
			LLVMInt32Type(), write_args_t, 0, 1
		);
		write_function = LLVMAddFunction(
			global_unique_module, "printf", write_function_t
		);
	}

	node->data.value = write_function;
}

handle(write_params, node)
{
	int idx = 0;
	forchild(node, c)
		node->data.value_list[idx++] = c->data.value;
	node->data.len = idx;
}

handle(write_expr, node)
{
	if (eq(node->lc->data.type, "STRING")) {
		node->data.value = node->lc->data.value;
	} else { //expression
		assert(0);
	}
}

handle(STRING, node)
{
	/* remove double quote */
	char *tmp = strdup(node->data.name);
	tmp[strlen(tmp) - 1] = '\0';
	node->data.value = LLVMBuildGlobalStringPtr(
		global_unique_builder,
		tmp + 1,
		inspect(&node->data)
	);
}

void traverse(struct ast_node *node)
{
	if (!node) return;

#define match(keyword) eq(node->data.type, keyword)

	if (match("BEGIN"))
		handle_BEGIN(node);

	forchild(node, c)
		traverse(c);

	if (match("write statement"))
		handle_write_statement(node);

	if (match("WRITE"))
		handle_WRITE(node);
	if (match("write-params"))
		handle_write_params(node);
	if (match("write-expr"))
		handle_write_expr(node);
	if (match("STRING"))
		handle_STRING(node);

#undef match
}

int codegen(struct ast_node *root)
{
	fflush(stdout);
	init();

	traverse(root);

	LLVMBuildRet(global_unique_builder, LLVMConstInt(LLVMInt32Type(), 0, 0));
	LLVMDumpModule(global_unique_module);
	LLVMDisposeModule(global_unique_module);
}
