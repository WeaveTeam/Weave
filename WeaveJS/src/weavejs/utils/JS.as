package weavejs.utils
{
	public class JS
	{
		/**
		 * AS->JS Language helper to get the global scope
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
		 * AS->JS Language helper for Map
		 */
		public static const Map:Class = (function():* { return this['Map']; }).apply(null);
		
		/**
		 * AS->JS Language helper for WeakMap
		 */
		public static const WeakMap:Class = (function():* { return this['WeakMap']; }).apply(null);
		
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
		 * AS->JS Language helper for Object.keys()
		 */
		public static function objectKeys(object:Object):Array
		{
			return Object['keys'](object);
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
		 * setTimeout
		 */
		public static function setTimeout(func:Function, delay:int, ...params):int
		{
			params.unshift(func, delay);
			return global.setTimeout.apply(global, params);
		}
		
		/**
		 * setInterval
		 */
		public static function setInterval(func:Function, delay:int, ...params):int
		{
			params.unshift(func, delay);
			return global.setInterval.apply(global, params);
		}
		
		/**
		 * Current time in milliseconds
		 */
		public static function now():Number
		{
			return Date['now']();
		}
		
		/**
		 * Fixes bugs with the "is" operator.
		 */
		public static function fix_is():*
		{
			global.org.apache.flex.utils.Language['is'] = IS;
			if (!(true is Boolean))
				throw new Error('"is" operator is broken')
		}
		
		/**
		 * Safe version of 'as' operator
		 * - won't compile "obj as this.classDef" incorrectly as "...Language.as(obj, classDef)"
		 */
		public static function AS(leftOperand:Object, rightOperand:Class):*
		{
			return global.org.apache.flex.utils.Language['as'](leftOperand, rightOperand);
		}
		
		/**
		 * Bug fixes for 'is' operator, modified from org.apache.flex.utils.Language.is
		 * - "this is Boolean" works
		 * - won't compile "obj is this.classDef" incorrectly as "...Language.is(obj, classDef)"
		 */
		public static function IS(leftOperand:Object, rightOperand:Class):Boolean
		{
			var superClass:Object;
			
			if (leftOperand == null)
				return false;
			
			if (leftOperand && rightOperand == null) {
				return false;
			}
			
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
	}
}