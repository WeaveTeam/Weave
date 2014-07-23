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
	import weave.api.primitives.IBounds2D;
	import weave.compiler.StandardLib;
	import weave.core.LinkableVariable;
	
	/**
	 * This is a linkable version of a Bounds2D object.
	 * 
	 * @author adufilie
	 */
	public class LinkableBounds2D extends LinkableVariable
	{
		public function setBounds(xMin:Number, yMin:Number, xMax:Number, yMax:Number):void
		{
			tempBounds.setBounds(xMin, yMin, xMax, yMax);
			setSessionState(tempBounds);
		}
		private static const tempBounds:Bounds2D = new Bounds2D(); // reusable temporary object
		
		public function copyFrom(sourceBounds:IBounds2D):void
		{
			tempBounds.copyFrom(sourceBounds);
			setSessionState(tempBounds);
		}
		
		public function copyTo(destinationBounds:IBounds2D):void
		{
			tempBounds.reset();
			if (_sessionState)
			{
				tempBounds.xMin = StandardLib.asNumber(_sessionState.xMin);
				tempBounds.yMin = StandardLib.asNumber(_sessionState.yMin);
				tempBounds.xMax = StandardLib.asNumber(_sessionState.xMax);
				tempBounds.yMax = StandardLib.asNumber(_sessionState.yMax);
			}
			destinationBounds.copyFrom(tempBounds);
		}
	}
}
