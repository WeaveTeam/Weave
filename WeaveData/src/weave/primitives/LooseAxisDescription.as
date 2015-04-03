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
	import weave.compiler.StandardLib;
	
	/**
	 * code adapted from the UVP
	 * given:
	 *    info about our data
	 *    numTicksReq, dataMin, dataMax
	 * we calculate:
	 *    what our axis will look like
	 *    tickMin, tickMax, tickDelta
	 *    axisMin, axisMax,
     *    numTicks and numDigits
	 * 
	 * @author sanbalagan
	 */
	public class LooseAxisDescription
	{
		private var _dataMin:Number;
		private var _dataMax:Number;
		private var _numTicksReq:Number;
		
		private var _range:Number;
		private var _tickMin:Number;
		private var _tickMax:Number;
		private var _tickDelta:Number;
		private var _axisMin:Number;
		private var _axisMax:Number;
		private var _numTicks:Number;
		private var _numDigits:Number;
				
		public function LooseAxisDescription(dataMin:Number = NaN, dataMax:Number = NaN, numTicksReq:Number = 5)
		{
			if (!isNaN(dataMin) && !isNaN(dataMax))
				setup(dataMin,dataMax,numTicksReq);
		}
		
		public function setup(dataMin:Number, dataMax:Number, numTicksReq:Number, forceTickCount:Boolean = false):void
		{
			_dataMin = dataMin;
			_dataMax = dataMax;
			_numTicksReq = numTicksReq;
			
			if (forceTickCount)
			{
				_numTicks = _numTicksReq;
				
				if (_dataMin == _dataMax)
				{
					_range = 0;
					_tickDelta = _tickMin = _tickMax = _dataMin;
				}
				else
				{
					_range = _dataMax - _dataMin;
					_tickDelta = _range / (_numTicksReq - 1);
					_tickMin = Math.floor(_dataMin / _tickDelta) * _tickDelta;
					_tickMax = Math.ceil(_dataMax / _tickDelta) * _tickDelta;
				}
				_axisMin = _tickMin - (.5 * _tickDelta);
				_axisMax = _tickMax + (.5 * _tickDelta);
			}
			else
			{
				var ticks:Array = StandardLib.getNiceNumbersInRange(dataMin, dataMax, numTicksReq);
				
				_numTicks = ticks.length;
				
				_tickMin = ticks[0];
				_tickMax = ticks[ticks.length - 1];
				
				_range = _tickMax - _tickMin;
				
				// special case
				if (ticks.length < 2)
					_tickDelta = 0;
				else
					_tickDelta = ticks[1] - ticks[0];
				
				_axisMin = _tickMin - (.5 * _tickDelta);
				_axisMax = _tickMax + (.5 * _tickDelta);
			}
			
			_numDigits = forceTickCount ? -1 : Math.max(-Math.floor(Math.log(_tickDelta) / Math.LN10), 0.0);
		}
		
		public function get range():Number
		{
			return _range;
		}
		public function get tickMin():Number{
			return _tickMin;
		}
		public function get tickMax():Number{
			return _tickMax;
		}
		public function get tickDelta():Number{
			return _tickDelta;
		}
		public function get axisMin():Number{
			return _axisMin;
		}
		public function get axisMax():Number{
			return _axisMax;
		}
		public function get numberOfTicks():Number{
			return _numTicks;
		}
		public function get numberOfDigits():Number{
			return _numDigits;
		}
		
		public function get dataMin():Number{
			return _dataMin;
		}
		
		public function get dataMax():Number{
			return _dataMax;
		}
		
		public function get numberOfTicksRequested():Number{
			return _numTicksReq;
		}
	}
}