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

package weavejs.geom
{
	/**
	 * BLGNode
	 * Binary Line Generalization Tree Node
	 * This class defines a structure to represent a streamed polygon vertex.
	 * 
	 * Reference: van Oosterom, P. 1990. Reactive data structures
	 *  for geographic information systems. PhD thesis, Department
	 *  of Computer Science, Leiden University, The Netherlands.
	 * 
	 * 
	 * @author adufilie
	 */
	public class BLGNode
	{
		public function BLGNode(index:int, importance:Number, x:Number, y:Number)
		{
			this.index = index;
			this.importance = importance;
			this.x = x;
			this.y = y;
			this.left = null;
			this.right = null;
		}

		/**
		 * These properties are made public for speed concerns, though they should not be modified.
		 */
		public var index:int;
		public var importance:Number;
		public var x:Number;
		public var y:Number;

		// left child node
		public var left:BLGNode = null;

		// right child node
		public var right:BLGNode = null;
	}
}
