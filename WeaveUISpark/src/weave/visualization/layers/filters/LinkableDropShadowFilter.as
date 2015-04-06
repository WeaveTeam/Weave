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
