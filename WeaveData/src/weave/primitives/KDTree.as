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

package weave.primitives
{
	import weave.api.core.IDisposableObject;
	import weave.flascc.as3_kd_clear;
	import weave.flascc.as3_kd_free;
	import weave.flascc.as3_kd_insert;
	import weave.flascc.as3_kd_new;
	import weave.flascc.as3_kd_query_range;
	import weave.utils.VectorUtils;
	
	/**
	 * This class defines a K-Dimensional Tree.
	 * 
	 * @author adufilie
	 */
	public class KDTree implements IDisposableObject
	{
		/**
		 * Constructs an empty KDTree with the given dimensionality.
		 */
		public function KDTree(dimensionality:uint)
		{
			this.dimensionality = dimensionality;
			if (dimensionality <= 0)
				throw("KDTree dimensionality must be > 0. (Given: "+dimensionality+")");
			tree_ptr = as3_kd_new(this.dimensionality);
		}

		/**
		 * C memory pointer
		 */
		private var tree_ptr:int;
		
		/**
		 * The dimensionality of the KDTree.
		 */
		private var dimensionality:int;

		/** 
		 * Lookup table from integers to Objects
		 */
		private var objects:Array = [];

		/**
		 * This function inserts a new key,object pair into the KDTree.
		 * Warning: This function could cause the tree to become unbalanced and degrade performance.
		 * @param key The k-dimensional key that corresponds to the object.
		 * @param obj The object to insert in the tree.
		 * @return A KDNode object that can be used as a parameter to the remove() function.
		 */
		public function insert(key:Array, obj:Object):void
		{
			if (!key || key.length != dimensionality)
				throw new Error("KDTree.insert key parameter must have same dimensionality as tree");
			
			as3_kd_insert(tree_ptr, key, objects.push(obj) - 1);
		}

		/**
		 * @param minKey The minimum key values allowed for results of this query
		 * @param maxKey The maximum key values allowed for results of this query
		 * @param boundaryInclusive Specify whether to include the boundary for the query
		 * @return An array of pointers to objects with K-Dimensional keys that fall between minKey and maxKey.
		 */
		public function queryRange(minKey:Array, maxKey:Array, boundaryInclusive:Boolean = true):Array
		{
			if (!minKey || minKey.length != dimensionality || !maxKey || maxKey.length != dimensionality)
				throw new Error("KDTree.queryRange minKey, maxKey parameters must have same dimensionality as tree");
			
			var result:Array = as3_kd_query_range(tree_ptr, minKey, maxKey, boundaryInclusive);
			result.sort(Array.NUMERIC);
			for (var i:int = 0; i < result.length; i++)
				result[i] = objects[result[i]];
			VectorUtils.removeDuplicatesFromSortedArray(result);
			return result;
		}

		/**
		 * Remove all nodes from the tree.
		 */
		public function clear():void
		{
			objects.length = 0;
			as3_kd_clear(tree_ptr);
		}

		public function dispose():void
		{
			objects = null;
			as3_kd_free(tree_ptr);
		}
	}
}
