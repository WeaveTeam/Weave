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
		public static function verifyNumberOrPercentage(numberOrPercent:String):Boolean
		{
			try
			{
				// don't accept null or empty string
				if (!numberOrPercent)
					return false;
				if (numberOrPercent.substr(-1) == '%')
					return isFinite(Number(numberOrPercent.substr(0, -1)));
				return isFinite(Number(numberOrPercent));
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
				if (numberOrPercent.substr(-1) == '%') // percentage
					return wholeForPercentage * Number(numberOrPercent.substr(0, -1)) / 100;
				else // absolute
					return Number(numberOrPercent);
			}
			catch (e:Error) { }
			
			return NaN;
		}
	}
}
