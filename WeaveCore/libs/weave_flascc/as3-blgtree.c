#include "blgtree.h"
#include "AS3/AS3.h"
#include "tracef.h"

void as3_blgtree_create() __attribute((used,
	annotate("as3sig:public function as3_blgtree_create():int"),
	annotate("as3package:weave.flascc")));

void as3_blgtree_create()
{
	void* tree = blgtree_create();
	AS3_Return(tree);
}

void as3_blgtree_clear() __attribute((used,
	annotate("as3sig:public function as3_blgtree_clear(tree:int):void"),
	annotate("as3package:weave.flascc")));

void as3_blgtree_clear()
{
	blgtree_t* tree_ptr;
	AS3_GetScalarFromVar(tree, tree_ptr);
	blgtree_clear(tree_ptr);
}

void as3_blgtree_destroy() __attribute((used,
	annotate("as3sig:public function as3_blgtree_destroy(tree:int):void"),
	annotate("as3package:weave.flascc")));

void as3_blgtree_destroy()
{
	blgtree_t* tree_ptr;
	AS3_GetScalarFromVar(tree, tree_ptr);
	blgtree_destroy(tree_ptr);
}

void as3_blgtree_is_empty() __attribute((used,
	annotate("as3sig:public function as3_blgtree_is_empty(tree:int):Boolean"),
	annotate("as3package:weave.flascc")));

void as3_blgtree_is_empty()
{
	blgtree_t* tree_ptr;
	char result;
	AS3_GetScalarFromVar(tree, tree_ptr);
	result = blgtree_is_empty(tree_ptr);
	AS3_Return(result);
}

void as3_blgtree_insert() __attribute((used,
	annotate("as3sig:public function as3_blgtree_insert(tree:int, index:int, importance:Number, x:Number, y:Number):void"),
	annotate("as3package:weave.flascc")));

void as3_blgtree_insert()
{
	blgtree_t* tree_ptr;
	int index;
	double importance, x, y;
	AS3_GetScalarFromVar(tree, tree_ptr);
	AS3_GetScalarFromVar(index, index);
	AS3_GetScalarFromVar(importance, importance);
	AS3_GetScalarFromVar(x, x);
	AS3_GetScalarFromVar(y, y);
	blgtree_insert(tree_ptr, index, importance, x, y);
}

void as3_blgtree_get_point_vector() __attribute((used,
	annotate("as3sig:public function as3_blgtree_insert(tree:int, minImportance:Number, visibleBounds:IBounds2D):Array"),
	annotate("as3package:weave.flascc")));

void as3_blgtree_get_point_vector()
{
	static blgnode_t* output_vector = NULL;
	static size_t output_vector_size = 0;


	blgtree_t* tree_ptr;
	blgnode_t* node;
	size_t len, tree_size;
	int idx;
	double minImportance;
	bounds_t visibleBounds;

	AS3_GetScalarFromVar(tree, tree_ptr);
	AS3_GetScalarFromVar(minImportance, minImportance);
	inline_nonreentrant_as3("
		%0 = visibleBounds.minX;
		%1 = visibleBounds.maxX;
		%2 = visibleBounds.minY;
		%3 = visibleBounds.maxY;
	" : "=r"(visibleBounds.minX), "=r"(visibleBounds.maxX), "=r"(visibleBounds.minY), "=r"(visibleBounds.maxY));

	tree_size = blgtree_size(tree_ptr);
	
	if (!output_vector || output_vector_size < tree_size)
	{
		output_vector && free(output_vector);
		output_vector = malloc(sizeof(blgnode_t*) * tree_size);
		output_vector_size = tree_size;
	}


	len = blgtree_get_point_vector(tree_ptr, min_importance, visibleBounds, output_vector, output_vector_size);

	inline_nonreentrant_as3("
		var output_array:Array = new Array(%0);
	" : : "r"(len));

	for (idx = 0; idx < len; idx++)
	{
		node = output_vector[idx];
		inline_nonreentrant_as3("
			output_array[%0] = new BLGNode(%1, %2, %3, %4);
		" : : "r"(idx), "r"(node->index), "r"(node->importance), "r"(node->x), "r"(node->y));
	}

	AS3_ReturnAS3Var(output_array);
}

void as3_blgtree_split_at_index() __attribute((used,
	annotate("as3sig:public function as3_blgtree_insert(tree:int, split_index:int):int"),
	annotate("as3package:weave.flascc")));

void as3_blgtree_split_at_index()
{
	blgtree_t* tree_ptr;
	AS3_GetScalarFromVar(tree, tree_ptr);
	tree_ptr = blgtree_split_at_index(tree, )
	AS3_Return(tree_ptr)
}
