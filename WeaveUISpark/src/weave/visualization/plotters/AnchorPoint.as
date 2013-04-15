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

package weave.visualization.plotters
{	
	import weave.api.core.ILinkableObject;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;

	/**
	 * AnchorPoint
	 * @author kmanohar
	 */	
	public class AnchorPoint implements ILinkableObject
	{
		public const x:LinkableNumber = newLinkableChild(this,LinkableNumber,convertCoords);
		public const y:LinkableNumber = newLinkableChild(this,LinkableNumber,convertCoords);		
		
		public const polarRadians:LinkableNumber = newLinkableChild(this,LinkableNumber);
		public const radius:LinkableNumber = newLinkableChild(this,LinkableNumber);
		public const title:LinkableString = newLinkableChild(this, LinkableString);
		
		public function AnchorPoint()
		{
		}
		
		private function convertCoords():void
		{
			var xval:Number = x.value; 
			var yval:Number = y.value;
			
			radius.value = Math.sqrt(xval * xval + yval * yval);

			var pi:Number = Math.PI;
			polarRadians.value = Math.atan2(yval,xval);
			if( polarRadians.value < 0 )
				polarRadians.value += 2 * pi;				
		}
	}
}
