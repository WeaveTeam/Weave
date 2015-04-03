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
