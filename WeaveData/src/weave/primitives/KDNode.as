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
		public const key:Array = [];

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
