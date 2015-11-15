/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package weavejs.utils
{
	/**
	 * This is a wrapper for a 2-dimensional Map.
	 * 
	 * @author adufilie
	 */
	public class Dictionary2D
	{
		public function Dictionary2D(weakPrimaryKeys:Boolean = false, weakSecondaryKeys:Boolean = false, defaultType:Class = null)
		{
			map = weakPrimaryKeys ? new Weave.WeakMap() : new Weave.Map;
			weak1 = weakPrimaryKeys;
			weak2 = weakSecondaryKeys;
			this.defaultType = defaultType;
		}
		
		/**
		 * The primary Map object.
		 */		
		public var map:Object;
		
		private var weak1:Boolean;
		private var weak2:Boolean; // used as a constructor parameter for nested Dictionaries
		private var defaultType:Class; // used for creating objects automatically via get()
		
		/**
		 * 
		 * @param key1 The first map key.
		 * @param key2 The second map key.
		 * @return The value.
		 */
		public function get(key1:Object, key2:Object):*
		{
			var value:* = undefined;
			var map2:* = map.get(key1);
			if (map2)
				value = map2.get(key2);
			if (value === undefined && defaultType)
			{
				value = new defaultType();
				set(key1, key2, value);
			}
			return value;
		}
		
		/**
		 * This will add or replace an entry in the map.
		 * @param key1 The first map key.
		 * @param key2 The second map key.
		 * @param value The value.
		 */
		public function set(key1:Object, key2:Object, value:Object):void
		{
			var map2:Object = map.get(key1);
			if (map2 == null)
				map.set(key1, map2 = weak2 ? new Weave.WeakMap() : new Weave.Map());
			map.set(key2, value);
		}
		
		/**
		 * This removes all values associated with the given primary key.
		 * @param key1 The first dictionary key.
		 */
		public function removeAllPrimary(key1:Object):void
		{
			map['delete'](key1);
		}
		
		/**
		 * This removes all values associated with the given secondary key.
		 * @param key2 The second dictionary key.
		 * @private
		 */
		private function removeAllSecondary(key2:Object):void
		{
			if (weak1)
				throw new Error("WeakMap cannot be iterated over");
			_key2ToRemove = key2;
			map.forEach(removeAllSecondary_each, this);
		}
		
		private var _key2ToRemove:*;
		private function removeAllSecondary_each(map1:*, key1:*):void
		{
			map1['delete'](_key2ToRemove);
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
			var map2:* = map.get(key1);
			if (map2)
			{
				value = map2.get(key2);
				map2['delete'](key2);
			}
			
			// if entries remain in map2, keep it
			for (var v2:* in map2)
				return value;
			
			// otherwise, remove it
			map['delete'](key1);
			
			return value;
		}
	}
}
