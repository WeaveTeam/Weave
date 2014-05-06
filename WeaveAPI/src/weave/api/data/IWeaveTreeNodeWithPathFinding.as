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
	 * Extends IWeaveTreeNode by adding findPathToNode().
	 * @author adufilie
	 */	
    public interface IWeaveTreeNodeWithPathFinding extends IWeaveTreeNode
    {
		/**
		 * Finds a series of IWeaveTreeNode objects which can be traversed as a path to a descendant node.
		 * @param descendant The descendant IWeaveTreeNode.
		 * @return An Array of IWeaveTreeNode objects which can be followed as a path from this node to the descendant, including this node and the descendant node.
		 *         Returns null if the descendant is unreachable from this node.
		 */
		function findPathToNode(descendant:IWeaveTreeNode):Array;
    }
}
