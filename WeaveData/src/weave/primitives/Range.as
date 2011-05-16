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
	/**
	 * Range
	 * This class defines a 1-dimensional continuous range of values by begin & end values.
	 * The difference between the begin and end values can be either positive or negative.
	 * 
	 * @author adufilie
	 */
	public class Range
	{
		public function Range(begin:Number = NaN, end:Number = NaN)
		{
			this.begin = begin;
			this.end = end;
		}

		/**
		 * begin & end
		 * These values define the range of values covered by this Range object.
		 * The difference between begin & end can be either positive or negative.
		 */
		public var begin:Number;
		public var end:Number;

		/**
		 * normalize
		 * @param value A number within this Range
		 * @return A number in the range [0,1]
		 */
		public function normalize(value:Number):Number
		{
			if (value == end)
				return 1;
			return (value - begin) / (end - begin);
		}
		/**
		 * denormalize
		 * @param A number in the range [0,1]
		 * @return A number within this Range
		 */
		public function denormalize(value:Number):Number
		{
			return begin + (end - begin) * value;
		}
		
		/**
		 * min & max
		 * These are the numeric min,max values of the range.
		 */
		public function get min():Number
		{
			return Math.min(begin, end);
		}
		public function get max():Number
		{
			return Math.max(begin, end);
		}
		
		/**
		 * coverage:
		 * The coverage of a Range is defined by the positive distance
		 * from the min numeric value to the max numeric value.
		 */
		public function get coverage():Number
		{
			return Math.abs(end - begin);
		}

		/**
		 * setRange:
		 * @param begin The new begin value.
		 * @param end The new end value.
		 */
		public function setRange(begin:Number, end:Number):void
		{
			this.begin = begin;
			this.end = end;
		}

		/**
		 * offset:
		 * This will shift the begin and end values by a delta value.
		 */
		public function offset(delta:Number):void
		{
			begin += delta;
			end += delta;
		}		

		/**
		 * constrain:
		 * This function will constrain a value to be within this Range.
		 * @return A number contained in this Range.
		 */
		public function constrain(value:Number):Number
		{
			if (begin < end)
				return Math.max(begin, Math.min(value, end));
			return Math.max(end, Math.min(value, begin));
		}

		/**
		 * contains
		 * @param value A number to check
		 * @return true if the given value is within this Range
		 */
		public function contains(value:Number):Boolean
		{
			if (begin < end)
				return begin <= value && value <= end;
			return end <= value && value <= begin;
		}

		/**
		 * compare
		 * @param value A number to check
		 * @return -1 if value < min, 1 if value > max, 0 if min <= value <= max, or NaN otherwise
		 */
		public function compare(value:Number):Number
		{
			var min:Number = this.min;
			var max:Number = this.max;
			if (value < min)
				return -1;
			if (value > max)
				return 1;
			if (min <= value && value <= max)
				return 0;
			return NaN;
		}

		/**
		 * constrainRange:
		 * This function will reposition another Range object
		 * such that one range will completely contain the other.
		 * @param rangeToConstrain The range to be repositioned.
		 * @param allowShrinking If set to true, the rangeToConstrain may be resized to fit within this range.
		 */
		public function constrainRange(rangeToConstrain:Range, allowShrinking:Boolean = false):void
		{
			// don't constrain if this range is NaN
			if (isNaN(this.coverage))
				return;

			if (rangeToConstrain.coverage < this.coverage) // if rangeToConstrain can fit within this Range
			{
				// shift rangeToConstrain enough so it is contained within this Range.
				if (rangeToConstrain.min < this.min)
					rangeToConstrain.offset(this.min - rangeToConstrain.min);
				else if (rangeToConstrain.max > this.max)
					rangeToConstrain.offset(this.max - rangeToConstrain.max);
			}
			else if (allowShrinking)
			{
				// rangeToConstrain should be resized to fit within this Range.
				rangeToConstrain.setRange(this.begin, this.end);
			}
			else // rangeToConstrain has a larger coverage (does not fit within this Range)
			{
				// shift rangeToConstrain enough so it contains this Range
				if (rangeToConstrain.min > this.min)
					rangeToConstrain.offset(this.min - rangeToConstrain.min);
				else if (rangeToConstrain.max < this.max)
					rangeToConstrain.offset(this.max - rangeToConstrain.max);
			}
		}
		
		public function toString():String
		{
			return "["+begin.toFixed(2)+" to "+end.toFixed(2)+"]";
		}
	}
}
