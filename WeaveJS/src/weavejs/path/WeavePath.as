/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package weavejs.path
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.ILinkableDynamicObject;
	import weavejs.api.core.ILinkableHashMap;
	import weavejs.api.core.ILinkableObject;
	import weavejs.core.SessionManager;
	import weavejs.utils.JS;
	import weavejs.utils.StandardLib;

	public class WeavePath
	{
		/**
		 * A pointer to the Weave instance.
		 */
		public var weave:Weave;
		
		protected var _path:Array;
		protected var _parent:WeavePath;
		
		/**
		 * WeavePath constructor.  WeavePath objects are immutable after they are created.
		 * @class WeavePath
		 * @param basePath An optional Array specifying the path to an object in the session state.
		 *                 A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @return A WeavePath object.
		 */
		public function WeavePath(weave:Weave, basePath:Array)
		{
			this.weave = weave;
			
			// "private" instance variables
			this._path = _A(basePath, 1);
			this._parent = null; // parent WeavePath returned by pop()
		}
		
		/**
		 * Private function for internal use.
		 * 
		 * Converts an arguments object to an Array.
		 * @param args An arguments object.
		 * @param option An integer flag for special behavior.
		 *   - If set to 1, it handles arguments like (...LIST) where LIST can be either an Array or multiple arguments.
		 *   - If set to 2, it handles arguments like (...LIST, REQUIRED_PARAM) where LIST can be either an Array or multiple arguments.
		 * @private
		 */
		protected static function _A(args:Array, option:int = 0):Array
		{
			if (args.length == option && args[0] is Array)
				return [].concat(args[0], Array.prototype.slice.call(args, 1));
			return Array.prototype.slice.call(args);
		}
		
		// public chainable methods
		
		/**
		 * Creates a new WeavePath relative to the current one.
		 * @param relativePath An Array (or multiple parameters) specifying descendant names relative to the current path.
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @return A new WeavePath object which remembers the current WeavePath as its parent.
		 */
		public function push(...relativePath):WeavePath
		{
			relativePath = _A(relativePath, 1);
			var newWeavePath:WeavePath = new this.constructor(this.weave, this.getPath(relativePath));
			newWeavePath._parent = this;
			return newWeavePath;
		}
		
		/**
		 * Returns to the previous WeavePath that spawned the current one with push().
		 * @return The parent WeavePath object.
		 */
		public function pop():WeavePath
		{
			if (this._parent)
				return this._parent;
			else
				_failMessage('pop', 'stack is empty');
			return null;
		}
		
		/**
		 * Requests that an object be created if it doesn't already exist at the current path (or relative path, if specified).
		 * This function can also be used to assert that the object at the current path is of the type you expect it to be.
		 * @param relativePath An optional Array (or multiple parameters) specifying descendant names relative to the current path.
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @param objectType The name of an ActionScript class in Weave.
		 * @return The current WeavePath object.
		 */
		public function request(...relativePath_objectType):WeavePath
		{
			var args:Array = _A(relativePath_objectType, 2);
			if (!_assertParams('request', args))
				return this;
			
			var type:String = args.pop();
			var relativePath:Array = args;

			var classDef:Class;
			var className:String;
			if (JS.isClass(type))
			{
				classDef = JS.asClass(type);
				className = Weave.className(classDef);
			}
			else
			{
				className = type as String; // may not be full qualified class name, but useful for error messages
				classDef = Weave.getDefinition(className);
				if (!classDef)
					throw new Error("No class definition for {0}", className);
			}
			
			// stop if at root path
			var objectPath:Array = _path.concat(relativePath);
			if (!objectPath.length)
			{
				// check for exact class match only
				if (Object(weave.root).constructor == classDef)
					return this;
				
				throw new Error("Cannot request an object at the root path");
			}
			
			// Get parent object first in case there is some backwards compatibility code that gets
			// executed when it is accessed (registering deprecated class definitions, for example).
			var parentPath:Array = objectPath.concat();
			var childName:Object = parentPath.pop();
			var parent:ILinkableObject = weave.getObject(parentPath);
			
			// request the child object
			var hashMap:ILinkableHashMap = parent as ILinkableHashMap;
			var dynamicObject:ILinkableDynamicObject = parent as ILinkableDynamicObject;
			var child:Object = null;
			if (hashMap)
			{
				if (childName is Number)
					childName = hashMap.getNames()[childName];
				child = hashMap.requestObject(childName as String, classDef, false);
			}
			else if (dynamicObject)
				child = dynamicObject.requestGlobalObject(childName as String, classDef, false);
			else
				child = weave.getObject(objectPath);
			
			// check for exact match only
			if (child && child.constructor == classDef)
				return this;
			
			throw new Error(StandardLib.substitute("Request for {0} failed at path {1}", type as String || Weave.className(type), JSON.stringify(objectPath)));
		};
		
		/**
		 * Removes a dynamically created object.
		 * @param relativePath An optional Array (or multiple parameters) specifying descendant names relative to the current path.
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @return The current WeavePath object.
		 */
		public function remove(...relativePath):WeavePath
		{
			relativePath = _A(relativePath, 1);
			
			if (_path.length + relativePath.length == 0)
				throw new Error("Cannot remove root object");
			
			var parentPath:Array = _path.concat(relativePath);
			var childName:Object = parentPath.pop();
			var parent:ILinkableObject = weave.getObject(parentPath);
			
			var hashMap:ILinkableHashMap = parent as ILinkableHashMap;
			if (hashMap)
			{
				if (childName is Number)
					childName = hashMap.getNames()[childName];
				
				if (hashMap.objectIsLocked(childName as String))
					throw new Error("Object is locked and cannot be removed: " + push(relativePath));
				
				hashMap.removeObject(childName as String);
				return this;
			}
			
			var dynamicObject:ILinkableDynamicObject = parent as ILinkableDynamicObject;
			if (dynamicObject)
			{
				if (dynamicObject.locked)
					throw new Error("Object is locked and cannot be removed: " + push(relativePath));
				
				dynamicObject.removeObject();
				return this;
			}
			
			if (parent)
				throw new Error("Parent object does not support dynamic children, so cannot remove child: " + push(relativePath));
			else
				throw new Error("No parent from which to remove a child: " + push(relativePath));
		};
		
		/**
		 * Reorders the children of an ILinkableHashMap at the current path.
		 * @param orderedNames An Array (or multiple parameters) specifying ordered child names.
		 * @return The current WeavePath object.
		 */
		public function reorder(...orderedNames):WeavePath
		{
			orderedNames = _A(orderedNames, 1);
			if (_assertParams('reorder', orderedNames))
			{
				var hashMap:ILinkableHashMap = this.getObject() as ILinkableHashMap;
				if (hashMap)
				{
					// it's ok if there are no names specified, because that wouldn't accomplish anything anyway
					if (orderedNames)
						hashMap.setNameOrder(orderedNames);
				}
				
				_failMessage('reorder', 'path does not refer to an ILinkableHashMap: ' + this);
			}
			return this;
		};
		
		/**
		 * Sets the session state of the object at the current path or relative to the current path.
		 * Any existing dynamically created objects that do not appear in the new state will be removed.
		 * @param relativePath An optional Array (or multiple parameters) specifying descendant names relative to the current path.
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @param state The session state to apply.
		 * @return The current WeavePath object.
		 */
		public function state(...relativePath_state):WeavePath
		{
			var args:Array = _A(relativePath_state, 2);
			if (_assertParams('state', args))
			{
				var state:Object = args.pop();
				var obj:ILinkableObject = this.getObject(args);
				if (obj)
					Weave.setState(obj, state, true);
				else
					_failObject('state', this.getPath(args));
			}
			return this;
		};
		
		/**
		 * Applies a session state diff to the object at the current path or relative to the current path.
		 * Existing dynamically created objects that do not appear in the new state will remain unchanged.
		 * @param relativePath An optional Array (or multiple parameters) specifying descendant names relative to the current path.
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @param diff The session state diff to apply.
		 * @return The current WeavePath object.
		 */
		public function diff(...relativePath_diff):WeavePath
		{
			var args:Array = _A(relativePath_diff, 2);
			if (_assertParams('diff', args))
			{
				var diff:Object = args.pop();
				var obj:ILinkableObject = this.getObject(args);
				if (obj)
					Weave.setState(obj, diff, false);
				else
					_failObject('diff', this.getPath(args));
			}
			return this;
		}
		
		/**
		 * Adds a callback to the object at the current path.
		 * When the callback is called, a WeavePath object initialized at the current path will be used as the 'this' context.
		 * If the same callback is added to multiple paths, only the last path will be used as the 'this' context.
		 * @param relevantContext The thisArg for the function. When the context is disposed with Weave.dispose(), the callback will be disabled.
		 * @param callback The callback function.
		 * @param triggerCallbackNow Optional parameter, when set to true will trigger the callback now.
		 * @param immediateMode Optional parameter, when set to true will use an immediate callback instead of a grouped callback.
		 * @param delayWhileBusy Optional parameter, specifies whether to delay a grouped callback while the object is busy. Default is true.
		 * @return The current WeavePath object.
		 */
		public function addCallback(relevantContext:Object, callback:Function, triggerCallbackNow:Boolean = false, immediateMode:Boolean = false, delayWhileBusy:Boolean = true):WeavePath
		{
			// backwards compatibility - shift arguments
			if (typeof relevantContext === 'function' && typeof callback !== 'function')
			{
				if (arguments.length > 3)
					delayWhileBusy = immediateMode;
				if (arguments.length > 2)
					immediateMode = triggerCallbackNow;
				if (arguments.length > 1)
					triggerCallbackNow = callback;
				if (arguments.length > 0)
					callback = relevantContext as Function;
				relevantContext = null;
			}
			else if (!_assertParams('addCallback', arguments, 2))
				return this;
			
			// When no context is specified, save a pointer to this WeavePath object
			// on the callback function itself where CallbackCollection looks for it.
			if (!relevantContext)
				callback['this'] = this;
			
			var object:ILinkableObject = getObject();
			if (!object)
				throw new Error("No ILinkableObject to which to add a callback: " + this);
			
			if (immediateMode)
				Weave.getCallbacks(object).addImmediateCallback(relevantContext, callback, triggerCallbackNow, false);
			else
				Weave.getCallbacks(object).addGroupedCallback(relevantContext, callback, triggerCallbackNow, delayWhileBusy);
			return this;
		}
		
		/**
		 * Removes a callback from the object at the current path or from everywhere.
		 * @param relevantContext The relevantContext parameter that was given when the callback was added.
		 * @param callback The callback function.
		 * @return The current WeavePath object.
		 */
		public function removeCallback(relevantContext:Object, callback:Function):WeavePath
		{
			var object:ILinkableObject = getObject();
			if (!object)
				throw new Error("No ILinkableObject from which to remove a callback: " + this);
			
			// backwards compatibility
			if (arguments.length == 1 && typeof relevantContext === 'function')
			{
				callback = relevantContext as Function;
				relevantContext = null;
			}
			else if (!_assertParams('removeCallback', arguments, 2))
				return this;
			
			Weave.getCallbacks(object).removeCallback(relevantContext || this, callback);
			return this;
		}
		
		/**
		 * Evaluates an ActionScript expression using the current path, vars, and libs.
		 * The 'this' context within the script will be the object at the current path.
		 * @param script_or_function Either a String containing JavaScript code, or a Function.
		 * @param callback Optional callback function to be passed the result of evaluating the script or function. The 'this' argument will be the current WeavePath object.
		 * @return The current WeavePath object.
		 */
		public function exec(script_or_function:*, callback:Function = null):WeavePath
		{
			if (_assertParams('exec', arguments))
			{
				var result:* = getValue(script_or_function);
				if (callback != null)
					callback.call(this, result);
			}
			return this;
		}
		
		/**
		 * Calls a function using the current WeavePath object as the 'this' value.
		 * @param func The function to call.
		 * @param args An optional list of arguments to pass to the function.
		 * @return The current WeavePath object.
		 */
		public function call(func:Function, ...args):WeavePath
		{
			if (!func)
				_assertParams('call', []);
			else
				func.apply(this, args);
			return this;
		}
		
		/**
		 * Applies a function to each item in an Array or an Object.
		 * @param items Either an Array or an Object to iterate over.
		 * @param visitorFunction A function to be called for each item in items. The function will be called using the current
		 *                        WeavePath object as the 'this' value and will receive three parameters:  item, key, items.
		 *                        If items is an Array, the key will be an integer. If items is an Object, the key will be a String.
		 * @return The current WeavePath object.
		 */
		public function forEach(items:Object, visitorFunction:Function):WeavePath
		{
			if (_assertParams('forEach', arguments, 2))
			{
				if (items is Array && Array.prototype.forEach)
					items.forEach(visitorFunction, this);
				else
					for (var key:String in items) visitorFunction.call(this, items[key], key, items);
			}
			return this;
		}
		
		/**
		 * Calls a function for each child of the current WeavePath or the one specified by a relativePath. The function receives child names.
		 * @param relativePath An optional Array (or multiple parameters) specifying descendant names relative to the current path.
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @param visitorFunction A function to be called for each child object. The function will be called using the current
		 *                        WeavePath object as the 'this' value and will receive three parameters:  name, index, names.
		 * @return The current WeavePath object.
		 */
		public function forEachName(...relativePath_visitorFunction):WeavePath
		{
			var args:Array = _A(relativePath_visitorFunction, 2);
			if (_assertParams('forEachName', args))
			{
				var visitorFunction:Function = args.pop() as Function;
				this.getNames(args).forEach(visitorFunction, this);
			}
			return this;
		}
		
		/**
		 * Calls a function for each child of the current WeavePath or the one specified by a relativePath. The function receives child WeavePath objects.
		 * @param relativePath An optional Array (or multiple parameters) specifying descendant names relative to the current path.
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @param visitorFunction A function to be called for each child object. The function will be called using the current
		 *                        WeavePath object as the 'this' value and will receive three parameters:  child, index, children.
		 * @return The current WeavePath object.
		 */
		public function forEachChild(...relativePath_visitorFunction):WeavePath
		{
			var args:Array = _A(relativePath_visitorFunction, 2);
			if (_assertParams('forEachChild', args))
			{
				var visitorFunction:Function = args.pop();
				this.getChildren(args).forEach(visitorFunction, this);
			}
			return this;
		}
		
		/**
		 * Calls weaveTrace() in Weave to print to the log window.
		 * @param args A list of parameters to pass to weaveTrace().
		 * @return The current WeavePath object.
		 */
		public function trace(...args):WeavePath
		{
			JS.log.apply(Weave, _A(args));
			return this;
		}
		
		
		// non-chainable methods
		
		/**
		 * Returns a copy of the current path Array or the path Array of a descendant object.
		 * @param relativePath An optional Array (or multiple parameters) specifying descendant names to be appended to the result.
		 * @return An Array of successive child names used to identify an object in a Weave session state.
		 */
		public function getPath(...relativePath):Array
		{
			return this._path.concat(_A(relativePath, 1));
		}
		
		private function _getChildNames(...relativePath):Array
		{
			relativePath = _A(relativePath, 1);
			var object:ILinkableObject = this.getObject(relativePath);
			if (object)
			{
				if (object is ILinkableHashMap)
					return (object as ILinkableHashMap).getNames();
				if (object is ILinkableDynamicObject)
					return [null];
				return (WeaveAPI.SessionManager as SessionManager).getLinkablePropertyNames(object, true);
			}
			
			throw new Error("No ILinkableObject for which to get child names at " + this);
		}
		
		/**
		 * Gets an Array of child names under the object at the current path or relative to the current path.
		 * @param relativePath An optional Array (or multiple parameters) specifying descendant names relative to the current path.
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @return An Array of child names.
		 */
		public function getNames(...relativePath):Array
		{
			relativePath = _A(relativePath, 1);
			return _getChildNames(relativePath)
		}
		
		/**
		 * Gets an Array of child WeavePath objects under the object at the current path or relative to the current path.
		 * @param relativePath An optional Array (or multiple parameters) specifying descendant names relative to the current path.
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @return An Array of child WeavePath objects.
		 */
		public function getChildren(...relativePath):Array
		{
			relativePath = _A(relativePath, 1);
			return _getChildNames(relativePath)
				.map(function(name:String):WeavePath { return this.push(relativePath.concat(name)); }, this);
		}
		
		/**
		 * Gets the type (qualified class name) of the object at the current path or relative to the current path.
		 * @param relativePath An optional Array (or multiple parameters) specifying descendant names relative to the current path.
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @return The qualified class name of the object at the current or descendant path, or null if there is no object.
		 */
		public function getType(...relativePath):String
		{
			relativePath = _A(relativePath, 1);
			return Weave.className(this.getObject(relativePath));
		}
		
		/**
		 * Gets the session state of an object at the current path or relative to the current path.
		 * @param relativePath An optional Array (or multiple parameters) specifying descendant names relative to the current path.
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @return The session state of the object at the current or descendant path.
		 */
		public function getState(...relativePath):Object
		{
			relativePath = _A(relativePath, 1);
			var obj:ILinkableObject = this.getObject(relativePath);
			if (obj)
				return Weave.getState(obj);
			else
				JS.error("No ILinkableObject from which to get session state at " + this.push(relativePath));
			return null;
		}
		
		/**
		 * Gets the changes that have occurred since previousState for the object at the current path or relative to the current path.
		 * @param relativePath An optional Array (or multiple parameters) specifying descendant names relative to the current path.
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @param previousState The previous state for comparison.
		 * @return A session state diff.
		 */
		public function getDiff(...relativePath_previousState):Object
		{
			var args:Array = _A(relativePath_previousState, 2);
			if (_assertParams('getDiff', args))
			{
				var previousState:Object = args.pop();
				var obj:ILinkableObject = this.getObject(args);
				if (obj)
					return Weave.computeDiff(previousState, Weave.getState(obj));
				else
					JS.error("No ILinkableObject from which to get diff at " + this.push(args));
			}
			return null;
		}
		
		/**
		 * Gets the changes that would have to occur to get to another state for the object at the current path or relative to the current path.
		 * @param relativePath An optional Array (or multiple parameters) specifying descendant names relative to the current path.
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @param otherState The other state for comparison.
		 * @return A session state diff.
		 */
		public function getReverseDiff(...relativePath_otherState):Object
		{
			var args:Array = _A(relativePath_otherState, 2);
			if (_assertParams('getReverseDiff', args))
			{
				var otherState:Object = args.pop();
				var obj:ILinkableObject = this.getObject(args);
				if (obj)
					return Weave.computeDiff(Weave.getState(obj), otherState);
				else
					JS.error("No ILinkableObject from which to get reverse diff at " + this.push(args));
			}
			return null;
		}
		
		/**
		 * Returns the value of an ActionScript expression or variable using the current path as the 'this' argument.
		 * @param script_or_function Either a String containing JavaScript code, or a Function.
		 * @return The result of evaluating the script or function.
		 */
		public function getValue(script_or_function:*, ...args):Object
		{
			if (!script_or_function)
				_assertParams('getValue', []);
			
			if (script_or_function is String)
				script_or_function = JS.compile(script_or_function);
			
			return script_or_function.apply(this, args);
		}
		
		public function getObject(...relativePath):ILinkableObject
		{
			relativePath = _A(relativePath, 1);
			return weave.getObject(this.getPath(relativePath));
		}
		
		/**
		 * Provides a human-readable string containing the path.
		 */
		public function toString():String
		{
			return "WeavePath(" + JSON.stringify(this._path) + ")";
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		// helper functions
		protected static function _assertParams(methodName:String, args:Array, minLength:int = 1):Boolean
		{
			if (!minLength)
				minLength = 1;
			if (args.length < minLength)
			{
				var min_params:String = (minLength == 1) ? 'one parameter' : (minLength + ' parameters');
				_failMessage(methodName, 'requires at least ' + min_params);
				return false;
			}
			return true;
		}
		
		protected static function _failPath(methodName:String, path:Array):*
		{
			_failMessage(methodName, 'command failed', path);
		}
		
		protected static function _failObject(methodName:String, path:Array):*
		{
			_failMessage(methodName, 'object does not exist', path);
		}
		
		protected static function _failMessage(methodName:String, message:String, path:Array = null):*
		{
			var str:String = 'WeavePath.' + methodName + '(): ' + message;
			if (path)
				str += ' (path: ' + JSON.stringify(path) + ')';
			throw new Error(str);
		}
	}
}
