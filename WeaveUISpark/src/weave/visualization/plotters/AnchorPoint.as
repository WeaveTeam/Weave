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

package weave.visualization.plotters
{	
	import weave.api.core.ILinkableObject;
	import weave.api.newLinkableChild;
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
		//public const anchorColor:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const title:LinkableString = newLinkableChild(this, LinkableString);
		
		//metric used to calculate the class discrimiation for eg t-stat, p value, mean ratio etc
		public const classDiscriminationMetric:LinkableNumber = newLinkableChild(this,LinkableNumber);
		
		//is the class to which an anchor belongs after the class discimination algorithm is done
		public const classType:LinkableString = newLinkableChild(this, LinkableString);
		
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
