#pragma once

struct ast_data {
	char *name;
};

struct ast_node {
	struct ast_node *lc, *rb; // left child, right brother
	struct ast_data data;
};

static struct ast_node pool[100000];

static inline struct ast_node *ast_new_node(char *name)
{
	static int top = 0;
	struct ast_node *p = &pool[top++];
	p->lc = p->rb = NULL;
	p->data.name = strdup(name);
	return p;
}

static void ast_print_structure(struct ast_node *root, int depth)
{
	if (!root) return;
	for (int i = 0; i < depth; i++)
		putchar(' ');
	printf("%s\n", root->data.name);

	ast_print_structure(root->lc, depth + 2);
	ast_print_structure(root->rb, depth);
}

static inline void ast_insert(struct ast_node *a, struct ast_node *b)
{
	struct ast_node *lc = a->lc;
	if (!lc) {
		a->lc = b;
		return;
	}
	while (lc->rb)
		lc = lc->rb;
	lc->rb = b;
}

static inline void ast_append(struct ast_node *a, struct ast_node *b)
{
	struct ast_node *rb = a->rb;
	if (!rb) {
		a->rb = b;
		return;
	}
	while (rb->rb)
		rb = rb->rb;
	rb->rb = b;
}

#define new_node(args...) ast_new_node(args)

#define INSERT_1(a)
#define INSERT_2(a, b) ast_insert(a, b)
#define INSERT_3(a, b, c) INSERT_2(a, b), ast_insert(a, c)
#define INSERT_4(a, b, c, d) INSERT_3(a, b, c), ast_insert(a, d)
#define INSERT_5(a, b, c, d, e) INSERT_4(a, b, c, d), ast_insert(a, e)
#define INSERT_6(a, b, c, d, e, f) INSERT_5(a, b, c, d, e), ast_insert(a, f)
#define INSERT_7(a, b, c, d, e, f, g) INSERT_6(a, b, c, d, e, f), ast_insert(a, g)
#define INSERT_8(a, b, c, d, e, f, g, h) INSERT_7(a, b, c, d, e, f, g), ast_insert(a, h)
#define INSERT_9(a, b, c, d, e, f, g, h, i) INSERT_8(a, b, c, d, e, f, g, h), ast_insert(a, i)
#define INSERT_N(N, ...) INSERT_##N(__VA_ARGS__)

#define APPEND_1(a)
#define APPEND_2(a, b) ast_append(a, b)
#define APPEND_3(a, b, c) APPEND_2(a, b), ast_append(a, c)
#define APPEND_4(a, b, c, d) APPEND_3(a, b, c), ast_append(a, d)
#define APPEND_5(a, b, c, d, e) APPEND_4(a, b, c, d), ast_append(a, e)
#define APPEND_6(a, b, c, d, e, f) APPEND_5(a, b, c, d, e), ast_append(a, f)
#define APPEND_7(a, b, c, d, e, f, g) APPEND_6(a, b, c, d, e, f), ast_append(a, g)
#define APPEND_N(N, ...) APPEND_##N(__VA_ARGS__)


#define _NUM_ARGS(X, X10, X9, X8, X7, X6, X5, X4, X3, X2, X1, N, ...) N
#define NUM_ARGS(...) _NUM_ARGS(0, ##__VA_ARGS__, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)

//#define _INSERT_MACRO_CHOOSE(N, ...) INSERT_N(N, __VA_ARGS__)
//#define INSERT_MACRO_CHOOSE(...) _INSERT_MACRO_CHOOSE(NUM_ARGS(__VA_ARGS__), __VA_ARGS__)

#define _GENERAL_MACRO_CHOOSE(macro, n, ...) macro##_N(n, __VA_ARGS__)
#define GENERAL_MACRO_CHOOSE(macro, ...) _GENERAL_MACRO_CHOOSE(macro, NUM_ARGS(__VA_ARGS__), __VA_ARGS__)

//#define insert(args...) INSERT_MACRO_CHOOSE(args)
#define insert(args...) GENERAL_MACRO_CHOOSE(INSERT, args)
#define append(args...) GENERAL_MACRO_CHOOSE(APPEND, args)
