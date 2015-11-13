/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package
{
	public class Weave
	{
		public function Weave()
		{
		}
		
		/**
		 * Instance of IExternalSessionStateInterface
		 */
		public var directAPI:Object;
		
		/**
		 * Creates a WeavePath object.  WeavePath objects are immutable after they are created.
		 * This is a shortcut for "new WeavePath(weave, basePath)".
		 * @param basePath An optional Array (or multiple parameters) specifying the path to an object in the session state.
		 *                 A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @return A WeavePath object.
		 * @see WeavePath
		 */
		public function path(...basePath):WeavePath
		{
			if (basePath.length == 1 && Weave.isArray(basePath[0]))
				basePath = basePath[0];
			return new WeavePath(this, basePath);
		}
		
		//////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * AS->JS Language helper for binding class instance functions
		 */
		public static function bindAll(instance:Object):*
		{
			if (!Object(Object).hasOwnProperty('getPrototypeOf'))
				return instance;
			
			var proto:Object = Object['getPrototypeOf'](instance);
			for (var key:String in proto)
			{
				var prop:* = proto[key];
				if (typeof prop === 'function')
					instance[key] = prop.bind(instance);
			}
			return instance;
		}
		
		/**
		 * AS->JS Language helper for Map
		 */
		public static const Map:Class = (function():* {
			return this['Map'];
		}).apply(null);
		
		/**
		 * AS->JS Language helper for Object.keys()
		 */
		public static function objectKeys(object:Object):Array
		{
			if (Object(Object).hasOwnProperty('keys'))
				return Object['keys'](object);
			
			var keys:Array = [];
			for (var key:* in object)
				keys.push(key);
			return keys;
		}
		
		/**
		 * AS->JS Language helper for Array.isArray()
		 */
		public static function isArray(value:*):Boolean
		{
			if (Object(Array).hasOwnProperty('isArray'))
				return Array['isArray'](value);
			
			return value is Array;
		}
	}
}