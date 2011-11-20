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

package weave.utils
{
	import weave.primitives.Range;
	
	/**
	 * This class contains functions that manipulate Numbers.
	 * 
	 * @author adufilie
	 */
	public class NumberUtils
	{
		/**
		 * generateBins
		 * @return an array of Range objects, with values evenly distributed between min and max
		 */
		public static function generateBins(min:Number, max:Number, divisions:Number):Array
		{
			var coverage:Number = max - min;
			var rangeList:Array = [];
			for (var i:int = 0; i < divisions; i++)
				rangeList[i] = new Range(
						min + i / divisions * coverage,
						min + (i + 1) / divisions * coverage
					);
			return rangeList;
		}
		
		/**
		 * This function verifies that the given String can be parsed as a finite Number optionally appended with a percent sign.
		 * @param numberOrPercent A String to verify.
		 * @return A value of true if the String can be parsed as a finite Number or percentage value.
		 */
		public static function verifyNumberOrPercentage(value:String):Boolean
		{
			try
			{
				// don't accept null or empty string
				if (!value)
					return false;
				if (value.substr(-1) == '%')
					return isFinite(Number(value.substr(0, -1)));
				return isFinite(Number(value));
			}
			catch (e:Error)
			{
				// failed to parse number
			}
			return false;
		}
		
		/**
		 * getNumberFromNumberOrPercent
		 * This function will convert a String like "75%" into a Number using the calculation "whole * percent / 100".
		 * If the String does not have a "%" sign in it, it will be treated as an absolute number.
		 * @param numberOrPercent
		 *     This string can be either a number like "640" or a percentage like "50%".
		 * @param wholeForPercentage
		 *     If the 'numberOrPercent' parameter contains the '%' sign, this will be used as the 'whole' value used in the calculation.
		 * @return
		 *     The 'numberOrPercent' parameter as a Number if it does not have a '%' sign, or (whole * percent / 100) if it does.
		 */
		public static function getNumberFromNumberOrPercent(numberOrPercent:String, wholeForPercentage:Number):Number
		{
			try
			{
				if (numberOrPercent.search("%") >= 0) // percentage
					return wholeForPercentage * Number(numberOrPercent.replace("%", "")) / 100;
				else // absolute
					return Number(numberOrPercent);
			}
			catch (e:Error) { }
			
			return NaN;
		}
	}
}
