/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

#include <stdlib.h>
#include <string.h>
#include "blgtree.h"

/**
 * Binary Line Generalization Tree
 * This class defines a structure to represent a streamed polygon.
 * 
 * Reference: van Oosterom, P. 1990. Reactive data structures
 *  for geographic information systems. PhD thesis, Department
 *  of Computer Science, Leiden University, The Netherlands.
 * 
 * Original code adufilie, ported to C by pkovac
 * 
 * @author adufilie
 * @author pkovac
 * 
 */



struct BLGTree {
	blgnode_t* root;
	size_t node_count;
};

/* BLGNode */

static blgnode_t* blgnode_create(int index, double importance, double x, double y)
{
	blgnode_t* node = malloc(sizeof(blgnode_t));
	
	node->index = index;
	node->importance = importance;
	node->x = x;
	node->y = y;
	node->left = node->right = NULL;

	return node;
}

static void blgnode_destroy(blgnode_t* node)
{
	if (!node) return;
	blgnode_destroy(node->left);
	blgnode_destroy(node->right);
	free(node);
}

/* BLGTree */

blgtree_t* blgtree_create(void)
{
	return calloc(1, sizeof(blgtree_t));
}

void blgtree_clear(blgtree_t* tree)
{
	blgnode_destroy(tree->root);
	tree->root = NULL;
}

void blgtree_destroy(blgtree_t* tree)
{
	blgtree_clear(tree);
	free(tree);
}

char blgtree_is_empty(blgtree_t* tree)
{
	return tree->root == NULL;
}

size_t blgtree_size(blgtree_t* tree)
{
	return tree->node_count;
}

static inline void swap_nodes(blgnode_t* a, blgnode_t* b)
{
	blgnode_t temp;

	memcpy(&temp, a, sizeof(blgnode_t));
	memcpy(a, b, sizeof(blgnode_t));
	memcpy(b, &temp, sizeof(blgnode_t));
}

static inline char traverse_and_insert_left(blgnode_t** current_node, blgnode_t** new_node)
{
	if ((*current_node)->left)
	{
		/* Travel down the tree to find the appropriate insertion point. */
		*current_node = (*current_node)->left;
		return 0;
	}
	else
	{
		/* Found the insertion point */
		(*current_node)->left = *new_node;
		*new_node = (*new_node)->right;
		/* Clear previous reference to new_node */
		(*current_node)->left->right = NULL;
		return 1;
	}
}

static inline char traverse_and_insert_right(blgnode_t** current_node, blgnode_t** new_node)
{
	if ((*current_node)->right)
	{
		/* Travel down the tree to find the appropriate insertion point. */
		*current_node = (*current_node)->right;
		return 0;
	}
	else
	{
		/* Found the insertion point */
		(*current_node)->right = *new_node;
		*new_node = (*new_node)->left;
		/* Clear previous reference to new_node */
		(*current_node)->right->left = NULL;
		return 1;
	}
}

static int blgtree_insert_internal(blgtree_t* tree, blgnode_t* new_node)
{
	blgnode_t *current_node, *left_traversal_node, *right_traversal_node;

	/* Base case: Tree is empty, save as root node */
	if (tree->root == NULL)
	{
		tree->root = new_node;
		return;
	}

	/* Iteratively traverse the tree until an appropriate insertion point is found */

	current_node = new_node;
	while (1)
	{
		/* Base case: If the new index is the same as the current index, keep the old node. */
		if (current_node->index == new_node->index)
		{
			if (new_node->left != NULL || new_node->right != NULL) /* This should never happen */
				return -1;
			return 0;
		}

		/* If the new importance is greater than this importance, the tree needs to be restructured */
		if (new_node->importance > current_node->importance)
			swap_nodes(new_node, current_node);

		/* The new node's importance is now <= the importance of this node
		 * If the new index is < this index, place it to the left. */
		if (new_node->index < current_node->index)
		{
			if (traverse_and_insert_left(&current_node, &new_node) == 0)
				continue;
			break;
		}
		else /* new_node->index >= current_node->index */
		{
			if (traverse_and_insert_right(&current_node, &new_node) == 0)
				continue;
			break;
		}
	}

	/* current_node is now a node that was just inserted. 
	 * new_node is a tree to shuffle around current_node */

	left_traversal_node = current_node;
	right_traversal_node = current_node;

	while (new_node != NULL)
	{
		/* Shuffle new_node around current_node */
		if (new_node->index < current_node->index)
		{
			/* new_node should go to the left of the current node */
			if (new_node->index < left_traversal_node->index)
			{
				/* This should only happen once when left is == current */
				if (traverse_and_insert_left(&left_traversal_node, &new_node) == 0)
					continue;
				break;

			}
			else
			{
				if (traverse_and_insert_right(&left_traversal_node, &new_node) == 0)
					continue;
				break;				
			}
		}
		else
		{
			/* new_node should go to the right of the current_node */
			if (new_node->index > right_traversal_node->index)
			{
				if (traverse_and_insert_right(&right_traversal_node, &new_node) == 0)
					continue;
				break;
			}
			else
			{
				if (traverse_and_insert_left(&right_traversal_node, &new_node) == 0)
					continue;
				break;
			}
		}
	}

	tree->node_count++;
	return 0;
}

