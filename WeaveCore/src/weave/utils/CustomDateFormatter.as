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
	import mx.core.mx_internal;
	import mx.formatters.DateBase;
	import mx.formatters.DateFormatter;
	import mx.formatters.StringFormatter;

	/**
	 * This fixes two bugs:
	 * - 00:NN:SS no longer converted to 24:NN:SS.
	 * - formatString no longer requires Year, Month, Day tokens
	 * 
	 * @author adufilie
	 */
	public class CustomDateFormatter extends DateFormatter
	{
		/**
		 * Copied from mx.formatters.DateFormatter
		 */		
		private static const VALID_PATTERN_CHARS:String = "Y,M,D,A,E,H,J,K,L,N,S,Q";
		
		/**
		 * @private
		 * Fixes bug in DateBase.extractTokenDate that changes '00' hours to '24' hours for HH token.
		 * @see mx.formatters.DateBase#extractTokenDate
		 */
		mx_internal static function extractTokenDate(date:Date, tokenInfo:Object):String
		{
			if (tokenInfo.token == "H")
			{
				var key:int = int(tokenInfo.end) - int(tokenInfo.begin);
				return setValue(int(date.getHours()), key);
			}
			
			return DateBase.mx_internal::extractTokenDate(date, tokenInfo);
		}
		
		/**
		 * @private
		 * Copied from DateBase for use in extractTokenDate().
		 * @see mx.formatters.DateBase#setValue
		 */
		private static function setValue(value:Object, key:int):String
		{
			var result:String = "";
			
			var vLen:int = value.toString().length;
			if (vLen < key)
			{
				var n:int = key - vLen;
				for (var i:int = 0; i < n; i++)
				{
					result += "0"
				}
			}
			
			result += value.toString();
			
			return result;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function format(value:Object):String
		{
			// BEGIN WEAVE CHANGE
			// work around bug in DateFormatter that requires Year, Month, and Day to be in the formatString
			var formatString:String = this.formatString;
			if (value is String)
			{
				var separator:String = "//";
				var appendFormat:String = "";
				var appendDate:String = "";
				for (var c:int = 0; c < 3; c++)
				{
					var char:String = "YMD".charAt(c);
					if (formatString.indexOf(char) < 0)
					{
						appendFormat += separator + char;
						appendDate += separator + (char == 'Y' ? '1970' : '1');
					}
				}
				if (appendFormat)
				{
					formatString += " " + appendFormat;
					value += " " + appendDate;
				}
			}
			// END WEAVE CHANGE
			
			
			// Reset any previous errors.
			if (error)
				error = null;
			
			// If value is null, or empty String just return "" 
			// but treat it as an error for consistency.
			// Users will ignore it anyway.
			if (!value || (value is String && value == ""))        
			{
				error = defaultInvalidValueError;
				return "";
			}
			
			// -- value --
			
			if (value is String)
			{
				value = DateFormatter.parseDateString(String(value));
				if (!value)
				{
					error = defaultInvalidValueError;
					return "";
				}
			}
			else if (!(value is Date))
			{
				error = defaultInvalidValueError;
				return "";
			}
			
			// -- format --
			
			var letter:String;
			var nTokens:int = 0;
			var tokens:String = "";
			
			var n:int = formatString.length;
			for (var i:int = 0; i < n; i++)
			{
				letter = formatString.charAt(i);
				if (VALID_PATTERN_CHARS.indexOf(letter) != -1 && letter != ",")
				{
					nTokens++;
					if (tokens.indexOf(letter) == -1)
					{
						tokens += letter;
					}
					else
					{
						if (letter != formatString.charAt(Math.max(i - 1, 0)))
						{
							error = defaultInvalidFormatError;
							return "";
						}
					}
				}
			}
			
			if (nTokens < 1)
			{
				error = defaultInvalidFormatError;
				return "";
			}
			
			var dataFormatter:StringFormatter = new StringFormatter(
				formatString, VALID_PATTERN_CHARS,
				mx_internal::extractTokenDate);
			
			return dataFormatter.formatValue(value);
		}
	}
}
