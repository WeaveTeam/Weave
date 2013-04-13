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

package weave.compiler
{
	import flash.utils.getQualifiedClassName;
	
	import mx.formatters.DateFormatter;
	import mx.formatters.NumberFormatter;
	import mx.utils.ObjectUtil;
	
	import weave.utils.AsyncSort;
	import weave.utils.DebugTimer;

	/**
	 * This provides a set of useful static functions.
	 * All the functions defined in this class are pure functions, meaning they always return the same result with the same arguments, and they have no side-effects.
	 * 
	 * @author adufilie
	 */
	public class StandardLib
	{
		/**
		 * This function will cast a value of any type to a Number,
		 * interpreting the empty string ("") and null as NaN.
		 * @param value A value to cast to a Number.
		 * @return The value cast to a Number, or NaN if the casting failed.
		 */
		public static function asNumber(value:*):Number
		{
			if (value == null)
				return NaN; // return NaN because Number(null) == 0
			
			if (value is Number)
				return value;
			
			try {
				value = String(value);
				if (value == '')
					return NaN; // return NaN because Number('') == 0
				return Number(value);
			} catch (e:Error) { }

			return NaN;
		}
		
		/**
		 * @param value A value to cast to a String.
		 * @return The value cast to a String.
		 */
		public static function asString(value:*):String
		{
			if (value == null)
				return '';
			try
			{
				return value;
			}
			catch (e:Error) { }
			return '';
		}
		
		/**
		 * This function attempts to derive a boolean value from different types of objects.
		 * @param value An object to parse as a Boolean.
		 */
		public static function asBoolean(value:*):Boolean
		{
			if (value is Boolean)
				return value;
			if (value is String)
				return ObjectUtil.stringCompare(value, "true", true) == 0;
			if (isNaN(value))
				return false;
			if (value is Number)
				return value != 0;
			return value;
		}
		
		public static function isDefined(value:*):Boolean
		{
			return !(value == undefined || (value is Number && isNaN(value)) || value == null);
		}
		public static function isUndefined(value:*):Boolean
		{
			return (value == undefined || (value is Number && isNaN(value)) || value == null);
		}
		
		public static function lpad(str:String, length:uint, padString:String = ' '):String
		{
			if (str.length >= length)
				return str;
			while (str.length + padString.length < length)
				padString += padString;
			return padString.substr(0, length - str.length) + str;
		}
		public static function rpad(str:String, length:uint, padString:String = ' '):String
		{
			if (str.length >= length)
				return str;
			while (str.length + padString.length < length)
				padString += padString;
			return str + padString.substr(0, length - str.length);
		}
		
		/**
		 * This function performs find and replace operations on a String.
		 * @param string A String to perform replacements on.
		 * @param findStr A String to find.
		 * @param replaceStr A String to replace occurrances of the 'findStr' String with.
		 * @param moreFindAndReplace A list of additional find,replace parameters to use.
		 * @return The String with all the specified replacements performed.
		 */
		public static function replace(string:String, findStr:String, replaceStr:String, ...moreFindAndReplace):String
		{
			string = string.split(findStr).join(replaceStr);
			while (moreFindAndReplace.length > 1)
			{
				findStr = moreFindAndReplace.shift();
				replaceStr = moreFindAndReplace.shift();
				string = string.split(findStr).join(replaceStr);
			}
			return string;
		}
		
		/**
		 * Substitutes "{n}" tokens within the specified string with the respective arguments passed in.
		 * Same syntax as StringUtil.substitute() without the side-effects of using String.replace() with a regex.
		 * @see String#replace()
		 * @see mx.utils.StringUtil#substitute()
		 */
		public static function substitute(format:String, ...args):String
		{
			for (var i:int = 0; i < args.length; i++)
			{
				var str:String = '{' + i + '}';
				var j:int = int.MAX_VALUE;
				while ((j = format.lastIndexOf(str, j)) >= 0)
					format = format.substr(0, j) + args[i] + format.substr(j + str.length);
			}
			return format;
		}
		
		/**
		 * @param number The Number to convert to a String.
		 * @param base Specifies the numeric base (from 2 to 36) to use.
		 * @param zeroPad This is the minimum number of digits to return.  The number will be padded with zeros if necessary.
		 * @return The String representation of the number using the specified numeric base.
		 */
		public static function numberToBase(number:Number, base:int = 10, zeroPad:int = 1):String
		{
			var parts:Array = Math.abs(number).toString(base).split('.');
			if (parts[0].length < zeroPad)
				parts[0] = lpad(parts[0], zeroPad, '0');
			if (number < 0)
				parts[0] = '-' + parts[0];
			return parts.join('.');
		}
		
		/**
		 * This function will use a default NumberFormatter object to format a Number to a String.
		 * @param number The number to format.
		 * @param precision A precision value to pass to the default NumberFormatter.
		 * @return The result of format(number) using the specified precision value.
		 * @see mx.formatters.NumberFormatter#format
		 */
		public static function formatNumber(number:Number, precision:Number = NaN):String
		{
			if (isFinite(precision))
			{
				_numberFormatter.precision = uint(precision);
			}
			else
			{
				if (Math.abs(number) < 1)
					return String(number); // this fixes the bug where "0.1" gets converted to ".1" (we don't want the "0" to be lost)
				_numberFormatter.precision = -1;
			}
			
			return _numberFormatter.format(number);
		}
		
		/**
		 * This is the default NumberFormatter to use inside the formatNumber() function.
		 */
		private static const _numberFormatter:NumberFormatter = new NumberFormatter();

		/**
		 * This function returns -1 if the given value is negative, and 1 otherwise.
		 * @param value A value to test.
		 * @return -1 if value &lt; 0, 1 otherwise
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
		 * @return If value &lt; min, returns min.  If value &gt; max, returns max.  Otherwise, returns value.
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
		public static function numberInRange(value:Number, min:Number, max:Number):Boolean
		{
			if (value < min || value > max) // a condition will be false if a value is NaN
				return false;
			return true;
		}
		
		/**
		 * @param value The value between min and max.
		 * @param min The minimum value that corresponds to a result of 0.
		 * @param max The maximum value that corresponds to a result of 1.
		 * @return The normalized value between 0 and 1, or NaN if value is out of range.
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
		 * @return The input value rescaled such that a value equal to inputMin is scaled to outputMin and a value equal to inputMax is scaled to outputMax.
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
		public static function roundSignificant(value:Number, significantDigits:uint = 14):Number
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
		
//		{ /** begin static code block **/
//			testRoundSignificant();
//		} /** end static code block **/
		private static function testRoundSignificant():void
		{
			for (var pow:int = -5; pow <= 5; pow++)
			{
				var n:Number = 1234.5678 * Math.pow(10, pow);
				for (var d:int = 0; d <= 9; d++)
					trace('roundSignificant(',n,',',d,') =',roundSignificant(n, d));
			}
		}

		/**
		 * @param normValue A Number between 0 and 1.
		 * @param colors An Array or list of colors to interpolate between.  Normalized values of 0 and 1 will be mapped to the first and last colors.
		 * @return An interpolated color associated with the given normValue based on the min,max color values.
		 */
		public static function interpolateColor(normValue:Number, ...colors):Number
		{
			// handle an array of colors as the second parameter
			if (colors.length == 1 && colors[0] is Array)
				colors = colors[0];
			
			// handle invalid parameters
			if (normValue < 0 || normValue > 1 || colors.length == 0)
				return NaN;
			
			// find the min and max colors we want to interpolate between
			
			var maxIndex:int = colors.length - 1;
			var leftIndex:int = maxIndex * normValue;
			var rightIndex:int = leftIndex + 1;
			
			// handle boundary condition
			if (rightIndex == colors.length)
				return colors[leftIndex];
			
			var minColor:Number = colors[leftIndex];
			var maxColor:Number = colors[rightIndex];
			// normalize the norm value between the two norm values associated with the surrounding colors
			normValue = normValue * maxIndex - leftIndex;
			
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
		 * Note: This may return less than the requested number of values
		 */
		public static function getNiceNumbersInRange(min:Number, max:Number, numberOfValuesInRange:int):Array
		{
			// special case
			if (min == max)
				return [min];
			
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
				values[i++] = roundSignificant(x); // this fixes values like x = 0.6000000000000001 that may occur from x += d
			}
			
			return values;
		}
		
		public static function mean(...args):Number
		{
			var sum:Number = 0;
			for each (var value:Number in args)
				sum += value;
			return sum / args.length;
		}
		
		public static function sum(...args):Number
		{
			var sum:Number = 0;
			for each (var value:Number in args)
				sum += value;
			return sum;
		}
		
		/**
		 * This uses AsyncSort.sortImmediately() to sort an Array (or Vector) in place.
		 * @param array An Array (or Vector) to sort.
		 * @param compare A function that accepts two items and returns -1, 0, or 1.
		 * @see weave.utils.AsyncSort#sortImmediately()
		 * @see Array#sort()
		 */		
		public static function sort(array:*, compare:Function = null):void
		{
			AsyncSort.sortImmediately(array, compare);
		}
		
		/**
		 * This function compares each of the elements in two arrays in order, supporting nested Arrays.
		 * @param a The first Array for comparison
		 * @param b The second Array for comparison
		 * @return The first nonzero compare value, or zero if the arrays are equal.
		 */
		public static function arrayCompare(a:Array, b:Array):int
		{
			if (!a || !b)
				return AsyncSort.defaultCompare(a, b);
			var an:int = a.length;
			var bn:int = b.length;
			if (an < bn)
				return -1;
			if (an > bn)
				return 1;
			for (var i:int = 0; i < an; i++)
			{
				var ai:* = a[i];
				var bi:* = b[i];
				var result:int;
				if (ai is Array && bi is Array)
					result = arrayCompare(ai as Array, bi as Array);
				else
					result = AsyncSort.defaultCompare(ai, bi);
				if (result != 0)
					return result;
			}
			return 0;
		}
		
		/**
		 * This will perform a log transformation on a normalized value to produce another normalized value.
		 * @param normValue A number between 0 and 1.
		 * @param factor The log factor to use.
		 * @return A number between 0 and 1.
		 */
		public static function logTransform(normValue:Number, factor:Number = 1024):Number
		{
			return Math.log(1 + normValue * factor) / Math.log(1 + factor);
		}
		
		/**
		 * This will parse a date string into a Date object.
		 * @param dateString The date string to parse.
		 * @param formatString The format of the date string.
		 * @param parseAsUniversalTime If set to true, the date string will be parsed as universal time.
		 *        If set to false, the timezone of the user's computer will be used.
		 * @return The resulting Date object.
		 * 
		 * @see mx.formatters::DateFormatter#formatString
		 * @see Date
		 */		
		public static function parseDate(dateString:String, formatString:String = null, parseAsUniversalTime:Boolean = true):Date
		{
			var formattedDateString:String = dateString;
			if (formatString)
			{
				// work around bug in DateFormatter that requires Year, Month, and Day to be in the formatString
				var separator:String = "//";
				var appendFormat:String = "";
				var appendDate:String = "";
				for (var i:int = 0; i < 3; i++)
				{
					var char:String = "YMD".charAt(i);
					if (formatString.indexOf(char) < 0)
					{
						appendFormat += separator + char;
						appendDate += separator + (char == 'Y' ? '1970' : '1');
					}
				}
				if (appendFormat)
				{
					formatString += " " + appendFormat;
					dateString += " " + appendDate;
				}
				
				_dateFormatter.formatString = formatString;
				formattedDateString = _dateFormatter.format(dateString);
				if (_dateFormatter.error)
					throw new Error(_dateFormatter.error);
			}
			var date:Date = DateFormatter.parseDateString(formattedDateString);
			if (parseAsUniversalTime)
				date.setTime( date.getTime() - date.getTimezoneOffset() * _timezoneMultiplier );
			return date;
		}
		
		/**
		 * This will generate a date string from a Number or a Date object using the specified date format.
		 * @param value The Date object or date string to format.
		 * @param formatString The format of the date string to be generated.
		 * @param formatAsUniversalTime If set to true, the date string will be generated using universal time.
		 *        If set to false, the timezone of the user's computer will be used.
		 * @return The resulting formatted date string.
		 * 
		 * @see mx.formatters::DateFormatter#formatString
		 * @see Date
		 */
		public static function formatDate(value:Object, formatString:String = null, formatAsUniversalTime:Boolean = true):String
		{
			var date:Date = value as Date;
			if (!date || formatAsUniversalTime)
				date = new Date(value);
			if (formatAsUniversalTime)
				date.setTime( date.getTime() + date.getTimezoneOffset() * _timezoneMultiplier );
			
			_dateFormatter.formatString = formatString;
			return _dateFormatter.format(date);
		}
		
		/**
		 * This is the DateFormatter used by parseDate() and formatDate().
		 */
		private static const _dateFormatter:DateFormatter = new DateFormatter();
		/**
		 * The number of milliseconds in one minute.
		 */
		private static const _timezoneMultiplier:Number = 60000;
		
		/**
		 * This compares two dynamic objects or primitive values and is much faster than ObjectUtil.compare().
		 * @param a First dynamic object or primitive value.
		 * @param b Second dynamic object or primitive value.
		 * @return A value of zero if the two objects are equal, nonzero if not equal.
		 */
		public static function compareDynamicObjects(a:Object, b:Object):int
		{
			if (a === b)
				return 0;
			if (a == null)
				return 1;
			if (b == null)
				return -1;
			var typeA:String = typeof(a);
			var typeB:String = typeof(b);
			if (typeA != typeB)
				return ObjectUtil.stringCompare(typeA, typeB);
			if (typeA == 'boolean')
				return ObjectUtil.numericCompare(Number(a), Number(b));
			if (typeA == 'number')
				return ObjectUtil.numericCompare(a as Number, b as Number);
			if (typeA == 'string')
				return ObjectUtil.stringCompare(a as String, b as String);
			if (typeA != 'object')
				return 1;
			if (a is Date && b is Date)
				return ObjectUtil.dateCompare(a as Date, b as Date);
			
			var qna:String = getQualifiedClassName(a);
			var qnb:String = getQualifiedClassName(b);
			
			if (qna != qnb)
				return ObjectUtil.stringCompare(qna, qnb);
			
			var p:String;
			
			// test if objects are dynamic
			try
			{
				a[''];
				b[''];
			}
			catch (e:Error)
			{
				return 1; // not dynamic objects
			}
			
			// if there are properties in a not found in b, return -1
			for (p in a)
			{
				if (!b.hasOwnProperty(p))
					return -1;
			}
			for (p in b)
			{
				// if there are properties in b not found in a, return 1
				if (!a.hasOwnProperty(p))
					return 1;
				
				var c:int = compareDynamicObjects(a[p], b[p]);
				if (c != 0)
					return c;
			}
			
			return 0;
		}
		
		private static function testCompare_generate(base:Object, depth:int):Object
		{
			for (var i:int = 0; i < 10; i++)
			{
				var child:Object = depth > 0 ? {} : Math.random();
				base[Math.random()] = child;
				if (depth > 0)
					testCompare_generate(child, depth - 1);
			}
			return base;
		}
		
		//WeaveAPI.StageUtils.callLater(null, testCompare);
		private static function testCompare():void
		{
			var i:int;
			var orig:Object = testCompare_generate({}, 2);
			var o1:Object = ObjectUtil.copy(orig);
			var o2:Object = ObjectUtil.copy(o1);
			
			trace(ObjectUtil.toString(o1));
			
			DebugTimer.begin();
			for (i = 0; i < 100; i++)
				if (ObjectUtil.compare(o1,o2) != 0)
					throw "ObjectUtil.compare fail";
			DebugTimer.lap('ObjectUtil.compare');
			for (i = 0; i < 100; i++)
				if (compareDynamicObjects(o1,o2) != 0)
					throw "StandardLib.compareDynamicObjects fail";
			DebugTimer.end('StandardLib.compareDynamicObjects');
		}
	}
}
