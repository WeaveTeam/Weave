/*
This Source Code Form is subject to the terms of the
Mozilla Public License, v. 2.0. If a copy of the MPL
was not distributed with this file, You can obtain
one at https://mozilla.org/MPL/2.0/.
*/
package weavejs
{
	import weavejs.core.CallbackCollection;
	import weavejs.core.LinkableBoolean;
	import weavejs.core.LinkableNumber;
	import weavejs.core.LinkableString;
	import weavejs.core.LinkableVariable;
	
	public class Weave
	{
		private static const dependencies:Array = [
			CallbackCollection,
			LinkableVariable,
			LinkableString,
			LinkableNumber,
			LinkableBoolean,
			null
		];
		
		public function Weave()
		{
			super();
		}
		
		public function test():void
		{
			var lv:LinkableString = new LinkableString('yo');
			lv.addImmediateCallback(this, function():void { Weave.log('lv', lv.state); }, true);
			lv.state = 'hello';
			lv.state = 'hello';
			lv.state = 'world';
			lv.state = '2';
			lv.state = 2;
			lv.state = '3';
		}
		
//		public var root:ILinkableHashMap;
		
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
//		public function path(...basePath):WeavePath
//		{
//			if (basePath.length == 1 && isArray(basePath[0]))
//				basePath = basePath[0];
//			return new WeavePathData(null, basePath);
//		}
		
		
		
		//////////////////////////////////////////////////////////////////////////////////
		// static Weave API functions
		//////////////////////////////////////////////////////////////////////////////////
		
		public static function objectWasDisposed(object:Object):Boolean
		{
			var WeaveAPI:Object = global.WeaveAPI;
			if (WeaveAPI)
				return WeaveAPI.SessionManager.objectWasDisposed(object);
			
			log('objectWasDisposed(): WeaveAPI missing');
			return false;
		}
		
		public static function reportError(...args):void
		{
			var console:Object = global.console;
			if (console)
				console.error.apply(console, args);
			else
				log.apply(null, args);
		}
		
		public static function callLater(context:Object, func:Function, args:Array = null):void
		{
			// temporary solution
			var setTimeout:Function = global.setTimeout;
			setTimeout(function():void {
				if (!objectWasDisposed(context))
					func.apply(context, args);
			}, 0);
		}
		
		
		
		//////////////////////////////////////////////////////////////////////////////////
		// static general helper functions
		//////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * A reference to the global scope.
		 */
		public static const global:Object = (function():* { return this; }).apply(null);
		
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
		public static const Map:Class = (function():* { return this['Map']; }).apply(null);
		
		/**
		 * AS->JS Language helper for WeakMap
		 */
		public static const WeakMap:Class = (function():* { return this['WeakMap']; }).apply(null);
		
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
		
		/**
		 * AS->JS Language helper for converting array-like objects to Arrays
		 */
		public static function toArray(value:*):Array
		{
			// just return the value if it doesn't need conversion
			if (value is Array)
				return value;
			
			return Array.prototype.slice.call(value);
		}
		
		/**
		 * Makes a deep copy of an object.
		 */
		public static function copyObject(object:Object):Object
		{
			if (object !== null && typeof object === 'object')
				return JSON.parse(JSON.stringify(object));
			return object;
		}
		
		private static const FLEXJS_CLASS_INFO:String = 'FLEXJS_CLASS_INFO';
		public static function className(def:Class):String
		{
			if (def.prototype.hasOwnProperty(FLEXJS_CLASS_INFO))
				return def.prototype[FLEXJS_CLASS_INFO]['names'][0]['qName'];
			
			if (def.hasOwnProperty('name'))
				return def.name;
			
			// ActionScript "[class MyClass]"
			var str:String = String(def);
			return str.substring(7, str.length - 1);
		}
		
		public static function getDefinition(name:String):*
		{
			var def:* = global;
			for each (var key:String in name.split('.'))
			{
				if (def !== undefined)
					def = def[key];
				else
					break;
			}
			if (def !== undefined)
				return def;
			
			var domain:Object = global.root.loaderInfo.applicationDomain;
			if (domain.hasDefinition(name))
				return domain.getDefinition(name);
			return undefined;
		}
		
		public static function log(...args):void
		{
			if (global.trace)
				global.trace.apply(null, args);
			else
				global.console.log.apply(global.console, args);
		}
		
		/**
		 * Safe 'as' operator
		 * - won't crash if left is null
		 * - won't compile incorrectly by changing 'this.ClassDef' to 'ClassDef'
		 */
		public static function AS(left:Object, right:Class):*
		{
			if (left == null)
				return null;
			if (right == Array)
			{
				if (left is Array)
					return left;
				return Array.prototype.slice.call(left);
			}
			return left as right;
		}
		
		/**
		 * Safe 'is' operator
		 * - won't crash if left is null
		 * - won't compile incorrectly by changing 'this.ClassDef' to 'ClassDef'
		 */
		public static function IS(left:Object, right:Class):Boolean
		{
			if (left == null)
				return false;
			if (right == Array)
				return Array['isArray'](left);
			return left is right;
		}
		
		/**
		 * Tests if something looks like a Class.
		 */
		public static function isClass(classDef:Object):Boolean
		{
			return typeof classDef === 'function'
				&& classDef.prototype
				&& classDef.prototype.constructor === classDef;
		}
		
		/**
		 * Implementation of "classDef as Class"
		 */
		public static function asClass(classDef:Object):*
		{
			return isClass(classDef) ? classDef : null;
		}
	}
}
