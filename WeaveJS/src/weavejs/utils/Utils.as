package weavejs.utils
{
	public class Utils
	{
		/**
		 * AS->JS Language helper for Map
		 */
		public static const Map:Class = (function():* { return this['Map']; }).apply(null);
		
		/**
		 * AS->JS Language helper for WeakMap
		 */
		public static const WeakMap:Class = (function():* { return this['WeakMap']; }).apply(null);
		
		/**
		 * ActionScript getter/setters will be cross-compiled as set_name/get_name.
		 * This uses Object.defineProperty() to ensure that it will create real getter/setters in JavaScript.
		 */
		public static function preserveGetterSetters(classDef:Class, ...names):*
		{
			// works for both static and non-static
			for each (var obj:Object in [classDef, classDef['prototype']])
			{
				for each (var name:String in names)
				{
					var def:Object = {
						"get": obj['get_' + name],
						"set": obj['set_' + name]
					};
					if (def.set || def.get)
						Object['defineProperty'](obj, name, def);
				}
			}
		}
		
		public static function fix_is_as():*
		{
			var fn:Function = function():* {
				var Language:Object = this['org'].apache.flex.utils.Language;
				Language['is'] = IS;
				Language['as'] = AS;
			};
			fn.apply(null);
			null is Object;
			null as Object;
		}
		
		/**
		 * Safe 'as' operator modified from org.apache.flex.utils.Language.as
		 * - won't crash if leftOperand is null
		 * - won't compile incorrectly by changing 'this.ClassDef' to 'ClassDef'
		 */
		public static function AS(leftOperand:Object, rightOperand:Class, opt_coercion:Boolean = false):*
		{
			var error:Error, itIs:Boolean, message:String;
			
			// (adufilie) changed to use IS()
			itIs = IS(leftOperand, rightOperand);
			
			// (adufilie) added special case for Array
			if (rightOperand === Array)
			{
				if (itIs)
					return leftOperand;
				return leftOperand && Array.prototype.slice.call(leftOperand);
			}
			
			if (!itIs && opt_coercion) {
				message = 'Type Coercion failed';
				if (TypeError) {
					error = new TypeError(message);
				} else {
					error = new Error(message);
				}
				throw error;
			}
			
			return (itIs) ? leftOperand : null;
		}
		
		/**
		 * Safe 'is' operator modified from org.apache.flex.utils.Language.is
		 * - won't crash if leftOperand is null
		 * - won't compile incorrectly by changing 'this.ClassDef' to 'ClassDef'
		 * - fixed crash bug checking leftOperand.FLEXJS_CLASS_INFO.interfaces
		 */
		public static function IS(leftOperand:Object, rightOperand:Class):Boolean
		{
			// (adufilie) checkInterfaces() moved to a static function
			var superClass:Object;
			
			// (adufilie) added check for null and special case for Array
			if (leftOperand == null)
				return false;
			if (rightOperand == Array)
				return Array['isArray'](leftOperand);
			
			// (erikdebruin) we intentionally DON'T do null checks on the
			//               [class].FLEXJS_CLASS_INFO property, as it MUST be
			//               declared for every FLEXJS JS (framework) class
			
			// (adufilie) It IS necessary to do null checks on leftOperand.FLEXJS_CLASS_INFO
			//            because the leftOperand may be any object,
			//            not just a class instance, and we don't want it to crash.
			
			if (leftOperand && !rightOperand) {
				return false;
			}
			
			// (adufilie) simplified logic
			if (leftOperand instanceof rightOperand)
				return true;
			if (rightOperand === String && typeof leftOperand === 'string')
				return true;
			if (rightOperand === Number && typeof leftOperand === 'number')
				return true;
			
			// (adufilie) Added null check for leftOperand.FLEXJS_CLASS_INFO
			if (leftOperand.FLEXJS_CLASS_INFO && leftOperand.FLEXJS_CLASS_INFO.interfaces) {
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
					// (adufilie) fixed bug where it would not check all interfaces before returning
					if (_IS_checkInterfaces(interfaces[i].prototype, rightOperand))
						return true;
				}
			}
			
			return false;
		}
	}
}