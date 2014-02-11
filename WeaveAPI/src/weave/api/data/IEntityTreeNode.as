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
	 * Interface for a node for use with EntityTreeDataDescriptor and EntityTree.
	 * When implementing this interface as a wrapper for remote objects,
	 * make sure to avoid making excess RPC calls wherever possible.
	 * 
	 * @author adufilie 
	 */	
    public interface IEntityTreeNode
    {
		/**
		 * Gets a pointer to the object which is responsible for managing this node.
		 * The source object should have additional functions to make use of the node.
		 * @return The object responsible for managing this node.
		 */
		function getSource():Object;
		
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
		 * @return A list of children or null if this node has no children
		 */
		function getChildren():Array;
		
		/**
		 * Adds a child node.
		 * @param child The child to add.
		 * @param index The new child index.
		 * @return true if successful.
		 */
		function addChildAt(newChild:IEntityTreeNode, index:int):Boolean;
		
		/**
		 * Removes a child node.
		 * @param child The child to remove.
		 * @return true if successful.
		 */
		function removeChild(child:IEntityTreeNode):Boolean;
    }
}
