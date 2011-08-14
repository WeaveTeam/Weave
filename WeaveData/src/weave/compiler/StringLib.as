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
	import mx.formatters.NumberFormatter;

	/**
	 * This provides a set of static functions related to String parsing and manipulation.
	 * 
	 * @author adufilie
	 */
	public class StringLib
	{
		/**
		 * @param value A value to cast to a String.
		 * @return The value cast to a String.
		 */
		public static function toString(value:*):String
		{
			if (value == null)
				return '';
			try
			{
				return String(value);
			}
			catch (e:Error) { }
			return '';
		}
		
		public static function stringSearch(str:String, pattern:*):int
		{
			return str.search(pattern);
		}
		
		public static function substr(str:String, startIndex:Number = 0, len:Number = 0x7fffffff):String
		{
			return str.substr(startIndex, len);
		}
		public static function concat(str:String, ...args):String
		{
			return (str.concat as Function).apply(null, args);
		}
		public static function strlen(str:String):int
		{
			return str.length;
		}
		public static function upper(str:String):String
		{
			return str.toUpperCase();
		}
		public static function lower(str:String):String
		{
			return str.toLowerCase();
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
		 * This function performs find & replace operations on a String.
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
		 * @param number The Number to convert to a String.
		 * @param base Specifies the numeric base (from 2 to 36) to use.
		 * @param zeroPad This is the minimum number of digits to return.  The number will be padded with zeros if necessary.
		 * @return The String representation of the number using the specified numeric base.
		 */
		public static function toBase(number:Number, base:int = 10, zeroPad:int = 1):String
		{
			var parts:Array = Math.abs(number).toString(base).split('.');
			if (parts[0].length < zeroPad)
				parts[0] = lpad(parts[0], zeroPad, '0');
			if (number < 0)
				parts[0] = '-' + parts[0];
			return parts.join('.');
		}
		
		/**
		 * @param number The number to format.
		 * @param formatterOrPrecision The NumberFormatter to use, or a precision value to use for the default NumberFormatter.
		 */
		public static function formatNumber(number:Number, formatterOrPrecision:Object = null):String
		{
			var formatter:NumberFormatter = formatterOrPrecision as NumberFormatter;
			if (formatter)
				return formatter.format(number);

			var precision:Number = MathLib.toNumber(formatterOrPrecision);
			if (isFinite(precision))
				defaultNumberFormatter.precision = uint(precision);
			else
				defaultNumberFormatter.precision = -1;

			return defaultNumberFormatter.format(number);
		}
		
		/**
		 * This is the default NumberFormatter to use inside the formatNumber() function.
		 */
		private static const defaultNumberFormatter:NumberFormatter = new NumberFormatter();
	}
}
