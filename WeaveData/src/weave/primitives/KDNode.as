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
		
		/**
		 * An Array of additional nodes having identical keys
		 */
		public var siblings:Array;
	}
}
