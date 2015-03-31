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
    }
}
