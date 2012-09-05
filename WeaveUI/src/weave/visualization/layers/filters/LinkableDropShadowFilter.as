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

package weave.visualization.layers.filters
{
	import flash.filters.DropShadowFilter;
	
	import weave.api.core.ILinkableObject;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableNumber;

	/**
	 * @author adufilie
	 */
	public class LinkableDropShadowFilter implements ILinkableObject
	{
		public function LinkableDropShadowFilter(distance:Number=4, angle:Number=45, color:Number=0, alpha:Number=1, blurX:Number=4, blurY:Number=4, strength:Number=1)
		{
			this.distance.value = distance;
			this.angle.value = angle;
			this.color.value = color;
			this.alpha.value = alpha;
			this.blurX.value = blurX;
			this.blurY.value = blurY;
			this.strength.value = strength;
		}
		
		private function verifyAlpha(value:Number):Boolean { return 0 <= value && value <= 1; }
		
		public const distance:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const angle:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const color:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0, isFinite));
		public const alpha:LinkableNumber = registerLinkableChild(this, new LinkableNumber(1, verifyAlpha));
		public const blurX:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const blurY:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const strength:LinkableNumber = newLinkableChild(this, LinkableNumber);
		
		public function copyTo(target:DropShadowFilter):void
		{
			target.distance = distance.value;
			target.angle = angle.value;
			target.color = color.value;
			target.alpha = alpha.value;
			target.blurX = blurX.value;
			target.blurY = blurY.value;
			target.strength = strength.value;
		}
	}
}
