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
	import flash.utils.Dictionary;
	
	import mx.utils.ObjectUtil;
	
	import weave.compiler.StandardLib;
	import weave.utils.VectorUtils;
	import weave.flascc.as3_kd_new;
	import weave.flascc.as3_kd_free;
	import weave.flascc.as3_kd_insert;
	import weave.flascc.as3_kd_clear;
	import weave.flascc.as3_kd_query_range;
	import weave.api.core.IDisposableObject;
	
	/**
	 * This class defines a K-Dimensional Tree.
	 * 
	 * @author adufilie
	 */
	public class KDTree implements IDisposableObject
	{
		private var tree_ptr:int;
		/**
		 * Constructs an empty KDTree with the given dimensionality.
		 * 
		 * TODO: add parameter for a vector of key,object pairs and create a balanced tree from those.
		 */
		public function KDTree(dimensionality:uint)
		{
			this.dimensionality = dimensionality;
			if (dimensionality <= 0)
				throw("KDTree dimensionality must be > 0. (Given: "+dimensionality+")");
			tree_ptr = as3_kd_new(this.dimensionality);
		}

		public function dispose():void
		{
			as3_kd_free(tree_ptr);
		}

		/**
		 * The dimensionality of the KDTree.
		 */
		private var dimensionality:int;

		/** 
		 * Lookup table from integer identifiers to Objects
		 */
		
		private var intToObj:Dictionary = new Dictionary();

		/*
		 * Lookup table from Objects to integer identifiers
		 */
		
		private var objToInt:Dictionary = new Dictionary();

		private var freshId:int = 1;

		/**
		 * Balance the tree so there are an (approximately) equal number of points
		 * on either side of any given node. A balanced tree yields faster query
		 * times compared to an unbalanced tree.
		 * 
		 * NOTE: Balancing a large tree is very slow, so this should not be called very often.
		 */

		/**
		 * This function inserts a new key,object pair into the KDTree.
		 * Warning: This function could cause the tree to become unbalanced and degrade performance.
		 * @param key The k-dimensional key that corresponds to the object.
		 * @param object The object to insert in the tree.
		 * @return A KDNode object that can be used as a parameter to the remove() function.
		 */
		public function insert(key:Array, obj:Object):void
		{
			var id:int;

			if (key.length != dimensionality)
				throw new Error("KDTree.insert key parameter must have same dimensionality as tree");
			if (objToInt[obj] === undefined)
			{
				id = freshId++;
				objToInt[obj] = id;
				intToObj[id] = obj;
			}
			as3_kd_insert(tree_ptr, key, id);
		}

		/**
		 * Remove all nodes from the tree.
		 */
		public function clear():void
		{
			as3_kd_clear(tree_ptr);
		}


		public static const ASCENDING:String = "ASCENDING";
		public static const DESCENDING:String = "DESCENDING";
		/**
		 * @param minKey The minimum key values allowed for results of this query
		 * @param maxKey The maximum key values allowed for results of this query
		 * @param boundaryInclusive Specify whether to include the boundary for the query
		 * @param sortDimension Specify an integer >= 0 for the dimension to sort by
		 * @param sortDirection Specify either ASCENDING or DESCENDING
		 * @return An array of pointers to objects with K-Dimensional keys that fall between minKey and maxKey.
		 */
		public function queryRange(minKey:Array, maxKey:Array, boundaryInclusive:Boolean = true, sortDimension:int = -1, sortDirection:String = ASCENDING):Array
		{
			var ids:Array = as3_kd_query_range(tree_ptr, minKey, maxKey, boundaryInclusive);

			var queryResult:Array = ids.map(function(d:int,i:int,a:Array):Object {return intToObj[d];}, this);

			/* Should we maintain a Dictionary storing the original key info to do this? 
			if (sortDimension >= 0)
			{
				KDTree.compareNodesSortDimension = sortDimension;
				KDTree.compareNodesDescending = sortDirection == DESCENDING;
				StandardLib.sortOn(queryResult, getNodeSortValue, compareNodesDescending ? -1 : 1);
				
				// replace nodes with objects in queryResult
				i = resultCount;
				while (i--)
					queryResult[i] = (queryResult[i] as KDNode).object;
			}
			*/
			return queryResult;
		}
		
		/**
		 * This function is used to sort the results of queryRange().
		 */
		private static function getNodeSortValue(node:KDNode):Number
		{
			return node.key[compareNodesSortDimension];
		}
		private static function compareNodes(node1:KDNode, node2:KDNode):int
		{
			var result:int = ObjectUtil.numericCompare(
					node1.key[compareNodesSortDimension],
					node2.key[compareNodesSortDimension]
				);
			return compareNodesDescending ? -result : result;
		}
		private static var compareNodesSortDimension:int = 0;
		private static var compareNodesDescending:Boolean = false;
	}
}
