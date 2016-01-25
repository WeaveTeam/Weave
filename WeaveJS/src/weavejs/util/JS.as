package weavejs.util
{
	public class JS
	{
		private static function getGlobal(name:String):*
		{
			var Fn:Class = Function;
			var fn:Function = new Fn("return " + name + ";");
			return fn();
		}
		
		/**
		 * AS->JS Language helper to get the global scope
		 */
		public static const global:Object = getGlobal("this");
		
		/**
		 * This must be set externally.
		 */
		public static var JSZip:Class;
		
		private static const console:Object = getGlobal("console");
		private static const Symbol:Object = getGlobal("Symbol");
		
		/**
		 * Calls console.error()
		 */
		public static function error(...args):void
		{
			console.error.apply(console, args);
		}
		
		/**
		 * Calls console.log()
		 */
		public static function log(...args):void
		{
			console.log.apply(console, args);
		}
		
		private static const unnamedFunctionRegExp:RegExp = /^\s*function\s*\([^\)]*\)\s*\{.*\}\s*$/;
		
		/**
		 * Compiles a script into a function with optional parameter names.
		 * @param script A String containing JavaScript code.
		 * @param paramNames A list of parameter names for the generated function, so that these variable names can be used in the script.
		 * @param errorHandler A function that handles errors.
		 */
		public static function compile(script:String, paramNames:Array = null, errorHandler:Function = null):Function
		{
			var isFunc:Boolean = unnamedFunctionRegExp.test(script);
			if (isFunc)
				script = "(" + script + ")";
			var args:Array = (paramNames || []).concat("return eval(" + JSON.stringify(script) + ");");
			var func:Function = Function['apply'](null, args);
			return function():* {
				try
				{
					return func.apply(this, arguments);
				}
				catch (e:Error)
				{
					// will get SyntaxError if script uses a return statement outside a function
					if (e is SyntaxError)
					{
						args.pop();
						args.push(script);
						try
						{
							func = Function['apply'](null, args);
						}
						catch (e2:Error)
						{
							if (e2 is SyntaxError)
								func = Function['apply']();
							if (errorHandler != null)
								return errorHandler(e2);
							else
								throw e2;
						}
						return func.apply(this, arguments);
					}
					if (errorHandler != null)
						return errorHandler(e);
					else
						throw e;
				}
			};
		}
		
		/**
		 * AS->JS Language helper for ArrayBuffer
		 */
		public static const ArrayBuffer:Class = getGlobal('ArrayBuffer');
		
		/**
		 * AS->JS Language helper for Uint8Array
		 */
		public static const Uint8Array:Class = getGlobal('Uint8Array');
		
		/**
		 * AS->JS Language helper for Promise
		 */
		public static const Promise:Class = getGlobal('Promise');
		
		/**
		 * AS->JS Language helper for Map
		 */
		public static const Map:Class = getGlobal('Map');
		
		/**
		 * AS->JS Language helper for WeakMap
		 */
		public static const WeakMap:Class = getGlobal('WeakMap');
		
		/**
		 * AS->JS Language helper for getting an Array of Map keys.
		 */
		public static function mapKeys(map:Object):Array
		{
			return map ? toArray(map.keys()) : [];
		}
		
		/**
		 * AS->JS Language helper for getting an Array of Map values.
		 */
		public static function mapValues(map:Object):Array
		{
			return map ? toArray(map.values()) : [];
		}
		
		/**
		 * AS->JS Language helper for getting an Array of Map entries.
		 */
		public static function mapEntries(map:Object):Array
		{
			return map ? toArray(map.entries()) : [];
		}
		
		/**
		 * Tests if an object can be iterated over. If this returns true, then toArray()
		 * can be called to get all the values from the iterator as an Array.
		 */
		public static function isIterable(value:*):Boolean
		{
			return value && typeof value[Symbol.iterator] === 'function';
		}
		
		/**
		 * AS->JS Language helper for converting array-like objects to Arrays
		 * Extracts an Array of values from an Iterator object.
		 * Converts Arguments object to an Array.
		 */
		public static function toArray(value:*):Array
		{
			if (value is Array)
				return value;
			
			// special case for iterable object
			if (value && typeof value[Symbol.iterator] === 'function')
			{
				var iterator:Object = value[Symbol.iterator]();
				var values:Array = [];
				while (true)
				{
					var next:Object = iterator.next();
					if (next.done)
						break;
					values.push(next.value);
				}
				return values;
			}
			
			// special case for Arguments
			if (Object.prototype.toString.call(value) === '[object Arguments]')
				return Array.prototype.slice.call(value);
			
			return null;
		}
		
		/**
		 * AS->JS Language helper for Object.keys()
		 */
		public static function objectKeys(object:Object):Array
		{
			return Object['keys'](object);
		}
		
		/**
		 * Tests if a value is of a primitive type.
		 */
		public static function isPrimitive(value:*):Boolean
		{
			return value === null || typeof value !== 'object';
		}
		
		/**
		 * Makes a deep copy of an object.
		 */
		public static function copyObject(object:Object):Object
		{
			// check for primitive values
			if (object === null || typeof object !== 'object')
				return object;
			
			var copy:Object = object is Array ? [] : {};
			for (var key:String in object)
				copy[key] = copyObject(object[key]);
			return copy;
			
			//return JSON.parse(JSON.stringify(object));
		}
		
		/**
		 * AS->JS Language helper for binding class instance functions
		 */
		private static function bindAll(instance:Object):*
		{
			var proto:Object = Object['getPrototypeOf'](instance);
			for (var key:String in proto)
			{
				var prop:* = proto[key];
				if (typeof prop === 'function' && key !== 'constructor')
					instance[key] = prop.bind(instance);
			}
			return instance;
		}
		
		/**
		 * Implementation of "classDef is Class"
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
		
		public static function setTimeout(func:Function, delay:int, ...params):int
		{
			params.unshift(func, delay);
			return global['setTimeout'].apply(global, params);
		}
		
		public static function clearTimeout(id:int):void
		{
			global['clearTimeout'](id);
		}
		
		public static function setInterval(func:Function, delay:int, ...params):int
		{
			params.unshift(func, delay);
			return global['setInterval'].apply(global, params);
		}
		
		public static function requestAnimationFrame(func:Function):int
		{
			return global['requestAnimationFrame'].call(global, func);
		}
		
		public static function cancelAnimationFrame(id:int):void
		{
			global['cancelAnimationFrame'].call(global, id);
		}
		
		/**
		 * Current time in milliseconds
		 */
		public static function now():Number
		{
			return Date['now']();
		}
		
		/**
		 * Similar to Object.hasOwnProperty(), except it also checks prototypes.
		 */
		public static function hasProperty(object:Object, prop:String):Boolean
		{
			while (object != null && !Object['getOwnPropertyDescriptor'](object, prop))
				object = Object['getPrototypeOf'](object);
			return object != null;
		}
		
		/**
		 * AS->JS Language helper for Object.getOwnPropertyNames()
		 */
		public static function getOwnPropertyNames(object:Object):Array
		{
			return Object['getOwnPropertyNames'](object);
		}
		
		/**
		 * Similar to Object.getOwnPropertyNames(), except it also checks prototypes.
		 */
		public static function getPropertyNames(object:Object, useCache:Boolean):Array
		{
			if (object == null || object === Object.prototype)
				return [];
			
			if (!map_obj_names)
			{
				map_obj_names = new JS.WeakMap();
				map_prop_skip = new JS.Map();
			}
			
			if (useCache && map_obj_names.has(object))
				return map_obj_names.get(object);
			
			var names:Array = getPropertyNames(Object['getPrototypeOf'](object), useCache);
			// if the names array is in the cache, make a copy
			if (useCache)
				names = names.concat();
			
			// prepare to skip duplicate names
			++skip_id;
			var name:String;
			for each (name in names)
				map_prop_skip.set(name, skip_id);
			
			// add own property names
			var ownNames:Array = Object['getOwnPropertyNames'](object);
			for each (name in ownNames)
			{
				// skip duplicate names
				if (map_prop_skip.get(name) !== skip_id)
				{
					map_prop_skip.set(name, skip_id);
					names.push(name);
				}
			}
			
			// save in cache
			map_obj_names.set(object, names);
			return names;
		}
		
		private static var map_obj_names:Object;
		private static var map_prop_skip:Object;
		private static var skip_id:int = 0;
	}
}