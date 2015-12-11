package weavejs.utils
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
		public static const global:Object = getGlobal("window");
		
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
		
		/**
		 * Compiles a script into a function with optional parameter names.
		 * @param script A String containing JavaScript code.
		 * @param paramNames A list of parameter names for the generated function, so that these variable names can be used in the script.
		 */
		public static function compile(script:String, paramNames:Array = null):Function
		{
			var paramsStr:String = paramNames ? paramNames.join(',') : '';
			return global['eval']("(function(" + paramsStr + "){ return eval(" + JSON.stringify(script) + "); })");
		}
		
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
		
		/**
		 * setTimeout
		 */
		public static function setTimeout(func:Function, delay:int, ...params):int
		{
			params.unshift(func, delay);
			return global['setTimeout'].apply(global, params);
		}
		
		/**
		 * setInterval
		 */
		public static function setInterval(func:Function, delay:int, ...params):int
		{
			params.unshift(func, delay);
			return global['setInterval'].apply(global, params);
		}
		
		/**
		 * Current time in milliseconds
		 */
		public static function now():Number
		{
			return Date['now']();
		}
		
		private static var Language:Class;
		
		/**
		 * Fixes bugs with the "is" operator.
		 */
		public static function fix_is():*
		{
			if (!Language)
				Language = getGlobal("org.apache.flex.utils.Language");
			Language['is'] = IS;
			if (!(true is Boolean))
				throw new Error('"is" operator is broken')
		}
		
		/**
		 * Safe version of 'as' operator
		 * Using this will avoid the bug where "obj as this.classDef" compiles incorrectly as "...Language.as(obj, classDef)"
		 */
		public static function AS(leftOperand:Object, rightOperand:Class):*
		{
			if (!Language)
				Language = getGlobal("org.apache.flex.utils.Language");
			return Language['as'](leftOperand, rightOperand);
		}
		
		/**
		 * Bug fixes for 'is' operator, modified from org.apache.flex.utils.Language.is
		 * - "this is Boolean" works
		 * - won't compile "obj is this.classDef" incorrectly as "...Language.is(obj, classDef)"
		 */
		public static function IS(leftOperand:Object, rightOperand:Class):Boolean
		{
			var superClass:Object;
			
			if (leftOperand == null || rightOperand == null)
				return false;
			
			// (adufilie) separated instanceof check to catch more cases.
			if (leftOperand instanceof rightOperand)
				return true;
			
			// (adufilie) simplified String check and added check for boolean
			if (typeof leftOperand === 'string')
				return rightOperand === String;
			if (typeof leftOperand === 'number')
				return rightOperand === Number;
			if (typeof leftOperand === 'boolean')
				return rightOperand === Boolean;
			if (rightOperand === Array)
				return Array['isArray'](leftOperand);
			
			if (leftOperand.FLEXJS_CLASS_INFO === undefined)
				return false; // could be a function but not an instance
			if (leftOperand.FLEXJS_CLASS_INFO.interfaces) {
				if (_IS_checkInterfaces(leftOperand, rightOperand)) {
					return true;
				}
			}
			
			superClass = leftOperand.constructor.superClass_;
			if (superClass) {
				while (superClass && superClass.FLEXJS_CLASS_INFO) {
					if (superClass.FLEXJS_CLASS_INFO.interfaces) {
						if (_IS_checkInterfaces(superClass, rightOperand)) {
							return true;
						}
					}
					superClass = superClass.constructor.superClass_;
				}
			}
			
			return false;
		}
		private static function _IS_checkInterfaces(leftOperand:Object, rightOperand:Object):Boolean
		{
			var i:int, interfaces:Array;
			
			interfaces = leftOperand.FLEXJS_CLASS_INFO.interfaces;
			for (i = interfaces.length - 1; i > -1; i--) {
				if (interfaces[i] === rightOperand) {
					return true;
				}
				
				if (interfaces[i].prototype.FLEXJS_CLASS_INFO.interfaces) {
					// (adufilie) avoid creating new instance of interface by checking prototype
					if (_IS_checkInterfaces(interfaces[i].prototype, rightOperand))
						return true;
				}
			}
			
			return false;
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
	}
}