int blgtree_insert(blgtree_t* tree, int index, double importance, double x, double y)
{
	return blgtree_insert_internal(tree, blgnode_create(index, importance, x, y));
}

typedef struct GetPointState {
	double min_importance;
	bounds_t* visible_bounds;
	blgnode_t* output;
	size_t output_len;
	size_t output_len_max;

	char prev_prev_grid_test;
	char prev_grid_test;
	char grid_test;
} get_point_state_t;

static char bounds_get_grid_test(bounds_t* bounds, double x, double y)
{
	double x0, x1, y0, y1;
	if (bounds->xMin < bounds->xMax)
		x0 = bounds->xMin, x1 = bounds->xMax;
	else
		x1 = bounds->xMin, x0 = bounds->xMax;

	if (bounds->yMin < bounds->yMax)
		y0 = bounds->yMin, y1 = bounds->yMax;
	else
		y1 = bounds->yMin, y0 = bounds->yMax;
	
	//return (x < x0 ? 0x0001/*X_LO*/ : (x > x1 ? 0x0010/*X_HI*/ : 0)) |
	//	   (y < y0 ? 0x0100/*Y_LO*/ : (y > y1 ? 0x1000/*Y_HI*/ : 0));
	return ((x < x0) << 0 ) | ((x > x1) << 1) | ((y < y0) << 2 ) | ((y > y1) << 3);
}

static void point_vector_visit(get_point_state_t* state, blgnode_t* node)
{
	if (state->visible_bounds)
	{
		state->grid_test = bounds_get_grid_test(state->visible_bounds, node->x, node->y);

		if (state->prev_prev_grid_test & state->prev_grid_test & state->grid_test)
		{
			/* Drop previous node */
			state->output_len--;
		}
		else
		{
			/* Don't drop previous node, shift previous grid test values */
			state->prev_prev_grid_test = state->prev_grid_test;
		}
		state->prev_grid_test = state->grid_test;
	}
	/* Copy node to results */
	state->output[state->output_len++];
}
static void point_vector_traverse(get_point_state_t* state, blgnode_t* node)
{
	if (node->importance < state->min_importance)
		return;

	if (node->left)
		point_vector_traverse(state, node);

	point_vector_visit(state, node);

	if (node->right)
		point_vector_traverse(state, node);

	return;
}
size_t blgtree_get_point_vector(blgtree_t* tree, double min_importance, bounds_t* visible_bounds, blgnode_t* output, size_t output_len_max)
{
	get_point_state_t state;

	state.min_importance = min_importance;
	state.visible_bounds = visible_bounds;
	state.output = output;
	state.output_len_max = output_len_max;
	state.output_len = 0;

	if (tree->root)
	{
		point_vector_traverse(&state, tree->root);
	}

	return state.output_len;
}

blgtree_t* blgtree_split_at_index(blgtree_t* tree, int split_index)
{
	blgtree_t* new_tree = blgtree_create();
	blgnode_t *parent, *subtree;
	while (1)
	{
		parent = NULL;
		subtree = tree->root;
		/* Traverse down right side of this tree until we find a subtree that should go to the new tree */
		while (subtree && subtree->index < split_index)
		{
			parent = subtree;
			subtree = subtree->right;
		}

		/* Stop if no appropriate subtree found. */
		if (!subtree)
			break;

		/* Remove subtree. */
		if (parent)
			parent->right = NULL;
		else
			tree->root = NULL;

		/* Add to new tree. */
		blgtree_insert_internal(new_tree, subtree);

		parent = NULL;
		subtree = new_tree->root;
		/* Traverse down left side of this new tree until we find a subtree that should go back to the old tree */
		while (subtree && subtree->index >= split_index)
		{
			parent = subtree;
			subtree = subtree->left;
		}

		/* Stop if no appropriate subtree found. */
		if (!subtree)
			break;

		/* Remove subtree */
		if (parent)
			parent->left = NULL;
		else
			new_tree->root = NULL;

		/* Add to old tree */
		blgtree_insert_internal(tree, subtree);
	}
	return new_tree;
}

main;
