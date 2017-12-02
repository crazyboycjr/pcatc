#pragma once

struct ast_data {
	char *name;
};

struct ast_node {
	struct ast_node *lc, *rb; // left child, right brother
	struct ast_data data;
};

static struct ast_node pool[100000];

static inline struct ast_node *new_node(char *name)
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

static inline void insert(struct ast_node *a, struct ast_node *b)
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

