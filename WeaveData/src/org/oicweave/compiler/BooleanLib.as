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
	import mx.utils.ObjectUtil;

	/**
	 * This provides a set of static functions related to Boolean values.
	 * 
	 * @author adufilie
	 */
	public class BooleanLib
	{
		//TODO: update compiler to include branching (c ? t : f), so 't' and 'f' parameters are not evaluated unless they are needed.
		public static function iif(c:*, t:*, f:*):* { return toBoolean(c) ? t : f; }

		public static function isDefined(value:*):Boolean
		{
			return !(value == undefined || (value is Number && isNaN(value)) || value == null);
		}
		public static function isUndefined(value:*):Boolean
		{
			return (value == undefined || (value is Number && isNaN(value)) || value == null);
		}
		
		public static function not(x:*):Boolean { return !x; }
		public static function equals(x:*, y:*):Boolean { return x == y; }
		public static function lessThan(x:*, y:*):Boolean { return x < y; }
		public static function greaterThan(x:*, y:*):Boolean { return x > y; }
		public static function lessThanEqualTo(x:*, y:*):Boolean { return x <= y; }
		public static function greaterThanEqualTo(x:*, y:*):Boolean { return x >= y; }

		/**
		 * This function attempts to derive a boolean value from different types of objects.
		 * @param value An object to parse as a Boolean.
		 */
		public static function toBoolean(value:*):Boolean
		{
			if (value is String)
				return ObjectUtil.stringCompare(value, "true", true) == 0;
			if (isNaN(value))
				return false;
			if (value is Number)
				return value != 0;
			return value;
		}
	}
}
