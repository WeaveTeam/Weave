/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package weave.primitives
{
	/**
	 * This class defines a single node for a KDTree.  It corresponds to a splitting
	 * plane in a single dimension and maps a k-dimensional key to an object.
	 * This class should not be used outside the KDTree class definition.
	 * 
	 * @author adufilie
	 */	
	public class KDNode
	{
		/**
		 * @param dimension the index of the dimension that the split plane should be defined on
		 * @param key the k-dimensional key used to locate this node
		 * @param object the object associated with the key
		 */
		public function KDNode(key:Array, object:Object, splitDimension:int = 0)
		{
			this.key = key;
			this.object = object;
			clearChildrenAndSetSplitDimension(splitDimension);
		}

		/**
		 * This array contains nodes no longer in use.
		 */
		private static const unusedNodes:Array = [];
		/**
		 * This function is used to save old nodes for later use.
		 * @param node The node to save for later.
		 */		
		public static function saveUnusedNode(node:KDNode):void
		{
			// clear all pointers stored in node
			node.key = null;
			node.object = null;
			node.left = null;
			node.right = null;
			// save node
			unusedNodes.push(node);
		}
		/**
		 * This function uses object pooling to get an instance of KDNode.
		 * @return Either a previously saved unused node, or a new node.
		 */
		public static function getUnusedNode(key:Array, object:Object, splitDimension:int = 0):KDNode
		{
			// if no more unused nodes left, return new node
			if (unusedNodes.length == 0)
				return new KDNode(key, object, splitDimension);
			// get last unused node and remove from unusedNodes array
			var node:KDNode = unusedNodes.pop() as KDNode;
			// initialize node
			node.key = key;
			node.object = object;
			node.clearChildrenAndSetSplitDimension(splitDimension);
			return node;
		}

		/**
		 * The dimension that the splitting plane is defined on
		 * This property is made public for speed concerns, though it should not be modified.
		 */
		public var splitDimension:int;

		/**
		 * The location of the splitting plane, derived from splitDimension
		 * This property is made public for speed concerns, though it should not be modified.
		 */
		public var location:Number;
		
		/**
		 * This function does what the name says.  It can be used for tree balancing algorithms.
		 * @param value the new split dimension
		 */
		public function clearChildrenAndSetSplitDimension(value:int = 0):void
		{
			left = null;
			right = null;
			splitDimension = value;
			location = key[splitDimension];
		}

		/**
		 * The numbers in K-Dimensions used to locate the object
		 */
		public var key:Array;

		/**
		 * The object that is associated with the key
		 */
		public var object:Object;
		
		/**
		 * Child node corresponding to the left side of the splitting plane
		 */
		public var left:KDNode = null;

		/**
		 * Child node corresponding to the right side of the splitting plane
		 */
		public var right:KDNode = null;
	}
}
