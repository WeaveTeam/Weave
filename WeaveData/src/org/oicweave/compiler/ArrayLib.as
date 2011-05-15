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
	/**
	 * This provides a set of static functions related to Array manipulation.
	 * 
	 * @author adufilie
	 */
	public class ArrayLib
	{
		/**
		 * @param array An Array to get an item from.
		 * @param index The index of an item to get.
		 * @return The item at the specified index.
		 */
		public static function getItem(array:Array, index:int):*
		{
			return array[index];
		}
		/**
		 * @return The result of string.split(delim, limit).
		 */
		public static function split(string:String, delim:String = null, limit:int = int.MAX_VALUE):Array
		{
			return string.split(delim, limit);
		}
		/**
		 * @return The result of array.join(separator).
		 */
		public static function join(array:Array, separator:*):String
		{
			return array.join(separator);
		}
		/**
		 * @return The result of array.indexOf(searchElement, fromIndex).
		 */
		public static function getItemIndex(array:Array, searchElement:*, fromIndex:* = 0):int
		{
			return array.indexOf(searchElement, fromIndex);
		}
		/**
		 * @return array.length.
		 */
		public static function arrayLength(array:Array):int
		{
			return array.length;
		}
	}
}
