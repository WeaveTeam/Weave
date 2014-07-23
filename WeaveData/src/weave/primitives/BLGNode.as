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
		
		public function toString():String
		{
			return [index,importance,x,y].toString();
		}
	}
}
