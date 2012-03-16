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
	import mx.utils.StringUtil;
	
	import weave.api.primitives.IBounds2D;
	import weave.compiler.StandardLib;
	
	/**
	 * Binary Line Generalization Tree
	 * This class defines a structure to represent a streamed polygon.
	 * 
	 * Reference: van Oosterom, P. 1990. Reactive data structures
	 *  for geographic information systems. PhD thesis, Department
	 *  of Computer Science, Leiden University, The Netherlands.
	 * 
	 * 
	 * @author adufilie
	 */
	public class BLGTree
	{
		/**
		 * Create an empty tree.
		 */
		public function BLGTree()
		{
		}

		/**
		 * This is the root of the BLGTree.
		 */
		private var rootNode:BLGNode = null;
		private var _lowestSavedImportance:Number = NaN;

		public function get isEmpty():Boolean
		{
			return rootNode == null;
		}
		
		/**
		 * The lowest importance value for any point that has been stored in the tree
		 */
		public function get lowestSavedImportance():Number
		{
			return _lowestSavedImportance;
		}

		/**
		 * Insert a new vertex into the BLGTree.
		 */
		public function insert(index:int, importance:Number, x:Number, y:Number):void
		{
			// update lowest saved importance
			if (isNaN(_lowestSavedImportance) || importance < _lowestSavedImportance)
				_lowestSavedImportance = importance; 
			
			// if this new point would have been in the previous traversal,
			// then the previous traversal is now invalid.
			if (importance >= previousTraversalMinImportance)
				previousTraversalMinImportance = -1; // reset this value so previous traversal won't be reused

			// create a new node object to hold these values
			var newNode:BLGNode = new BLGNode(index, importance, x, y);
			
			// base case: tree is empty, save as root node
			if (rootNode == null)
			{
				rootNode = newNode;
				return;
			}
			// iteratively traverse the tree until an appropriate insertion point is found
			var currentNode:BLGNode = rootNode;
			while (true)
			{
				// base case: if the new index is the same as the current index, keep old node
				if (currentNode.index == newNode.index)
				{
					if (newNode.left != null || newNode.right != null) // sanity check -- this should never happen
						throw new Error("BLGNode.insert: new node with children has index identical to an existing node");
					return;
				}
				// if the new importance is greater than this importance, tree needs to be restructured.
				if (newNode.importance > currentNode.importance)
				{
					// pull out the values of this node and replace with new node
					var tempIndex:int = currentNode.index;
					var tempImportance:Number = currentNode.importance;
					var tempX:Number = currentNode.x;
					var tempY:Number = currentNode.y;
					var tempLeft:BLGNode = currentNode.left;
					var tempRight:BLGNode = currentNode.right;
					
					currentNode.index = newNode.index;
					currentNode.importance = newNode.importance;
					currentNode.x = newNode.x;
					currentNode.y = newNode.y;
					currentNode.left = newNode.left;
					currentNode.right = newNode.right;
					
					newNode.index = tempIndex;
					newNode.importance = tempImportance;
					newNode.x = tempX;
					newNode.y = tempY;
					newNode.left = tempLeft;
					newNode.right = tempRight;
					// now 'currentNode' is the new node with no children and 'newNode' is the old tree.
					// we can insert the old tree into the new node below.
				}
				// the new node's importance is <= the importance of this node
				// if the new index is < this index, place it to the left 
				if (newNode.index < currentNode.index)
				{
					if (currentNode.left != null)
					{
						// travel down the tree to find the appropriate insertion spot
						currentNode = currentNode.left;
						continue;
					}
					// found insertion point
					currentNode.left = newNode;
					// newNode.left is ok because all child indices will be < currentNode; newNode.right is questionable
					newNode = newNode.right;
					currentNode.left.right = null; // clear previous reference to newNode
					break;
				}
				// otherwise, place it to the right of this node
				else // new index > this index
				{
					if (currentNode.right != null)
					{
						// travel down the tree to find the appropriate insertion spot
						currentNode = currentNode.right;
						continue;
					}
					// found insertion point, done
					currentNode.right = newNode;
					// newNode.right is ok because all child indices will be > currentNode; newNode.left is questionable
					newNode = newNode.left;
					currentNode.right.left = null; // clear previous reference to newNode
					break;
				}
			}
			// currentNode is a node that was just inserted
			// newNode is a tree to shuffle around currentNode
			var leftTraversalNode:BLGNode = currentNode; // for traversing down the left side of currentNode
			var rightTraversalNode:BLGNode = currentNode; // for traversing down the right side of currentNode
			while (newNode != null)
			{
				// shuffle newNode around currentNode
				if (newNode.index < currentNode.index) // newNode should go to the left of currentNode
				{
					if (newNode.index < leftTraversalNode.index) // will only happen once, when leftTraversalNode == currentNode
					{
						if (leftTraversalNode != currentNode)
							throw new Error("Unexpected error. leftTraversalNode != currentNode");
						
						if (leftTraversalNode.left != null)
						{
							// travel down the tree to find the appropriate insertion spot
							leftTraversalNode = leftTraversalNode.left;
							continue;
						}
						// found insertion point
						leftTraversalNode.left = newNode;
						// newNode.left is ok because all child indices will be < currentNode; newNode.right is questionable
						newNode = newNode.right;
						leftTraversalNode.left.right = null; // clear previous reference to newNode
						continue;
					}
					// everything under leftTraversalNode is < currentNode, so insert to the right of leftTraversalNode
					if (leftTraversalNode.right != null)
					{
						// travel down the tree to find the appropriate insertion spot
						leftTraversalNode = leftTraversalNode.right;
						continue;
					}
					// found insertion point
					leftTraversalNode.right = newNode;
					// newNode.left is ok because all child indices will be < currentNode; newNode.right is questionable
					newNode = newNode.right;
					leftTraversalNode.right.right = null; // clear previous reference to newNode
				}
				else // newNode should go to the right of currentNode
				{
					if (newNode.index > rightTraversalNode.index) // will only happen once, when rightTraversalNode == currentNode
					{
						if (rightTraversalNode != currentNode)
							throw new Error("Unexpected error. rightTraversalNode != currentNode");
						
						if (rightTraversalNode.right != null)
						{
							// travel down the tree to find the appropriate insertion spot
							rightTraversalNode = rightTraversalNode.right;
							continue;
						}
						// found insertion point
						rightTraversalNode.right = newNode;
						// newNode.right is ok because all child indices will be > currentNode; newNode.left is questionable
						newNode = newNode.left;
						rightTraversalNode.right.left = null; // clear previous reference to newNode
						continue;
					}
					// everything under rightTraversalNode is > currentNode, so insert to the left of rightTraversalNode
					if (rightTraversalNode.left != null)
					{
						// travel down the tree to find the appropriate insertion spot
						rightTraversalNode = rightTraversalNode.left;
						continue;
					}
					// found insertion point
					rightTraversalNode.left = newNode;
					// newNode.right is ok because all child indices will be > currentNode; newNode.left is questionable
					newNode = newNode.left;
					rightTraversalNode.left.left = null; // clear previous reference to newNode
				}
			}
		}

		/**
		 * operationStack & nodeStack
		 * used internally in getPointVector() to keep track of the current traversal operation
		 */
		private var operationStack:Vector.<int> = new Vector.<int>();
		private var nodeStack:Vector.<BLGNode> = new Vector.<BLGNode>();
		private static const OP_VISIT:int = 0; // constant used with operationStack
		private static const OP_TRAVERSE:int = 1; // constant used with operationStack
		
		/**
		 * This function performs an in-order traversal of nodes, skipping those
		 * with importance < minImportance.  The visit operation is to append the
		 * current node to the traversalVector.
		 * @param minImportance No points with importance less than this value will be returned.
		 * @param visibleBounds If not null, this bounds will be used to remove unnecessary offscreen points.
		 * @return A list of BLGNodes, ordered by point index.
		 */
		public function getPointVector(minImportance:Number = 0, visibleBounds:IBounds2D = null):Vector.<BLGNode>
		{
			if (minImportance == previousTraversalMinImportance && previousTraversalVisibleBounds.equals(visibleBounds))
				return traversalVector; // avoid redundant computation

			var visible:Boolean = (visibleBounds == null);
			var resultCount:int = 0; // the number of nodes that have been stored in the traversalVector
			if (rootNode != null)
			{
				// traverse the tree
				// begin by putting a traverse operation on the stack
				operationStack[0] = OP_TRAVERSE;
				nodeStack[0] = rootNode;
				var prevPrevGridTest:uint = 0;
				var prevGridTest:uint = 0;
				var gridTest:uint;
				var sameOutsideGridID:Boolean = false; // true when the two previous consecutive points were in the same off-screen grid
				var stackPos:int = 0;
				var node:BLGNode;
				var operation:int;
				// loop until the stack is empty
				while (stackPos >= 0)
				{
					// get next node & operation
					node = nodeStack[stackPos];
					operation = operationStack[stackPos];
					// pop off stacks with cleanup
					nodeStack[stackPos] = null;
					operationStack[stackPos] = null;
					stackPos--;
					
					// handle operation
					if (operation == OP_TRAVERSE)
					{
						// if this node is unimportant, its children are also unimportant, so do nothing
						if (node.importance < minImportance)
							continue;
						
						// push three new operations on the stack, reverse order
	
						// push third operation if necessary
						if (node.right != null)
						{
							stackPos++;
							operationStack[stackPos] = OP_TRAVERSE;
							nodeStack[stackPos] = node.right; // right side last for in-order traversal
						}
						
						// push second operation
						stackPos++;
						operationStack[stackPos] = OP_VISIT;
						nodeStack[stackPos] = node;
						
						// push first operation if necessary
						if (node.left != null)
						{
							stackPos++;
							operationStack[stackPos] = OP_TRAVERSE;
							nodeStack[stackPos] = node.left; // left side first for in-order traversal
						}
					}
					else // OP_VISIT
					{
						/*
						// for debugging
						if (resultCount > 0 && traversalVector[resultCount - 1].index > node.index)
						{
							var errorMsg:String = StringUtil.substitute(
								"Unexpected error. OP_VISIT out of order ({0} to {1})",
								traversalVector[resultCount - 1].index,
								node.index
							);
							throw new Error(errorMsg);
						}
						*/
						if (visibleBounds != null)
						{
							gridTest = visibleBounds.getGridTest(node.x, node.y);
							if (prevPrevGridTest & prevGridTest & gridTest)
							{
								// Drop previous node.  Keep current prevPrevGridTest value.
								resultCount--;
							}
							else
							{
								if (resultCount >= 2) // polygon should be rendered if at least 3 vertices exist
									visible = true;
								
								// Don't drop previous node.  Shift prev grid test values.
								prevPrevGridTest = prevGridTest;
							}
							prevGridTest = gridTest;
						}
						// copy this node to the results
						traversalVector[resultCount++] = node;
					}
				}
			}
			// truncate vector to number of results
			traversalVector.length = resultCount;
			previousTraversalMinImportance = minImportance; // remember this value to avoid rudundant computation
			previousTraversalVisibleBounds.copyFrom(visibleBounds); // remember this value to avoid rudundant computation
			
			/*
			// for debugging
			for (var i:int = 0, prev:int = -1; i < traversalVector.length; i++)
			{
				if (traversalVector[i].index < prev)
				{
					trace("PROBLEM:",prev,"to",traversalVector[i].index);
					break;
				}
				prev = traversalVector[i].index;
			}
			*/
			
			// if nothing is visible, don't return anything
			if (!visible)
				traversalVector.length = 0;
			
			return traversalVector;
		}
		
		/**
		 * This vector is used in getPointVector().  It contains pointers to nodes that
		 * are currently being traversed. The first entry in the vector is the root node,
		 * and each other entry corresponds to a child node of the previous entry.
		 */
		private var traversalVector:Vector.<BLGNode> = new Vector.<BLGNode>();
		/**
		 * This is the minImportance value from the last traversal.
		 * It can be used to avoid redundant traversal computations.
		 */
		private var previousTraversalMinImportance:Number = -1;
		/**
		 * This is the visibleBounds value from the last traversal.
		 * It can be used to avoid redundant traversal computations.
		 */
		private var previousTraversalVisibleBounds:IBounds2D = new Bounds2D();

		/**
		 * @param splitIndex An index to split the tree at.
		 * @return A new BLGTree containing all the points whose index >= splitIndex.
		 */
		public function splitAtIndex(splitIndex:int):BLGTree
		{
			var newTree:BLGTree = new BLGTree();
			// get all points in this tree
			var nodes:Vector.<BLGNode> = getPointVector();
			// clear this tree
			rootNode = null;
			_lowestSavedImportance = NaN;
			// add back all the points to the appropriate trees
			for each (var node:BLGNode in nodes)
			{
				(node.index < splitIndex ? this : newTree).insert(node.index, node.importance, node.x, node.y);
				// break up tree structure of the old nodes
				node.left = node.right = null;
			}
			// clear references to previous nodes
			traversalVector.length = 0;
			previousTraversalMinImportance = -1;
			// return new tree
			return newTree;
		}

		/**
		 * Removes all points from the BLGTree.
		 */		
		public function clear():void
		{
			rootNode = null;
			traversalVector.length = 0;
			previousTraversalMinImportance = -1;
			_lowestSavedImportance = NaN;
		}
	}
}
