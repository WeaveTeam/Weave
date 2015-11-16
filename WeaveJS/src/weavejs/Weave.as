/*
This Source Code Form is subject to the terms of the
Mozilla Public License, v. 2.0. If a copy of the MPL
was not distributed with this file, You can obtain
one at https://mozilla.org/MPL/2.0/.
*/
package weavejs
{
	import weavejs.api.core.IExternalSessionStateInterface;
	import weavejs.api.core.ILinkableHashMap;
	import weavejs.api.core.ILinkableObject;
	import weavejs.api.core.ISessionManager;
	import weavejs.compiler.StandardLib;
	import weavejs.core.CallbackCollection;
	import weavejs.core.ExternalSessionStateInterface;
	import weavejs.core.LinkableBoolean;
	import weavejs.core.LinkableHashMap;
	import weavejs.core.LinkableNumber;
	import weavejs.core.LinkableString;
	import weavejs.core.LinkableVariable;
	import weavejs.core.SessionManager;
	import weavejs.path.WeavePath;
	import weavejs.path.WeavePathData;
	
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
			
			WeaveAPI.ClassRegistry.registerSingletonImplementation(ISessionManager, SessionManager);
			
			root = new LinkableHashMap();
			directAPI = new ExternalSessionStateInterface(root);
		}
		
		public function test():void
		{
			//var lv:LinkableString = root.requestObject('yo', LinkableString, false);
			var lv:LinkableString = new LinkableString('yo');
			lv.addImmediateCallback(this, function():void { Weave.log('lv', lv.state); }, true);
			lv.state = 'hello';
			lv.state = 'hello';
			lv.state = 'world';
			lv.state = '2';
			lv.state = 2;
			lv.state = '3';
		}
		
		/**
		 * The root object in the session state
		 */
		public var root:ILinkableHashMap;
		
		/**
		 * Instance of IExternalSessionStateInterface
		 */
		public var directAPI:IExternalSessionStateInterface;
		
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
			if (basePath.length == 1 && basePath[0] is Array)
				basePath = basePath[0];
			return new WeavePathData(this, basePath);
		}
		
		/**
		 * A shortcut for WeaveAPI.SessionManager.getObject(WeaveAPI.globalHashMap, path).
		 * @see weave.api.core.ISessionManager#getObject()
		 */
		public function getObject(path:Array):ILinkableObject
		{
			return WeaveAPI.SessionManager.getObject(root, path);
		}
		
		/**
		 * A shortcut for WeaveAPI.SessionManager.getPath(WeaveAPI.globalHashMap, object).
		 * @see weave.api.core.ISessionManager#getPath()
		 */
		public function getPath(object:ILinkableObject):Array
		{
			return WeaveAPI.SessionManager.getPath(root, object);
		}

		
		//////////////////////////////////////////////////////////////////////////////////
		// static Weave API functions
		//////////////////////////////////////////////////////////////////////////////////
		
		public static function objectWasDisposed(object:Object):Boolean
		{
			//return WeaveAPI.SessionManager.objectWasDisposed(object);
			
			log('objectWasDisposed(): Not implemented yet');
			return false;
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
		 * Calls console.error()
		 */
		public static function error(...args):void
		{
			global.console.error.apply(global.console, args);
		}
		
		/**
		 * Calls console.log()
		 */
		public static function log(...args):void
		{
			global.console.log.apply(global.console, args);
		}
		
		/**
		 * AS->JS Language helper for binding class instance functions
		 */
		public static function bindAll(instance:Object):*
		{
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
		 * AS->JS Language helper for Object.keys()
		 */
		public static function objectKeys(object:Object):Array
		{
			return Object['keys'](object);
		}
		
		/**
		 * AS->JS Language helper for converting array-like objects to Arrays
		 * Also works on Iterator objects to extract an Array of values
		 */
		public static function toArray(value:*):Array
		{
			// special case for Iterator
			if (value is global.Iterator)
			{
				var values:Array = [];
				while (true)
				{
					var next:Object = value.next();
					if (next.done)
						break;
					values.push(next.value);
				}
				return values;
			}
			
			return value as Array;
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
		
		/**
		 * Gets the qualified class name from a class definition or an object instance.
		 */
		public static function className(def:Object):String
		{
			if (!def)
				return null;
			
			if (!def.prototype)
				def = def.constructor;
			
			if (def.prototype && def.prototype.FLEXJS_CLASS_INFO)
				return def.prototype.FLEXJS_CLASS_INFO.names[0].qName;
			
			return def.name;
		}
		
		public static const defaultPackages:Array = [
			'weavejs.core'
		];
		
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
			
			if (!def)
			{
				for each (var pkg:String in defaultPackages)
				{
					def = getDefinition(pkg + '.' + name);
					if (def)
						return def;
				}
			}
			
			return def;
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
		
		/**
		 * Current time in milliseconds
		 */
		public static function getTimer():Number
		{
			return Date['now']();
		}
		
		/**
		 * Checks if an object implements ILinkableObject
		 */
		public static function isLinkable(object:Object):Boolean
		{
			return object is ILinkableObject;
		}
		
		/**
		 * Generates a deterministic JSON-like representation of an object, meaning object keys appear in sorted order.
		 * @param value The object to stringify.
		 * @param replacer A function like function(key:String, value:*):*
		 * @param indent Either a Number or a String to specify indentation of nested values
		 * @param json_values_only If this is set to true, only JSON-compatible values will be used (NaN/Infinity/undefined -> null)
		 */
		public static function stringify(value:*, replacer:Function = null, indent:* = null, json_values_only:Boolean = false):String
		{
			indent = typeof indent === 'number' ? StandardLib.lpad('', indent, ' ') : indent as String || ''
			return _stringify("", value, replacer, indent ? '\n' : '', indent, json_values_only);
		}
		private static function _stringify(key:String, value:*, replacer:Function, lineBreak:String, indent:String, json_values_only:Boolean):String
		{
			if (replacer != null)
				value = replacer(key, value);
			
			var output:Array;
			var item:*;
			
			if (typeof value === 'string')
				return encodeString(value);
			
			// non-string primitives
			if (value == null || typeof value != 'object')
			{
				if (json_values_only && (value === undefined || !isFinite(value as Number)))
					value = null;
				return String(value) || String(null);
			}
			
			// loop over keys in Array or Object
			var lineBreakIndent:String = lineBreak + indent;
			var valueIsArray:Boolean = value is Array;
			output = [];
			if (valueIsArray)
			{
				for (var i:int = 0; i < value.length; i++)
					output.push(_stringify(String(i), value[i], replacer, lineBreakIndent, indent, json_values_only));
			}
			else if (typeof value == 'object')
			{
				for (key in value)
					output.push(encodeString(key) + ": " + _stringify(key, value[key], replacer, lineBreakIndent, indent, json_values_only));
				// sort keys
				output.sort();
			}
			
			if (output.length == 0)
				return valueIsArray ? "[]" : "{}";
			
			return (valueIsArray ? "[" : "{")
				+ lineBreakIndent
				+ output.join(indent ? ',' + lineBreakIndent : ', ')
				+ lineBreak
				+ (valueIsArray ? "]" : "}");
		}
		/**
		 * This function surrounds a String with quotes and escapes special characters using ActionScript string literal format.
		 * @param string A String that may contain special characters.
		 * @param quote Set this to either a double-quote or a single-quote.
		 * @return The given String formatted for ActionScript.
		 */
		private static function encodeString(string:String, quote:String = '"'):String
		{
			if (string == null)
				return 'null';
			var result:Array = new Array(string.length);
			for (var i:int = 0; i < string.length; i++)
			{
				var chr:String = string.charAt(i);
				var esc:String = chr == quote ? quote : ENCODE_LOOKUP[chr];
				result[i] = esc ? '\\' + esc : chr;
			}
			return quote + result.join('') + quote;
		}
		private static const ENCODE_LOOKUP:Object = {'\b':'b', '\f':'f', '\n':'n', '\r':'r', '\t':'t', '\\':'\\'};
	}
}
