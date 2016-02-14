/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package weavejs.util
{
	/**
	 * This is a wrapper for a 2-dimensional Map.
	 * 
	 * @author adufilie
	 */
	public class Dictionary2D/*/<K1,K2,V>/*/
	{
		public function Dictionary2D(weakPrimaryKeys:Boolean = false, weakSecondaryKeys:Boolean = false, defaultType:Class = null)
		{
			map = weakPrimaryKeys ? new JS.WeakMap() : new JS.Map();
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
		 * @param key1 The first map key.
		 * @param key2 The second map key.
		 * @return The value.
		 */
		public function get(key1:/*/K1/*/Object, key2:/*/K2/*/Object):/*/V/*/*
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
		public function set(key1:/*/K1/*/Object, key2:/*/K2/*/Object, value:/*/V/*/Object):void
		{
			var map2:Object = map.get(key1);
			if (map2 == null)
			{
				map2 = weak2 ? new JS.WeakMap() : new JS.Map();
				map.set(key1, map2);
			}
			map2.set(key2, value);
		}
		
		public function primaryKeys():Array/*/<K1>/*/
		{
			if (weak1)
				throwWeakIterationError();
			return JS.mapKeys(map);
		}
		
		public function secondaryKeys(key1:/*/K1/*/Object):Array/*/<K2>/*/
		{
			if (weak2)
				throwWeakIterationError();
			return JS.mapKeys(map.get(key1));
		}
		
		/**
		 * This removes all values associated with the given primary key.
		 * @param key1 The first dictionary key.
		 */
		public function removeAllPrimary(key1:/*/K1/*/Object):void
		{
			map['delete'](key1);
		}
		
		/**
		 * This removes all values associated with the given secondary key.
		 * @param key2 The second dictionary key.
		 * @private
		 */
		public function removeAllSecondary(key2:/*/K2/*/Object):void
		{
			if (weak1)
				throwWeakIterationError();
			_key2ToRemove = key2;
			map.forEach(removeAllSecondary_each, this);
		}
		private var _key2ToRemove:*;
		private function removeAllSecondary_each(map2:*, key1:*):void
		{
			map2['delete'](_key2ToRemove);
		}
		
		/**
		 * This removes a value associated with the given primary and secondary keys.
		 * @param key1 The first dictionary key.
		 * @param key2 The second dictionary key.
		 * @return The value that was in the dictionary.
		 */
		public function remove(key1:/*/K1/*/Object, key2:/*/K2/*/Object):/*/V/*/*
		{
			var value:* = undefined;
			var map2:* = map.get(key1);
			if (map2)
			{
				value = map2.get(key2);
				map2['delete'](key2);
				
				// if map2 is a WeakMap or entries remain in map2, keep it
				if (weak2 || map2.size)
					return value;
				
				// otherwise, remove it
				map['delete'](key1);
			}
			return value;
		}
		
		private static function throwWeakIterationError():void
		{
			throw new Error("WeakMap cannot be iterated over");
		}
		
		/**
		 * Iterates over pairs of keys and corresponding values.
		 * @param key1_key2_value A function which may return true to stop iterating.
		 * @param thisArg The 'this' argument for the function.
		 */
		public function forEach(key1_key2_value:/*/(key1:K1, key2:K2, value:V) => any/*/Function, thisArg:Object):void
		{
			if (weak1 || weak2)
				throwWeakIterationError();
			
			forEach_fn = key1_key2_value;
			forEach_this = thisArg;
			
			map.forEach(forEach1, this);
			
			forEach_fn = null;
			forEach_this = null;
			forEach_key1 = null;
			forEach_map2 = null;
		}
		private var forEach_fn:Function;
		private var forEach_this:Object;
		private var forEach_key1:Object;
		private var forEach_map2:Object;
		private function forEach1(map2:*, key1:*):void
		{
			if (forEach_fn == null)
				return;
			forEach_key1 = key1;
			forEach_map2 = map2;
			map2.forEach(forEach2, this);
		}
		private function forEach2(value:*, key2:*):void
		{
			if (forEach_fn != null && forEach_fn.call(forEach_this, forEach_key1, key2, value))
				forEach_fn = null;
		}
	}
}
