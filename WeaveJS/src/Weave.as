/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.ICallbackCollection;
	import weavejs.api.core.IDisposableObject;
	import weavejs.api.core.ILinkableDynamicObject;
	import weavejs.api.core.ILinkableHashMap;
	import weavejs.api.core.ILinkableObject;
	import weavejs.api.core.ISessionManager;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.core.LinkableFunction;
	import weavejs.core.LinkablePlaceholder;
	import weavejs.core.SessionStateLog;
	import weavejs.path.WeavePath;
	import weavejs.path.WeavePathUI;
	import weavejs.util.Dictionary2D;
	import weavejs.util.JS;
	import weavejs.util.StandardLib;
	
	public class Weave implements IDisposableObject
	{
		public static const HISTORY_SYNC_DELAY:int = 100;
		public static const FRAME_INTERVAL:Number = 1000/30;
		
		public function Weave()
		{
			// set this property for backwards compatibility
			this['WeavePath'] = WeavePathUI;
			
			root = disposableChild(this, WeaveAPI.ClassRegistry.getImplementations(ILinkableHashMap)[0]);
			history = disposableChild(this, new SessionStateLog(root, HISTORY_SYNC_DELAY));
			map_root_weave.set(root, this);
		}
		
		public function dispose():void
		{
			Weave.dispose(this);
			map_root_weave['delete'](root);
			root = null;
			history = null;
		}
		
		/**
		 * The root object in the session state
		 */
		public var root:ILinkableHashMap;
		
		/**
		 * The session history
		 */
		public var history:SessionStateLog;
		
		/**
		 * For backwards compatibility, may be temporary solution
		 */
		public function macro(name:String, ...params):*
		{
			var macros:ILinkableHashMap = getObject('WeaveProperties', 'macros') as ILinkableHashMap;
			if (!macros)
				throw new Error("macros hash map not found");
			var fn:LinkableFunction = macros.getObject(name) as LinkableFunction;
			if (!fn)
				throw new Error("Macro does not exist: " + name);
			return fn.apply(null, params);
		}
		
		/**
		 * Creates a WeavePath object.  WeavePath objects are immutable after they are created.
		 * This is a shortcut for "new WeavePath(weave, basePath)".
		 * @param basePath An optional Array (or multiple parameters) specifying the path to an object in the session state.
		 *                 A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @return A WeavePath object.
		 * @see WeavePath
		 */
		public function path(...basePath/*/(string|number|(string|number)[])[]/*/):WeavePath
		{
			if (basePath.length == 1 && basePath[0] is Array)
				basePath = basePath[0];
			// handle path(linkableObject)
			if (basePath.length == 1 && isLinkable(basePath[0]))
				basePath = findPath(root, basePath[0]);
			return basePath ? new WeavePathUI(this, basePath) : null;
		}
		
		/**
		 * Gets the ILinkableObject at a specified path.
		 * @param path An Array (or multiple parameters) specifying the path to an object in the session state.
		 *             A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 */
		public function getObject(...path/*/(string|number|(string|number)[])[]/*/):ILinkableObject
		{
			if (path.length == 1)
			{
				if (path[0] is WeavePath)
					return (path[0] as WeavePath).getObject();
				if (path[0] is Array)
					path = path[0];
			}
			return Weave.followPath(root, path);
		}

		/**
		 * Requests that an object be created if it doesn't already exist at the given path.
		 * This function can also be used to assert that the object at the current path is of the type you expect it to be.
		 * @param path The path
		 * @param type The type
		 * @return Either an instance of the requested type, a LinkablePlaceholder, or null if the object could not be created.
		 */
		public function requestObject(path:Array/*/<string|number>/*/, type:Class):ILinkableObject
		{
			// Get parent object first in case there is some backwards compatibility code that gets
			// executed when it is accessed (registering deprecated class definitions, for example).
			var parentPath:Array = path.concat();
			var childName:Object = parentPath.pop();
			var parent:ILinkableObject = Weave.followPath(root, parentPath);
			
			// request the child object
			var hashMap:ILinkableHashMap = parent as ILinkableHashMap;
			var dynamicObject:ILinkableDynamicObject = parent as ILinkableDynamicObject;
			var child:Object = null;
			if (hashMap)
			{
				if (childName is Number)
					childName = hashMap.getNames()[childName];
				child = hashMap.requestObject(childName as String, type, false);
			}
			else if (dynamicObject)
				child = dynamicObject.requestGlobalObject(childName as String, type, false);
			else
				child = Weave.followPath(root, path);
			
			// check for exact match only
			if (LinkablePlaceholder.getClass(child) == type)
				return child as ILinkableObject;
			
			return null;
		}
		
		
		//////////////////////////////////////////////////////////////////////////////////
		// static functions for linkable objects
		//////////////////////////////////////////////////////////////////////////////////
		
		private static const map_root_weave:Object = new JS.Map();
		
		/**
		 * Finds the Weave instance for a given Object.
		 * @param object An Object.
		 * @return The Weave instance, or null if the object was not registered as an ancestor of any instance of Weave.
		 */
		public static function getWeave(object:Object):Weave
		{
			var sm:ISessionManager = WeaveAPI.SessionManager;
			while (object && !(object is Weave))
				object = sm.getOwner(object);
			return object as Weave;
		}
		
		/**
		 * Gets a WeavePath from an ILinkableObject.
		 * @param object An ILinkableObject.
		 * @return A WeavePath, or null if the object is not registered with a Weave instance.
		 */
		public static function getPath(object:ILinkableObject):WeavePath
		{
			var weave:Weave = Weave.getWeave(object);
			return weave ? weave.path(object) : null;
		}
		
		/**
		 * Shortcut for WeaveAPI.SessionManager.getPath()
		 * @copy weave.api.core.ISessionManager#getPath()
		 */
		public static function findPath(root:ILinkableObject, descendant:ILinkableObject):Array/*/<string>/*/
		{
			return WeaveAPI.SessionManager.getPath(root, descendant);
		}
		
		/**
		 * Shortcut for WeaveAPI.SessionManager.getObject()
		 * @copy weave.api.core.ISessionManager#getObject()
		 */
		public static function followPath(root:ILinkableObject, path:Array/*/<string|number>/*/):ILinkableObject
		{
			return WeaveAPI.SessionManager.getObject(root, path);
		}
		
		/**
		 * Shortcut for WeaveAPI.SessionManager.getCallbackCollection()
		 * @copy weave.api.core.ISessionManager#getCallbackCollection()
		 */
		public static function getCallbacks(linkableObject:ILinkableObject):ICallbackCollection
		{
			return WeaveAPI.SessionManager.getCallbackCollection(linkableObject);
		}

		/**
		 * This function is used to detect if callbacks of a linkable object were triggered since the last time this function
		 * was called with the same parameters, likely by the observer.  Note that once this function returns true, subsequent calls will
		 * return false until the callbacks are triggered again.  It's a good idea to specify a private object or function as the observer
		 * so no other code can call detectChange with the same observer and linkableObject parameters.
		 * @param observer The object that is observing the change.
		 * @param linkableObject The object that is being observed.
		 * @param moreLinkableObjects More objects that are being observed.
		 * @return A value of true if the callbacks for any of the objects have triggered since the last time this function was called
		 *         with the same observer for any of the specified linkable objects.
		 */
		public static function detectChange(observer:Object, linkableObject:ILinkableObject, ...moreLinkableObjects/*/<ILinkableObject>/*/):Boolean
		{
			var changeDetected:Boolean = false;
			moreLinkableObjects.unshift(linkableObject);
			// it's important not to short-circuit like a boolean OR (||) because we need to clear the 'changed' flag on each object.
			for each (linkableObject in moreLinkableObjects)
				if (linkableObject && _internalDetectChange(observer, linkableObject, true)) // clear 'changed' flag
					changeDetected = true;
			return changeDetected;
		}
		/**
		 * This function is used to detect if callbacks of a linkable object were triggered since the last time detectChange
		 * was called with the same parameters, likely by the observer.  Note that once this function returns true, subsequent calls will
		 * return false until the callbacks are triggered again, unless clearChangedNow is set to false.  It may be a good idea to specify
		 * a private object as the observer so no other code can call detectChange with the same observer and linkableObject
		 * parameters.
		 * @param observer The object that is observing the change.
		 * @param linkableObject The object that is being observed.
		 * @param clearChangedNow If this is true, the trigger counter will be reset to the current value now so that this function will
		 *        return false if called again with the same parameters before the next time the linkable object triggers its callbacks.
		 * @return A value of true if the callbacks for the linkableObject have triggered since the last time this function was called
		 *         with the same observer and linkableObject parameters.
		 */
		public static function _internalDetectChange(observer:Object, linkableObject:ILinkableObject, clearChangedNow:Boolean = true):Boolean
		{
			var previousCount:* = d2d_linkableObject_observer_triggerCounter.get(linkableObject, observer); // untyped to handle undefined value
			var newCount:uint = WeaveAPI.SessionManager.getCallbackCollection(linkableObject).triggerCounter;
			if (previousCount !== newCount) // !== avoids casting to handle the case (0 !== undefined)
			{
				if (clearChangedNow)
					d2d_linkableObject_observer_triggerCounter.set(linkableObject, observer, newCount);
				return true;
			}
			return false;
		}
		/**
		 * This is a two-dimensional dictionary, where _triggerCounterMap[linkableObject][observer]
		 * equals the previous triggerCounter value from linkableObject observed by the observer.
		 */
		private static const d2d_linkableObject_observer_triggerCounter:Dictionary2D = new Dictionary2D(true, true);
		
		/**
		 * Finds the root ILinkableHashMap for a given ILinkableObject.
		 * @param object An ILinkableObject.
		 * @return The root ILinkableHashMap.
		 */
		public static function getRoot(object:ILinkableObject):ILinkableHashMap
		{
			var sm:ISessionManager = WeaveAPI.SessionManager;
			while (true)
			{
				var owner:ILinkableObject = sm.getLinkableOwner(object);
				if (!owner)
					break;
				object = owner;
			}
			return object as ILinkableHashMap;
		}
		
		/**
		 * Finds the closest ancestor of a descendant given the ancestor type.
		 * @param descendant An object with ancestors.
		 * @param ancestorType The Class definition used to determine which ancestor to return.
		 * @return The closest ancestor of the given type.
		 * @see weave.api.core.ISessionManager#getLinkableOwner()
		 */
		public static function getAncestor/*/<T>/*/(descendant:ILinkableObject, ancestorType:/*/new(..._:any[])=>T | string/*/Class):/*/T & ILinkableObject/*/ILinkableObject
		{
			if (ancestorType is String)
				ancestorType = Weave.getDefinition(String(ancestorType), true);
			
			var sm:ISessionManager = WeaveAPI.SessionManager;
			do {
				descendant = sm.getLinkableOwner(descendant);
			} while (descendant && !(descendant is ancestorType));
			
			return descendant;
		}
		
		/**
		 * Shortcut for WeaveAPI.SessionManager.getLinkableOwner()
		 * @copy weave.api.core.ISessionManager#getLinkableOwner()
		 */
		public static function getOwner(child:ILinkableObject):ILinkableObject
		{
			return WeaveAPI.SessionManager.getLinkableOwner(child);
		}
		
		/**
		 * Shortcut for WeaveAPI.SessionManager.getLinkableDescendants()
		 * @copy weave.api.core.ISessionManager#getLinkableDescendants()
		 */
		public static function getDescendants/*/<T>/*/(object:ILinkableObject, filter:/*/new(..._:any[])=>T | string/*/Class = null):Array/*/<T & ILinkableObject>/*/
		{
			if (filter is String)
				filter = Weave.getDefinition(String(filter), true);
			
			return WeaveAPI.SessionManager.getLinkableDescendants(object, filter);
		}
		
		/**
		 * Shortcut for WeaveAPI.SessionManager.getSessionState()
		 * @copy weave.api.core.ISessionManager#getSessionState()
		 */
		public static function getState(linkableObject:ILinkableObject):Object
		{
			return WeaveAPI.SessionManager.getSessionState(linkableObject);
		}
		
		/**
		 * Shortcut for WeaveAPI.SessionManager.setSessionState()
		 * @copy weave.api.core.ISessionManager#setSessionState()
		 */
		public static function setState(linkableObject:ILinkableObject, newState:Object, removeMissingDynamicObjects:Boolean = true):void
		{
			WeaveAPI.SessionManager.setSessionState(linkableObject, newState, removeMissingDynamicObjects);
		}
		
		/**
		 * Shortcut for WeaveAPI.SessionManager.copySessionState()
		 * @copy weave.api.core.ISessionManager#copySessionState()
		 */
		public static function copyState(source:ILinkableObject, destination:ILinkableObject):void
		{
			WeaveAPI.SessionManager.copySessionState(source, destination);
		}
		
		/**
		 * Shortcut for WeaveAPI.SessionManager.linkSessionState()
		 * @copy weave.api.core.ISessionManager#linkSessionState()
		 */
		public static function linkState(primary:ILinkableObject, secondary:ILinkableObject):void
		{
			WeaveAPI.SessionManager.linkSessionState(primary, secondary);
		}
		
		/**
		 * Shortcut for WeaveAPI.SessionManager.unlinkSessionState()
		 * @copy weave.api.core.ISessionManager#unlinkSessionState()
		 */
		public static function unlinkState(first:ILinkableObject, second:ILinkableObject):void
		{
			WeaveAPI.SessionManager.unlinkSessionState(first, second);
		}
		
		/**
		 * Shortcut for WeaveAPI.SessionManager.computeDiff()
		 * @copy weave.api.core.ISessionManager#computeDiff()
		 */
		public static function computeDiff(oldState:Object, newState:Object):Object
		{
			return WeaveAPI.SessionManager.computeDiff(oldState, newState);
		}
		
		/**
		 * Shortcut for WeaveAPI.SessionManager.combineDiff()
		 * @copy weave.api.core.ISessionManager#combineDiff()
		 */
		public static function combineDiff(baseDiff:Object, diffToAdd:Object):Object
		{
			return WeaveAPI.SessionManager.combineDiff(baseDiff, diffToAdd);
		}
		
		/**
		 * Shortcut for WeaveAPI.SessionManager.newDisposableChild() and WeaveAPI.SessionManager.registerDisposableChild()
		 * @see weave.api.core.ISessionManager#newDisposableChild()
		 * @see weave.api.core.ISessionManager#registerDisposableChild()
		 */
		public static function disposableChild(disposableParent:Object, disposableChildOrType:Object):*
		{
			if (JS.isClass(disposableChildOrType))
				return WeaveAPI.SessionManager.newDisposableChild(disposableParent, JS.asClass(disposableChildOrType));
			return WeaveAPI.SessionManager.registerDisposableChild(disposableParent, disposableChildOrType);
		}
		
		/**
		 * Shortcut for WeaveAPI.SessionManager.newLinkableChild() and WeaveAPI.SessionManager.registerLinkableChild()
		 * @see weave.api.core.ISessionManager#newLinkableChild()
		 * @see weave.api.core.ISessionManager#registerLinkableChild()
		 */
		public static function linkableChild/*/<T extends ILinkableObject>/*/(linkableParent:Object, linkableChildOrType:/*/(new()=>T) | T/*/Object, callback:Function = null, useGroupedCallback:Boolean = false):/*/T/*/*
		{
			if (JS.isClass(linkableChildOrType))
				return WeaveAPI.SessionManager.newLinkableChild(linkableParent, JS.asClass(linkableChildOrType), callback, useGroupedCallback);
			return WeaveAPI.SessionManager.registerLinkableChild(linkableParent, linkableChildOrType as ILinkableObject, callback, useGroupedCallback);
		}
		
		/**
		 * Shortcut for WeaveAPI.SessionManager.disposeObject()
		 * @copy weave.api.core.ISessionManager#disposeObject()
		 */
		public static function dispose(object:Object):void
		{
			WeaveAPI.SessionManager.disposeObject(object);
		}
		
		/**
		 * Shortcut for WeaveAPI.SessionManager.objectWasDisposed()
		 * @copy weave.api.core.ISessionManager#objectWasDisposed()
		 */
		public static function wasDisposed(object:Object):Boolean
		{
			return WeaveAPI.SessionManager.objectWasDisposed(object);
		}
		
		/**
		 * Shortcut for WeaveAPI.SessionManager.linkableObjectIsBusy()
		 * @copy weave.api.core.ISessionManager#linkableObjectIsBusy()
		 */
		public static function isBusy(object:ILinkableObject):Boolean
		{
			return WeaveAPI.SessionManager.linkableObjectIsBusy(object);
		}
		
		/**
		 * Checks if an object or class implements ILinkableObject
		 */
		public static function isLinkable(objectOrClass:Object):Boolean
		{
			if (objectOrClass is ILinkableObject || objectOrClass === ILinkableObject)
				return true;
			// test class definition
			return objectOrClass ? objectOrClass.prototype is ILinkableObject : false;
		}
		
		
		
		//////////////////////////////////////////////////////////////////////////////////
		// static general helper functions
		//////////////////////////////////////////////////////////////////////////////////
		
		private static const map_class_isAsync:Object = new JS.Map();
		
		/**
		 * Registers a class that must be instantiated asynchronously.
		 * Dynamic items in the session state that extend this class will be replaced with
		 * LinkablePlaceholder objects that can be replaced with actual instances later.
		 */
		public static function registerAsyncClass/*/<T>/*/(type:/*/new(..._:any[])=>T/*/Class, instanceHandler:/*/(instance:T)=>void/*/Function):void
		{
			var valueInMap:* = instanceHandler || true;
			map_class_isAsync.set(type, valueInMap);
			
			// update previously-cached types in case async status has changed
			for each (var cachedType:Class in JS.mapKeys(map_class_isAsync))
			{
				if (!map_class_isAsync.get(cachedType) && type.isPrototypeOf(cachedType))
				{
					// new type is in the prototype chain of a non-async type
					map_class_isAsync.set(cachedType, valueInMap);
				}
			}
		}
		
		/**
		 * Checks if a class is or extends one that was registered through registerAsyncClass().
		 */
		public static function isAsyncClass(type:Class):Boolean
		{
			if (map_class_isAsync.has(type))
				return map_class_isAsync.get(type);
			
			for each (var cachedType:Class in JS.mapKeys(map_class_isAsync))
			{
				var valueInMap:* = map_class_isAsync.get(cachedType);
				if (valueInMap && cachedType.isPrototypeOf(type))
				{
					// new type extends registered async type
					map_class_isAsync.set(type, valueInMap);
					return true;
				}
			}
			// new type does not extend any registered async type
			map_class_isAsync.set(type, false);
			return false;
		}
		
		/**
		 * Gets the function that was passed in to registerAsyncClass() for a given type.
		 */
		public static function getAsyncInstanceHandler(type:Class):Function
		{
			return map_class_isAsync.get(type) as Function;
		}
		
		/**
		 * Registers an ILinkableObject class for use with Weave.className() and Weave.getDefinition().
		 * @param qualifiedName
		 * @param definition
		 * @param additionalInterfaces An Array of interfaces (Class objects) that the definition implements in addition to ILinkableObject.
		 */
		public static function registerClass(qualifiedName:String, definition:Class, additionalInterfaces:Array/*/<new()=>any>/*/ = null):void
		{
			WeaveAPI.ClassRegistry.registerClass(qualifiedName, definition, [ILinkableObject].concat(additionalInterfaces || []));
		}
		
		/**
		 * Gets the qualified class name from a class definition or an object instance.
		 */
		public static function className(def:Object):String
		{
			return WeaveAPI.ClassRegistry.getClassName(def);
		}
		
		/**
		 * Looks up a static definition by name.
		 */
		public static function getDefinition(name:String, throwIfNotFound:Boolean = false):*
		{
			var result:* = WeaveAPI.ClassRegistry.getDefinition(name);
			if (result === undefined && throwIfNotFound)
				throw new Error("No definition for " + JSON.stringify(name));
			return result;
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
			indent = typeof indent === 'number' ? StandardLib.lpad('', indent, ' ') : indent as String || '';
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
			
			var lb:String = valueIsArray ? "[" : "{";
			var rb:String = valueIsArray ? "]" : "}";
			return lb
				+ lineBreakIndent
				+ output.join(indent ? ',' + lineBreakIndent : ', ')
				+ lineBreak
				+ rb;
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
		
		/**
		 * This is a convenient global function for retrieving localized text.
		 * Sample syntax:
		 *     Weave.lang("hello world")
		 * 
		 * You can also specify a format string with parameters which will be passed to StandardLib.substitute():
		 *     Weave.lang("{0} and {1}", first, second)
		 * 
		 * @param text The original text or format string to translate.
		 * @param parameters Parameters to be passed to StandardLib.substitute() if the text is to be treated as a format string.
		 */
		public static function lang(text:String, ...parameters):String
		{
			// call localize() either way to let the LocaleManager know that we are interested in translations of this text.
			var newText:String = WeaveAPI.Locale.getText(text);

			if (WeaveAPI.debugLocale)
			{
				parameters.unshift(text);
				var str:String = stringify(parameters);
				return 'lang(' + str.substring(1, str.length - 1) + ')';
			}

			if (parameters.length)
				return StandardLib.substitute(newText, parameters);
			
			return newText;
		}
		
		/**
		 * For testing purposes.
		 */
		public function triggerColumns():void
		{
			triggerAll('ReferencedColumn');
		}
		
		/**
		 * For testing purposes.
		 */
		public function triggerAll(filter:*):void
		{
			if (filter is String)
				filter = getDefinition(filter);
			Weave.getDescendants(root, JS.asClass(filter))
				.forEach(function(obj:ILinkableObject):void { getCallbacks(obj).triggerCallbacks(); });
		}
		
		/**
		 * For testing purposes.
		 */
		public function populateColumns():void
		{
			var RefCol:Class = Weave.getDefinition('ReferencedColumn');
			var ExtDynCol:Class = Weave.getDefinition('ExtendedDynamicColumn');
			var all:Array = Weave.getDescendants(root, ILinkableDynamicObject);
			var def:Array = [];
			var undef:Array = [];
			for each (var item:ILinkableDynamicObject in all)
			{
				var col:IAttributeColumn = item as IAttributeColumn;
				if (!col)
					continue;
				if (item.target is RefCol)
					def.push(item);
				if (!item.target)
					undef.push(item);
			}
			for (var i:int = 0; i < undef.length; i++)
				copyState(def[i % def.length], undef[i]);
		}
	}
}
