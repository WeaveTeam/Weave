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
			detectChanges();
			if (_sessionStateInternal && typeof _sessionStateInternal == 'object')
			{
				tempBounds.xMin = StandardLib.asNumber(_sessionStateInternal.xMin);
				tempBounds.yMin = StandardLib.asNumber(_sessionStateInternal.yMin);
				tempBounds.xMax = StandardLib.asNumber(_sessionStateInternal.xMax);
				tempBounds.yMax = StandardLib.asNumber(_sessionStateInternal.yMax);
			}
			destinationBounds.copyFrom(tempBounds);
		}
	}
}
