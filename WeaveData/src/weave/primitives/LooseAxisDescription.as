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
	import weave.compiler.MathLib;
	/**
	 * LooseAxisDescription
	 * 
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
			this._dataMin = dataMin;
			this._dataMax = dataMax;
			this._numTicksReq = numTicksReq;
			
			if(forceTickCount)
			{
				_numTicks = _numTicksReq;
				
				_range = _dataMax - _dataMin;
				
				_tickDelta = _range / (_numTicksReq - 1);
				_tickMin = Math.floor (_dataMin / _tickDelta) * _tickDelta;
				_tickMax = Math.ceil (_dataMax / _tickDelta) * _tickDelta;
				_axisMin = _tickMin - (.5 * _tickDelta);
				_axisMax = _tickMax + (.5 * _tickDelta);
			}
			else
			{
				/*
				 
			
				_range = MathLib.getNiceNumber(_dataMax - _dataMin, false);
				
				trace(_range, _dataMin, "->", MathLib.getNiceNumber(_dataMin, false), _dataMax, "->", MathLib.getNiceNumber(_dataMax, false) );
				
				_tickDelta = MathLib.getNiceNumber(_range / (_numTicksReq - 1), true);
				_tickMin = Math.floor (_dataMin / _tickDelta) * _tickDelta;
				_tickMax = Math.ceil (_dataMax / _tickDelta) * _tickDelta;
				_axisMin = _tickMin - (.5 * _tickDelta);
				_axisMax = _tickMax + (.5 * _tickDelta);
				
				_numTicks = Math.ceil( (_tickMax - _tickMin) / _tickDelta ) + 1;
				
				if (_numTicks > _numTicksReq)
				{
					_numTicks = _numTicksReq;
				}*/
				
				
				
				var ticks:Array = MathLib.getNiceNumbersInRange(dataMin, dataMax, numTicksReq);
				
				_numTicks = ticks.length;
				
				_tickMin = ticks[0];
				_tickMax = ticks[ticks.length-1];
				
				_range = _tickMax - _tickMin;
				
				_tickDelta = ticks[1] - ticks[0];
				
				_axisMin = _tickMin - (.5 * _tickDelta);
				_axisMax = _tickMax + (.5 * _tickDelta);
			}
			
			_numDigits = Math.max(-Math.floor((Math.log(_tickDelta))/(Math.LN10)),0.0);
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