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

package weavejs.util
{
	/**
	 * This provides a set of useful static functions.
	 * All the functions defined in this class are pure functions, meaning they always return the same result with the same arguments, and they have no side-effects.
	 * 
	 * @author adufilie
	 */
	public class StandardLib
	{
		public static function formatNumber(number:Number, precision:int = -1):String
		{
			//TODO - use a library
			return String(number);
		}
		
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
			
			if (value is Number || value is Date)
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
		 * Converts a value to a non-null String
		 * @param value A value to cast to a String.
		 * @return The value cast to a String.
		 */
		public static function asString(value:*):String
		{
			if (value == null)
				return '';
			return String(value);
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
				return stringCompare(value, "true", true) == 0;
			if (isNaN(value))
				return false;
			if (value is Number)
				return value != 0;
			return value;
		}
		
		/**
		 * Tests if a value is anything other than undefined, null, or NaN.
		 */
		public static function isDefined(value:*):Boolean
		{
			return value !== undefined && value !== null && !(value is Number && isNaN(value));
		}
		
		/**
		 * Tests if a value is undefined, null, or NaN.
		 */
		public static function isUndefined(value:*):Boolean
		{
			return value === undefined || value === null || (value is Number && isNaN(value));
		}
		
		/**
		 * Pads a string on the left.
		 */
		public static function lpad(str:String, length:uint, padString:String = ' '):String
		{
			if (str.length >= length)
				return str;
			while (str.length + padString.length < length)
				padString += padString;
			return padString.substr(0, length - str.length) + str;
		}
		
		/**
		 * Pads a string on the right.
		 */
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
		
		private static const argRef:RegExp = new RegExp("^(0|[1-9][0-9]*)\}");
		
		/**
		 * Substitutes "{n}" tokens within the specified string with the respective arguments passed in.
		 * Same syntax as StringUtil.substitute() without the side-effects of using String.replace() with a regex.
		 * @see String#replace()
		 * @see mx.utils.StringUtil#substitute()
		 */
		public static function substitute(format:String, ...args):String
		{
			if (args.length == 1 && args[0] is Array)
				args = args[0] as Array;
			var split:Array = format.split('{')
			var output:String = split[0];
			for (var i:int = 1; i < split.length; i++)
			{
				var str:String = split[i] as String;
				if (argRef.test(str))
				{
					var j:int = str.indexOf("}");
					output += args[str.substring(0, j)];
					output += str.substring(j + 1);
				}
				else
					output += "{" + str;
			}
			return output;
		}
		
		/**
		 * Takes a script where all lines have been indented with tabs,
		 * removes the common indentation from all lines and optionally
		 * replaces extra leading tabs with a number of spaces.
		 * @param script A script.
		 * @param spacesPerTab If zero or greater, this is the number of spaces to be used in place of each tab character used as indentation.
		 * @return The modified script.
		 */		
		public static function unIndent(script:String, spacesPerTab:int = -1):String
		{
			if (script == null)
				return null;
			// switch all line endings to \n
			script = replace(script, '\r\n', '\n', '\r', '\n');
			// remove trailing whitespace (not leading whitespace)
			script = trim('.' + script).substr(1);
			// separate into lines
			var lines:Array = script.split('\n');
			// remove blank lines from the beginning
			while (lines.length && !trim(lines[0]))
				lines.shift();
			// stop if there's nothing left
			if (!lines.length)
			{
				return '';
			}
			// find the common indentation
			var commonIndent:Number = Number.MAX_VALUE;
			var line:String;
			for each (line in lines)
			{
				// ignore blank lines
				if (!trim(line))
					continue;
				// count leading tabs
				var lineIndent:int = 0;
				while (line.charAt(lineIndent) == '\t')
					lineIndent++;
				// remember the minimum number of leading tabs
				commonIndent = Math.min(commonIndent, lineIndent);
			}
			// remove the common indentation from each line
			for (var i:int = 0; i < lines.length; i++)
			{
				line = lines[i];
				// prepare to remove common indentation
				var t:int = 0;
				while (t < commonIndent && line.charAt(t) == '\t')
					t++;
				// optionally, prepare to replace extra tabs with spaces
				var spaces:String = '';
				if (spacesPerTab >= 0)
				{
					while (line.charAt(t) == '\t')
					{
						spaces += lpad('', spacesPerTab, '        ');
						t++;
					}
				}
				// commit changes
				lines[i] = spaces + line.substr(t);
			}
			return lines.join('\n');
		}

		/**
		 * @see mx.utils.StringUtil#trim()
		 */
		public static function trim(str:String):String
		{
			if (str == null) return '';
			
			var startIndex:int = 0;
			while (isWhitespace(str.charAt(startIndex)))
				++startIndex;
			
			var endIndex:int = str.length - 1;
			while (isWhitespace(str.charAt(endIndex)))
				--endIndex;
			
			if (endIndex >= startIndex)
				return str.slice(startIndex, endIndex + 1);
			else
				return "";
		}
		
		/**
		 * @see mx.utils.StringUtil#isWhitespace()
		 */
		public static function isWhitespace(character:String):Boolean
		{
			switch (character)
			{
				case " ":
				case "\t":
				case "\r":
				case "\n":
				case "\f":
				/*
					// non breaking space
				case "\u00A0":
					// line seperator
				case "\u2028":
					// paragraph seperator
				case "\u2029":
					// ideographic space
				case "\u3000":
					return true;
				*/
				default:
					return false;
			}
		}
		
		/**
		 * Converts a number to a String using a specific numeric base and optionally pads with leading zeros.
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
		 * Scales a number between 0 and 1 using specified min and max values.
		 * @param value The value between min and max.
		 * @param min The minimum value that corresponds to a result of 0.
		 * @param max The maximum value that corresponds to a result of 1.
		 * @return The normalized value between 0 and 1, or NaN if value is out of range.
		 */
		public static function normalize(value:Number, min:Number, max:Number):Number
		{
			if (value < min || value > max)
				return NaN;
			if (min == max)
				return value - min; // min -> 0; NaN -> NaN
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
			if (inputMin == inputMax)
			{
				if (isNaN(inputValue))
					return NaN;
				if (inputValue > inputMax)
					return outputMax;
				return outputMin;
			}
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
			// it doesn't make sense to round infinity or NaN
			if (!isFinite(value))
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
		
		//testRoundSignificant();
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
		 * Rounds a number to the nearest multiple of a precision value.
		 * @param number A number to round.
		 * @param precision A precision to use.
		 * @return The number rounded to the nearest multiple of the precision value.
		 */
		public static function roundPrecision(number:Number, precision:Number):Number
		{
			return Math.round(number / precision) * precision;
		}
		
		/**
		 * @param n The number to round.
		 * @param d The total number of non-zero digits we care about for small numbers.
		 */
		public static function suggestPrecision(n:Number, d:int):Number
		{
			return Math.pow(10, Math.min(0, Math.ceil(Math.log(n) / Math.LN10) - d));
		}

		/**
		 * Calculates an interpolated color for a normalized value.
		 * @param normValue A Number between 0 and 1.
		 * @param colors An Array or list of colors to interpolate between.  Normalized values of 0 and 1 will be mapped to the first and last colors.
		 * @return An interpolated color associated with the given normValue based on the list of color values.
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
			var R:int = 0xFF0000;
			var G:int = 0x00FF00;
			var B:int = 0x0000FF;
			return (
				((percentLeft * (minColor & R) + percentRight * (maxColor & R)) & R) |
				((percentLeft * (minColor & G) + percentRight * (maxColor & G)) & G) |
				((percentLeft * (minColor & B) + percentRight * (maxColor & B)) & B)
			);
		}
		
		/**
		 * ITU-R 601
		 */
		public static function getColorLuma(color:Number):Number
		{
			return 0.3 * ((color & 0xFF0000) >> 16) + 0.59 * ((color & 0x00FF00) >> 8) + 0.11 * (color & 0x0000FF);
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
			
			// Bug fix: getNiceNumbersInRange(0, 500, 6) returned [0,200,400] when it could be [0,100,200,300,400,500]
			// Was: range = getNiceNumber(max - min, false);
			range = max - min;
			
			d = getNiceNumber( range / (numberOfValuesInRange - 1), true);
			graphmin = Math.floor(min / d) * d;
			graphmax = Math.ceil(max / d) * d;
			
			nfrac = Math.max(-Math.floor(Math.log(d)/Math.LN10), 0);
			
			for (x = graphmin; x < graphmax + 0.5*d; x += d)
			{
				values[i++] = roundSignificant(x); // this fixes values like x = 0.6000000000000001 that may occur from x += d
			}
			
			return values;
		}
		
		/**
		 * Calculates the mean value from a list of Numbers.
		 */
		public static function mean(...args):Number
		{
			if (args.length == 1 && args[0] is Array)
				args = args[0];
			var sum:Number = 0;
			for each (var value:Number in args)
				sum += value;
			return sum / args.length;
		}
		
		/**
		 * Calculates the sum of a list of Numbers.
		 */
		public static function sum(...args):Number
		{
			if (args.length == 1 && args[0] is Array)
				args = args[0];
			var sum:Number = 0;
			for each (var value:Number in args)
				sum += value;
			return sum;
		}
		
		/**
		 * Sorts an Array of items in place using properties, lookup tables, or replacer functions.
		 * @param array An Array to sort.
		 * @param params Specifies how to get values used to sort items in the array.
		 *               This can either be an Array of params or a single param, each of which can be one of the following:<br>
		 *               Array: values are looked up based on index (Such an Array must be nested in a params array rather than given alone as a single param)<br>
		 *               Object or Dictionary: values are looked up using items in the array as keys<br>
		 *               Property name: values are taken from items in the array using a property name<br>
		 *               Replacer function: array items are passed through this function to get values<br>
		 * @param sortDirections Specifies sort direction(s) (1 or -1) corresponding to the params.
		 * @param inPlace Set this to true to modify the original Array in place or false to return a new, sorted copy.
		 * @param returnSortedIndexArray Set this to true to return a new Array of sorted indices.
		 * @return Either the original Array or a new one.
		 * @see Array#sortOn()
		 */
		public static function sortOn(array:*, params:*, sortDirections:* = undefined, inPlace:Boolean = true, returnSortedIndexArray:Boolean = false):*
		{
			//TODO
			if (returnSortedIndexArray)
				return array.map(function(o:*, i:*, a:*):* { return i; });
			return inPlace ? array : array.concat();
		}
		
		/**
		 * This will return the type of item found in the Array if each item has the same type.
		 * @param a An Array to check.
		 * @return The type of all items in the Array, or null if the types differ. 
		 */
		public static function getArrayType(a:Array):Class
		{
			if (a == null || a.length == 0 || a[0] == null)
				return null;
			var type:Class = Object(a[0]).constructor;
			for each (var item:Object in a)
				if (item == null || item.constructor != type)
					return null;
			return type;
		}
		
		/**
		 * Checks if all items in an Array are instances of a given type.
		 * @param a An Array of items to test
		 * @param type A type to check for
		 * @return true if each item in the Array is an object of the given type.
		 */
		public static function arrayIsType(a:Array, type:Class):Boolean
		{
			for each (var item:Object in a)
				if (!(item is type))
					return false;
			return true;
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
			//TODO
			if (value is Number)
			{
				var date:Date = new Date();
				date.time = value as Number;
				value = date;
			}
			return String(value);
		}
		
		/**
		 * The number of milliseconds in one minute.
		 */
		private static const _timezoneMultiplier:Number = 60000;
		
		/**
		 * This compares two dynamic objects or primitive values and is much faster than ObjectUtil.compare().
		 * Does not check for circular refrences.
		 * @param a First dynamic object or primitive value.
		 * @param b Second dynamic object or primitive value.
		 * @param objectCompare An optional compare function to replace the default compare behavior for non-primitive Objects.
		 *                      The function should return -1, 0, or 1 to override the comparison result, or NaN to use the default recursive comparison result.
		 * @return A value of zero if the two objects are equal, nonzero if not equal.
		 */
		public static function compare(a:Object, b:Object, objectCompare:Function = null):int
		{
			var c:int;
			if (a === b)
				return 0;
			if (a == null)
				return 1;
			if (b == null)
				return -1;
			var typeA:String = typeof(a);
			var typeB:String = typeof(b);
			if (typeA != typeB)
				return stringCompare(typeA, typeB);
			if (typeA == 'boolean')
				return numericCompare(Number(a), Number(b));
			if (typeA == 'number')
				return numericCompare(a as Number, b as Number);
			if (typeA == 'string')
				return stringCompare(a as String, b as String);
			if (typeA != 'object')
				return 1;
			if (a is Date && b is Date)
				return dateCompare(a as Date, b as Date);
			if (a is Array && b is Array)
			{
				var an:int = a.length;
				var bn:int = b.length;
				if (an < bn)
					return -1;
				if (an > bn)
					return 1;
				for (var i:int = 0; i < an; i++)
				{
					c = compare(a[i], b[i]);
					if (c != 0)
						return c;
				}
				return 0;
			}
			
			if (objectCompare != null)
			{
				var result:Number = objectCompare(a, b);
				if (isFinite(result))
					return result;
			}
			
			var qna:String = String(a); // getQualifiedClassName(a);
			var qnb:String = String(b); // getQualifiedClassName(b);
			
			if (qna != qnb)
				return stringCompare(qna, qnb);
			
			var p:String;
			
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
				
				c = compare(a[p], b[p]);
				if (c != 0)
					return c;
			}
			
			return 0;
		}
		
		/**
		 * @see mx.utils.ObjectUtil#numericCompare()
		 */
		public static function numericCompare(a:Number, b:Number):int
		{
			if (isNaN(a) && isNaN(b))
				return 0;
			
			if (isNaN(a))
				return 1;
			
			if (isNaN(b))
				return -1;
			
			if (a < b)
				return -1;
			
			if (a > b)
				return 1;
			
			return 0;
		}
		
		/**
		 * @see mx.utils.ObjectUtil#stringCompare()
		 */
		public static function stringCompare(a:String, b:String, caseInsensitive:Boolean = false):int
		{
			if (a == null && b == null)
				return 0;
			
			if (a == null)
				return 1;
			
			if (b == null)
				return -1;
			
			// Convert to lowercase if we are case insensitive.
			if (caseInsensitive)
			{
				a = a.toLocaleLowerCase();
				b = b.toLocaleLowerCase();
			}
			
			var result:int = a.localeCompare(b);
			
			if (result < -1)
				result = -1;
			else if (result > 1)
				result = 1;
			
			return result;
		}
		
		/**
		 * @see mx.utils.ObjectUtil#dateCompare()
		 */
		public static function dateCompare(a:Date, b:Date):int
		{
			if (a == null && b == null)
				return 0;
			
			if (a == null)
				return 1;
			
			if (b == null)
				return -1;
			
			var na:Number = a.getTime();
			var nb:Number = b.getTime();
			
			if (na < nb)
				return -1;
			
			if (na > nb)
				return 1;
			
			if (isNaN(na) && isNaN(nb))
				return 0;
			
			if (isNaN(na))
				return 1;
			
			if (isNaN(nb))
				return -1;
			
			return 0;
		}
		
		/**
		 * @see https://github.com/bestiejs/punycode.js
		 */
		internal static function ucs2encode(value:uint):String
		{
			var output:String = '';
			if (value > 0xFFFF)
			{
				value -= 0x10000;
				output += String.fromCharCode(value >>> 10 & 0x3FF | 0xD800);
				value = 0xDC00 | value & 0x3FF;
			}
			return output + String.fromCharCode(value);
		}
		
		[Deprecated(replacement="compare")] public static function arrayCompare(a:Object, b:Object):int { return compare(a,b); }
		[Deprecated(replacement="compare")] public static function compareDynamicObjects(a:Object, b:Object):int { return compare(a,b); }
	}
}
