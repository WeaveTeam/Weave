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

package org.oicweave.compiler
{
	import flash.utils.describeType;

	/**
	 * This provides a set of static functions that take Numbers as arguments and return Numbers.
	 * 
	 * @author adufilie
	 */
	public class MathLib
	{
		/**
		 * This function will cast a value of any type to a Number,
		 * interpreting the empty string ("") and null as NaN.
		 * @param value A value to cast to a Number.
		 * @return The value cast to a Number, or NaN if the casting failed.
		 */
		public static function toNumber(value:*):Number
		{
			if (value == null)
				return NaN; // return NaN, because Number(null) == 0
			
			if (value is Number)
				return value;
			
			try {
				value = String(value);
				if (value == '')
					return NaN;
				return Number(value);
			} catch (e:Error) { }

			return NaN;
		}
		
		/**
		 * neg,add,sub,mul,div,mod
		 * These basic functions correspond to math operators -+*%/.  Then are here for EquationParser to use.
		 */
		public static function neg(x:Number):Number { return -x; };
		public static function add(x:Number, y:Number):Number { return x + y; };
		public static function sub(x:Number, y:Number):Number { return x - y; };
		public static function mul(x:Number, y:Number):Number { return x * y; };
		public static function div(x:Number, y:Number):Number { return x / y; };
		public static function mod(x:Number, y:Number):Number { return x % y; };
		
		/**
		 * This function returns -1 if the given value is negative, and 1 otherwise.
		 * @param value A value to test.
		 * @return -1 if value < 0, 1 otherwise
		 */
		public static function sign(value:Number):Number
		{
			if (value < 0)
				return -1;
			return 1;
		}
		
		/**
		 * This function constrains a number between min and max values.
		 * @param value A value to constrain between a min and max.
		 * @param min The minimum value.
		 * @param max The maximum value.
		 * @return If value < min, returns min.  If value > max, returns max.  Otherwise, returns value.
		 */
		public static function constrain(value:Number, min:Number, max:Number):Number
		{
			if (value < min)
				return min;
			if (value > max)
				return max;
			return value;
		}
		
		/**
		 * This function filters out values outside of a given range.
		 * @param value A value to filter.
		 * @param min The minimum value to accept.
		 * @param max The maximum value to accept.
		 * @return If value is between min and max, returns value.  Otherwise, returns NaN.
		 */
		public static function filterRange(value:Number, min:Number, max:Number):Number
		{
			if (value < min || value > max)
				return NaN;
			return value;
		}
		
		/**
		 * This function tests if a Number is within a min,max range.
		 * @param value A value to filter.
		 * @param min The minimum value to accept.
		 * @param max The maximum value to accept.
		 * @return If value is between min and max, returns true.  Otherwise, returns false.
		 */
		public static function inRange(value:Number, min:Number, max:Number):Boolean
		{
			if (value < min || value > max)
				return false;
			return true;
		}
		
		/**
		 * @param value The value between min and max.
		 * @param min The minimum value that corresponds to a result of 0.
		 * @param max The maximum value that corresponds to a result of 1.
		 * @param The normalized value between 0 and 1, or NaN if value is out of range.
		 */
		public static function normalize(value:Number, min:Number, max:Number):Number
		{
			if (value < min || value > max)
				return NaN;
			return (value - min) / (max - min);
		}

		/**
		 * This function performs a linear scaling of a value from an input min,max range to an output min,max range.
		 * @param inputValue A value to scale.
		 * @param inputMin The minimum value in the input range.
		 * @param inputMax The maximum value in the input range.
		 * @param outputMin The minimum value in the output range.
		 * @param outputMax The maximum value in the output range.
		 * @param The input value rescaled such that a value equal to inputMin is scaled to outputMin and a value equal to inputMax is scaled to outputMax.
		 */
		public static function scale(inputValue:Number, inputMin:Number, inputMax:Number, outputMin:Number, outputMax:Number):Number
		{
			return outputMin + (outputMax - outputMin) * (inputValue - inputMin) / (inputMax - inputMin);
		}

		/**
		 * This rounds a Number to a given number of significant digits.
		 * @param value A value to round.
		 * @param significantDigits The desired number of significant digits in the result.
		 * @return The number, rounded to the specified number of significant digits.
		 */
		public static function roundSignificant(value:Number, significantDigits:uint = 15):Number
		{
			// it doesn't make sense to round infinity
			if (isNaN(value) || value == Number.NEGATIVE_INFINITY || value == Number.POSITIVE_INFINITY)
				return value;
			
			var sign:Number = (value < 0) ? -1 : 1;
			var absValue:Number = Math.abs(value);
			var pow10:Number;
			
			// if absValue is less than 1, all digits after the decimal point are significant
			if (absValue < 1)
			{
				pow10 = Math.pow(10, significantDigits);
				//trace("absValue<1: Math.round(",absValue,"*",pow10,")",Math.round(absValue * pow10));
				return sign * Math.round(absValue * pow10) / pow10;
			}
			
			var log10:Number = Math.ceil(Math.log(absValue) / Math.LN10);
			
			// Both these calculations are equivalent mathematically, but if we use
			// the wrong one we get bad rounding results like "123.456000000001".
			if (log10 < significantDigits)
			{
				// find the power of 10 that you need to MULTIPLY absValue by
				// so Math.round() will round off the digits we don't want
				pow10 = Math.pow(10, significantDigits - log10);
				return sign * Math.round(absValue * pow10) / pow10;
			}
			else
			{
				// find the power of 10 that you need to DIVIDE absValue by
				// so Math.round() will round off the digits we don't want
				pow10 = Math.pow(10, log10 - significantDigits);
				//trace("log10>significantDigits: Math.round(",absValue,"/",pow10,")",Math.round(absValue / pow10));
				return sign * Math.round(absValue / pow10) * pow10;
			}
		}
//		private static var testResult:* = testRoundSignificant();
//		private static function testRoundSignificant():*
//		{
//			for (var pow:int = -5; pow <= 5; pow++)
//			{
//				var n:Number = 1234.5678 * Math.pow(10, pow);
//				for (var d:int = 0; d <= 9; d++)
//					trace('roundSignificant(',n,',',d,') =',roundSignificant(n, d));
//			}
//		}

		/**
		 * @param normValue A Number between 0 and 1.
		 * @param minColor A color associated with a value of 0.
		 * @param maxColor A color associated with a value of 1.
		 * @return An interpolated color associated with the given normValue based on the min,max color values.
		 */
		public static function interpolateColor(normValue:Number, minColor:int, maxColor:int):Number
		{
			if (normValue < 0 || normValue > 1)
				return NaN;
			
			var percentLeft:Number = 1 - normValue; // relevance of minColor
			var percentRight:Number = normValue; // relevance of maxColor
			const R:int = 0xFF0000;
			const G:int = 0x00FF00;
			const B:int = 0x0000FF;
			return (
				((percentLeft * (minColor & R) + percentRight * (maxColor & R)) & R) |
				((percentLeft * (minColor & G) + percentRight * (maxColor & G)) & G) |
				((percentLeft * (minColor & B) + percentRight * (maxColor & B)) & B)
			);
		}
		
		/**
		 * Code from Graphics Gems Volume 1
		 */
		public static function getNiceNumber(x:Number, round:Boolean):Number
		{
			var exponent:Number;
			var fractionalPart:Number;
			var niceFractionalPart:Number;
			
			// special case for nice number of 0, since Math.log(0) is -Infinity
			if(x == 0)
				return 0;
			
			exponent = Math.floor( Math.log( x ) / Math.LN10 );
			fractionalPart = x / Math.pow( 10.0, exponent );
			
			if( round ) {
				if( fractionalPart < 1.5 ) {
					niceFractionalPart = 1.0;
				} else if( fractionalPart < 3.0 ) {
					niceFractionalPart = 2.0;
				} else if( fractionalPart < 7.0 ) {
					niceFractionalPart = 5.0;
				} else {
					niceFractionalPart = 10.0;
				}
			} else {
				if( fractionalPart <= 1.0 ) {
					niceFractionalPart = 1.0;
				} else if( fractionalPart <= 2.0 ) {
					niceFractionalPart = 2.0;
				} else if( fractionalPart < 5.0 ) {
					niceFractionalPart = 5.0;
				} else {
					niceFractionalPart = 10.0;
				}
			}
			
			return niceFractionalPart * Math.pow( 10.0, exponent );
		}
		
		/**
		 * Code from Graphics Gems Volume 1
		 */
		public static function getNiceNumbersInRange(min:Number, max:Number, numberOfValuesInRange:int):Array
		{
			var nfrac:int;
			var d:Number;
			var graphmin:Number;
			var graphmax:Number;
			var range:Number;
			var x:Number;
			var i:int = 0;
			
			var values:Array = [];
			
			range = getNiceNumber(max - min, false);
			d = getNiceNumber( range / (numberOfValuesInRange - 1), true);
			graphmin = Math.floor(min / d) * d;
			graphmax = Math.ceil(max / d) * d;
			
			nfrac = Math.max(-Math.floor(Math.log(d)/Math.LN10), 0);
			
			for(x = graphmin; x < graphmax + 0.5*d; x += d)
			{
				values[i++] = x;
			}
			
			return values;
		}
	}
}
