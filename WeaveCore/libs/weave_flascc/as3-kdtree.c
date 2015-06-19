#include "kdtree.h"
#include "AS3/AS3.h"
#include "tracef.h"

void as3_kd_new() __attribute((used,
	annotate("as3sig:public function as3_kd_new(dimensions:int):int"),
	annotate("as3package:weave.flascc")));

void as3_kd_new()
{
	int dimensions;
	struct kdtree* new_tree;

	AS3_GetScalarFromVar(dimensions, dimensions);

	new_tree = kd_create(dimensions);

	AS3_Return(new_tree);
}

void as3_kd_free() __attribute((used,
	annotate("as3sig:public function as3_kd_free(tree_ptr:int):void"),
	annotate("as3package:weave.flascc")));

void as3_kd_free()
{
	struct kdtree* tree_ptr;
	AS3_GetScalarFromVar(tree_ptr, tree_ptr);
	kd_free(tree_ptr);
}

void as3_kd_insert() __attribute((used,
	annotate("as3sig:public function as3_kd_insert(tree_ptr:int, key:Array, data:int):int"),
	annotate("as3package:weave.flascc")));

void as3_kd_insert()
{
	struct kdtree* tree_ptr;
	void* data;
	int idx, key_n, retval;

	AS3_GetScalarFromVar(tree_ptr, tree_ptr);
	AS3_GetScalarFromVar(data, data);

	inline_as3("%0 = key.length;" : "=r"(key_n));

	double keys[key_n];	

	for (idx = 0; idx < key_n; idx++)
	{
		inline_as3("%0 = key[%1]" : "=r"(keys[idx]) : "r"(idx));
	}

	retval = kd_insert(tree_ptr, keys, data);

	AS3_Return(retval);
}

void as3_kd_clear() __attribute((used,
	annotate("as3sig:public function as3_kd_clear(tree_ptr:int):void"),
	annotate("as3package:weave.flascc")));

void as3_kd_clear()
{
	struct kdtree* tree_ptr;
	AS3_GetScalarFromVar(tree_ptr, tree_ptr);
	kd_clear(tree_ptr);
}

void as3_kd_query_range() __attribute((used,
	annotate("as3sig:public function as3_kd_query_range(tree_ptr:int, minKey:Array, maxKey:Array, inclusive:Boolean = true):Array"),
	annotate("as3package:weave.flascc")));

void as3_kd_query_range()
{
	int key_n, res_size, inclusive, idx;

	struct kdtree* tree_ptr;
	struct kdres* res;
	void* data_tmp;

	AS3_GetScalarFromVar(tree_ptr, tree_ptr);
	AS3_GetScalarFromVar(inclusive, inclusive);
	inline_as3("%0 = key.length;" : "=r"(key_n));

	/* copy over the key arrays */

	double minKey[key_n];
	double maxKey[key_n];

	for (idx = 0; idx < key_n; idx++)
	{
		inline_as3("%0 = minKey[%2]; %1 = maxKey[%2];" : "=r"(minKey[idx]), "=r"(maxKey[idx]) : "r"(idx));
	}

	res = kd_in_bounds(tree_ptr, minKey, maxKey, inclusive);

	/* Build an array of data with the result list */

	res_size = kd_res_size(res);

	inline_as3("var results:Array = new Array(%0);" : : "r"(res_size));

	for (idx = 0; idx < res_size; idx++)
	{
		data_tmp = kd_res_item_data(res);
		inline_as3("results[%0] = %1;" : : "r"(idx), "r"(data_tmp));
		kd_res_next(res);
	}

	kd_res_free(res);

	AS3_ReturnAS3Var(results);
}