#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "ast.h"

#include <llvm-c/Core.h>

static inline report_error(int lineno, const char *msg)
{
	fprintf(stderr, "lineno:%d, %s\n", lineno, msg);
	exit(1);
}

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
	LLVMValueRef *args = node->data.value_list;
	char *format = malloc(2 * argc + 2);

	/* construct format parameter */
	for (int i = 0; i < argc; i++) {
		args[i + 1] = node->lc->rb->data.value_list[i];
		format[i * 2] = '%';
		format[i * 2 + 1] = node->lc->rb->data.expr_type_list[i];
	}
	format[argc * 2] = '\n';
	args[0] = LLVMBuildGlobalStringPtr(
		global_unique_builder, format, "format"
	);

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
	forchild(node, c) {
		node->data.expr_type_list[idx] = c->data.expr_type;
		node->data.value_list[idx++] = c->data.value;
	}
	node->data.len = idx;
}

handle(write_expr, node)
{
	if (eq(node->lc->data.type, "STRING")) {
		node->data.expr_type = node->lc->data.expr_type;
		node->data.value = node->lc->data.value;
	} else { //expression
		node->data.expr_type = node->lc->data.expr_type;
		node->data.value = node->lc->data.value;
	}
}

handle(STRING, node)
{
	/* remove double quote */
	char *tmp = strdup(node->data.name);
	tmp[strlen(tmp) - 1] = '\0';
	node->data.expr_type = 's';
	node->data.value = LLVMBuildGlobalStringPtr(
		global_unique_builder,
		tmp + 1,
		inspect(&node->data)
	);
}

handle(INTEGER, node)
{
	node->data.expr_type = 'd';
	node->data.value = LLVMConstInt(
		LLVMInt32Type(), atoi(node->data.name), 1
	);
}

handle(REAL, node)
{
	node->data.expr_type = 'f';
	node->data.value = LLVMConstRealOfString(
		LLVMDoubleType(), node->data.name
	);
}

handle(number, node)
{
	node->data.expr_type = node->lc->data.expr_type;
	node->data.value = node->lc->data.value;
}

handle(simple_expression, node)
{
	node->data.expr_type = node->lc->data.expr_type;
	node->data.value = node->lc->data.value;
}

handle(binary_op, node)
{
	node->data.type = node->lc->data.type;
}

static inline void handle_integer_expression(struct ast_node *node,
					     struct ast_node *lc,
					     char *op,
					     struct ast_node *rc)
{
	node->data.expr_type = lc->data.expr_type;
	if (eq(op, "+")) {
		node->data.value = LLVMBuildAdd(global_unique_builder,
						lc->data.value,
						rc->data.value,
						"A + B"); //lc->data.name + rc->data.name
	} else if (eq(op, "-")) {
		node->data.value = LLVMBuildSub(global_unique_builder,
						lc->data.value,
						rc->data.value,
						"A - B");
	} else if (eq(op, "*")) {
		node->data.value = LLVMBuildMul(global_unique_builder,
						lc->data.value,
						rc->data.value,
						"A * B");
	} else if (eq(op, "DIV")) {
		node->data.value = LLVMBuildExactSDiv(global_unique_builder,
						      lc->data.value,
						      rc->data.value,
						      "A DIV B");
	} else if (eq(op, "DIV")) {
		LLVMValueRef tmp = LLVMBuildExactSDiv(global_unique_builder,
						      lc->data.value,
						      rc->data.value,
						      "");
		LLVMValueRef tmp2 = LLVMBuildMul(global_unique_builder,
						 tmp, rc->data.value, "");
		node->data.value = LLVMBuildSub(global_unique_builder,
						lc->data.value, tmp2, "");
	} else {
		assert(0);
	}

}

static inline void handle_real_expression(struct ast_node *node,
					  struct ast_node *lc,
					  char *op,
					  struct ast_node *rc)
{
	if (eq(op, "+")) {
		node->data.expr_type = lc->data.expr_type;
		node->data.value = LLVMBuildFAdd(global_unique_builder,
						lc->data.value,
						rc->data.value,
						"A + B"); //lc->data.name + rc->data.name
	} else if (eq(op, "-")) {
		node->data.expr_type = lc->data.expr_type;
		node->data.value = LLVMBuildFSub(global_unique_builder,
						lc->data.value,
						rc->data.value,
						"A - B");
	} else if (eq(op, "*")) {
		node->data.expr_type = lc->data.expr_type;
		node->data.value = LLVMBuildFMul(global_unique_builder,
						lc->data.value,
						rc->data.value,
						"A * B");
	} else if (eq(op, "/")) {
		node->data.expr_type = lc->data.expr_type;
		node->data.value = LLVMBuildFDiv(global_unique_builder,
						lc->data.value,
						rc->data.value,
						"A / B");
	} else {
		assert(0);
	}
}

handle(binary_op_expression, node)
{
	struct ast_node *lc = node->lc;
	struct ast_node *op = node->lc->rb;
	struct ast_node *rc = node->lc->rb->rb;

	if (lc->data.expr_type != rc->data.expr_type)
		report_error(node->data.lineno, "lhs type != rhs type");

	char expr_type = lc->data.expr_type;
	if (expr_type == 'd')
		handle_integer_expression(node, lc, op->data.type, rc);
	if (expr_type == 'f')
		handle_real_expression(node, lc, op->data.type, rc);
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
	if (match("INTEGER"))
		handle_INTEGER(node);
	if (match("REAL"))
		handle_REAL(node);
	if (match("number"))
		handle_number(node);
	if (match("simple expression"))
		handle_simple_expression(node);
	if (match("binary-op"))
		handle_binary_op(node);
	if (match("binary-op expression"))
		handle_binary_op_expression(node);

#undef match
}

int codegen(struct ast_node *root)
{
	init();

	traverse(root);

	LLVMBuildRet(global_unique_builder, LLVMConstInt(LLVMInt32Type(), 0, 0));
	LLVMDumpModule(global_unique_module);
	LLVMDisposeModule(global_unique_module);
}
