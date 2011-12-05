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
	import weave.api.core.ILinkableObject;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.setSessionState;
	import weave.core.LinkableNumber;
	
	/**
	 * This is a linkable version of a Bounds2D object.
	 * 
	 * @author adufilie
	 */
	public class LinkableBounds2D implements ILinkableObject
	{
		public function LinkableBounds2D()
		{
		}
		
		public const xMin:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const yMin:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const xMax:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const yMax:LinkableNumber = newLinkableChild(this, LinkableNumber);
		
		public function setBounds(xMin:Number, yMin:Number, xMax:Number, yMax:Number):void
		{
			tempBounds.setBounds(xMin, yMin, xMax, yMax);
			copyFrom(tempBounds);
		}
		private static const tempBounds:IBounds2D = new Bounds2D(); // reusable temporary object
		
		public function copyFrom(sourceBounds:IBounds2D):void
		{
			//TODO: do this manually instead of calling setSessionState
			setSessionState(this, sourceBounds, false);
		}
		
		public function copyTo(destinationBounds:IBounds2D):void
		{
			destinationBounds.setBounds(xMin.value, yMin.value, xMax.value, yMax.value);
		}
	}
}
