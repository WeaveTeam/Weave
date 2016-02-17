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

package weavejs.geom
{
	import weavejs.core.LinkableVariable;
	import weavejs.geom.Bounds2D;
	import weavejs.util.StandardLib;
	
	/**
	 * This is a linkable version of a Bounds2D object.
	 * 
	 * @author adufilie
	 */
	public class LinkableBounds2D extends LinkableVariable
	{
		public function LinkableBounds2D()
		{
			super(null, null, tempBounds);
		}
		
		override public function setSessionState(value:Object):void
		{
			if (typeof value !== 'object' && value)
			{
				tempBounds.setBounds(
					StandardLib.asNumber(value.xMin),
					StandardLib.asNumber(value.yMin),
					StandardLib.asNumber(value.xMax),
					StandardLib.asNumber(value.yMax)
				);
			}
			else
			{
				tempBounds.setBounds(NaN, NaN, NaN, NaN);
			}
			super.setSessionState(tempBounds);
		}
		
		public function get xMin():Number { return this._sessionStateInternal.xMin; }
		public function get yMin():Number { return this._sessionStateInternal.yMin; }
		public function get xMax():Number { return this._sessionStateInternal.xMax; }
		public function get yMax():Number { return this._sessionStateInternal.yMax; }
		
		public function set xMin(value:Number):void { this._sessionStateExternal.xMin = value; detectChanges(); }
		public function set yMin(value:Number):void { this._sessionStateExternal.yMin = value; detectChanges(); }
		public function set xMax(value:Number):void { this._sessionStateExternal.xMax = value; detectChanges(); }
		public function set yMax(value:Number):void { this._sessionStateExternal.yMax = value; detectChanges(); }
		
		public function setBounds(xMin:Number, yMin:Number, xMax:Number, yMax:Number):void
		{
			tempBounds.setBounds(xMin, yMin, xMax, yMax);
			setSessionState(tempBounds);
		}
		private static const tempBounds:Bounds2D = new Bounds2D(); // reusable temporary object
		
		public function copyFrom(sourceBounds:Bounds2D):void
		{
			tempBounds.copyFrom(sourceBounds);
			setSessionState(tempBounds);
		}
		
		public function copyTo(destinationBounds:Bounds2D):void
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
