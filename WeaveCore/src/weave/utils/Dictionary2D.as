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
	import flash.utils.Dictionary;

	/**
	 * This is a wrapper for a 2-dimensional Dictionary.
	 * 
	 * @author adufilie
	 */
	public class Dictionary2D
	{
		public function Dictionary2D(weakPrimaryKeys:Boolean = false, weakSecondaryKeys:Boolean = false)
		{
			dictionary = new Dictionary(weakPrimaryKeys);
			weak2 = weakSecondaryKeys;
		}
		
		/**
		 * The primary Dictionary object.
		 */		
		public var dictionary:Dictionary;
		
		private var weak2:Boolean; // used as a constructor parameter for nested Dictionaries
		
		/**
		 * 
		 * @param key1 The first dictionary key.
		 * @param key2 The second dictionary key.
		 * @return The value in the dictionary.
		 */
		public function get(key1:Object, key2:Object):*
		{
			var d2:* = dictionary[key1];
			return d2 ? d2[key2] : undefined;
		}
		
		/**
		 * This will add or replace an entry in the dictionary.
		 * @param key1 The first dictionary key.
		 * @param key2 The second dictionary key.
		 * @param value The value to put into the dictionary.
		 */
		public function set(key1:Object, key2:Object, value:Object):void
		{
			var d2:Dictionary = dictionary[key1] as Dictionary;
			if (d2 == null)
				dictionary[key1] = d2 = new Dictionary(weak2);
			d2[key2] = value;
		}
		
		/**
		 * This removes all values associated with the given primary key.
		 * @param key1 The first dictionary key.
		 */		
		public function removeAllPrimary(key1:Object):void
		{
			delete dictionary[key1];
		}
		
		/**
		 * This removes all values associated with the given secondary key.
		 * @param key2 The second dictionary key.
		 */		
		public function removeAllSecondary(key2:Object):void
		{
			for (var key1:* in dictionary)
				delete dictionary[key1][key2];
		}
		
		/**
		 * This removes a value associated with the given primary and secondary keys.
		 * @param key1 The first dictionary key.
		 * @param key2 The second dictionary key.
		 * @return The value that was in the dictionary.
		 */
		public function remove(key1:Object, key2:Object):*
		{
			var value:* = undefined;
			var d2:* = dictionary[key1];
			if (d2)
			{
				value = d2[key2];
				delete d2[key2];
			}
			
			// if entries remain in d2, keep it
			for (var v2:* in d2)
				return value;
			
			// otherwise, remove it
			delete dictionary[key1];
			
			return value;
		}
	}
}
