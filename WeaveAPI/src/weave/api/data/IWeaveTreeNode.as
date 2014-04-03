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
package weave.api.data
{
	/**
	 * Interface for a node for use with WeaveTreeDataDescriptor and WeaveTree.
	 * Implementations should have [RemoteClass] metadata in front of the class definition
	 * and should make it possible for drag+drop to make a fully-functional copy of a node by
	 * copying all public properties, which should have simple types.
	 * When implementing this interface as a wrapper for remote objects, make sure to avoid
	 * making excess RPC calls wherever possible.
	 * @author adufilie 
	 */	
    public interface IWeaveTreeNode
    {
		/**
		 * Checks if this node is equivalent to another.
		 * Note that the following should return true:  node.equals(ObjectUtil.copy(node))
		 * @param other Another node to compare.
		 * @return true if this node is equivalent to the other node.
		 */
		function equals(other:IWeaveTreeNode):Boolean;
		
		/**
		 * Gets a label for this node.
		 * @return A label to display in the tree.
		 */
		function getLabel():String;
		
		/**
		 * Checks if this node is a branch.
		 * @return true if this node is a branch
		 */
		function isBranch():Boolean;
		
		/**
		 * Checks if this node has any children which are branches.
		 * @return true if this node has any children which are branches
		 */
		function hasChildBranches():Boolean;
		
		/**
		 * Gets children for this node.
		 * @return A list of children implementing IWeaveTreeNode or null if this node has no children.
		 */
		function getChildren():Array;
		
		/**
		 * Adds a child node.
		 * @param child The child to add.
		 * @param index The new child index.
		 * @return true if successful.
		 */
		function addChildAt(newChild:IWeaveTreeNode, index:int):Boolean;
		
		/**
		 * Removes a child node.
		 * @param child The child to remove.
		 * @return true if successful.
		 */
		function removeChild(child:IWeaveTreeNode):Boolean;
    }
}
