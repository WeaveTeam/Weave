/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package weavejs.path
{
	import weavejs.Weave;

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
		 * Stores JavaScript variables common to all WeavePath objects.
		 * Used by vars(), exec(), and getValue()
		 * @private
		 */
		protected static var _vars:Object = {};
		
		/**
		 * Remembers which JavaScript variables should be unset after the next call to exec() or getValue().
		 * @private
		 */
		protected static var _tempVars:Object = {};
		
		/**
		 * Cleans up temporary variables.
		 * @private
		 */
		protected static function _deleteTempVars():void
		{
			for (var key:String in _tempVars)
				if (_tempVars[key])
					delete _vars[key];
			_tempVars = {};
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
			var args:Array = _A(relativePath, 1);
			var newWeavePath:WeavePath = new this.constructor(this.weave, this._path.concat(args));
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
			if (_assertParams('request', args))
			{
				var type:String = args.pop();
				var pathcopy:Array = this._path.concat(args);
				this.weave.directAPI.requestObject(pathcopy, type)
					|| _failPath('request', pathcopy);
			}
			return this;
		};
		
		/**
		 * Removes a dynamically created object.
		 * @param relativePath An optional Array (or multiple parameters) specifying descendant names relative to the current path.
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @return The current WeavePath object.
		 */
		public function remove(...relativePath):WeavePath
		{
			var pathcopy:Array = this._path.concat(_A(relativePath, 1));
			this.weave.directAPI.removeObject(pathcopy)
				|| _failPath('remove', pathcopy);
			return this;
		};
		
		/**
		 * Reorders the children of an ILinkableHashMap at the current path.
		 * @param orderedNames An Array (or multiple parameters) specifying ordered child names.
		 * @return The current WeavePath object.
		 */
		public function reorder(...orderedNames):WeavePath
		{
			var args:Array = _A(orderedNames, 1);
			if (_assertParams('reorder', args))
			{
				this.weave.directAPI.setChildNameOrder(this._path, args)
					|| _failMessage('reorder', 'path does not refer to an ILinkableHashMap: ' + this._path);
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
				var pathcopy:Array = this._path.concat(args);
				this.weave.directAPI.setSessionState(pathcopy, state, true)
					|| _failObject('state', pathcopy);
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
				var pathcopy:Array = this._path.concat(args);
				this.weave.directAPI.setSessionState(pathcopy, diff, false)
					|| _failObject('diff', pathcopy);
			}
			return this;
		}
		
		/**
		 * Adds a callback to the object at the current path.
		 * When the callback is called, a WeavePath object initialized at the current path will be used as the 'this' context.
		 * If the same callback is added to multiple paths, only the last path will be used as the 'this' context.
		 * @param callback The callback function.
		 * @param triggerCallbackNow Optional parameter, when set to true will trigger the callback now.
		 * @param immediateMode Optional parameter, when set to true will use an immediate callback instead of a grouped callback.
		 * @param delayWhileBusy Optional parameter, specifies whether to delay the callback while the object is busy. Default is true.
		 * @return The current WeavePath object.
		 */
		public function addCallback(callback:Function, triggerCallbackNow:Boolean = false, immediateMode:Boolean = false, delayWhileBusy:Boolean = true):WeavePath
		{
			if (_assertParams('addCallback', arguments))
			{
				var args:Array = Array.prototype.slice.call(arguments);
				args.unshift(this._path);
				this.weave.directAPI.addCallback.apply(this.weave, args)
					|| _failObject('addCallback', this._path);
			}
			return this;
		}
		
		/**
		 * Removes a callback from the object at the current path or from everywhere.
		 * @param callback The callback function.
		 * @param everywhere Optional parameter, if set to true will remove the callback from every object to which it was added.
		 * @return The current WeavePath object.
		 */
		public function removeCallback(callback, everywhere):WeavePath
		{
			if (_assertParams('removeCallback', arguments))
			{
				this.weave.directAPI.removeCallback(this._path, callback, everywhere)
					|| _failObject('removeCallback', this._path);
			}
			return this;
		}
		
		/**
		 * Specifies additional variables to be used in subsequent calls to exec() and getValue().
		 * The variables will be made globally available for any WeavePath object created from the same Weave instance.
		 * @param newVars An object mapping variable names to values.
		 * @param temporary Optional parameter. If set to true, these variables will be unset after the next call to exec() or getValue()
		 *                  no matter how either function is called, including from inside custom WeavePath functions.
		 * @return The current WeavePath object.
		 */
		public function vars(newVars, temporary):WeavePath
		{
			for (var key:String in newVars)
			{
				_tempVars[key] = !!temporary;
				_vars[key] = newVars[key];
			}
			return this;
		}
		
		/**
		 * Specifies additional libraries to be included in subsequent calls to exec() and getValue().
		 * @param libraries An Array (or multiple parameters) specifying ActionScript class names to include as libraries.
		 * @return The current WeavePath object.
		 */
		public function libs(...libraries):WeavePath
		{
			var args:Array = _A(libraries, 1);
			if (_assertParams('libs', args))
			{
				// include libraries for future evaluations
				this.weave.directAPI.evaluateExpression(null, null, null, args);
			}
			return this;
		}
		
		/**
		 * Evaluates an ActionScript expression using the current path, vars, and libs.
		 * The 'this' context within the script will be the object at the current path.
		 * @param script The script to be evaluated by Weave under the scope of the object at the current path.
		 * @param callback_or_variableName Optional callback function or variable name.
		 * - If given a callback function, the function will be passed the result of
		 *   evaluating the expression, setting the 'this' value to the current WeavePath object.
		 * - If given a variable name, the result will be stored as a variable
		 *   as if it was passed as an object property to WeavePath.vars().  It may then be used
		 *   in future calls to WeavePath.exec() or retrieved with WeavePath.getValue().
		 * @return The current WeavePath object.
		 */
		public function exec(script, callback_or_variableName):WeavePath
		{
			var type:String = typeof callback_or_variableName;
			var callback:Function = type == 'function' ? callback_or_variableName : null;
			// Passing "" as the variable name avoids the overhead of converting the ActionScript object to a JavaScript object.
			var variableName:String = type == 'string' ? callback_or_variableName : "";
			_vars[''] = Weave.objectKeys(_vars); // include a list of keys in property '' so undefined variables will be preserved
			var result:* = this.weave.directAPI.evaluateExpression(this._path, script, _vars, null, variableName);
			_deleteTempVars();
			// if an AS var was saved, delete the corresponding JS var if present to avoid overriding it in future expressions
			if (variableName)
				delete _vars[variableName];
			if (callback)
				callback.apply(this, [result]);
			
			return this;
		}
		
		/**
		 * Calls a function using the current WeavePath object as the 'this' value.
		 * @param func The function to call.
		 * @param args An optional list of arguments to pass to the function.
		 * @return The current WeavePath object.
		 */
		public function call(...func_args):WeavePath
		{
			if (_assertParams('call', func_args))
			{
				var a:Array = _A(func_args);
				a.shift().apply(this, a);
			}
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
		public function forEach(items, visitorFunction):WeavePath
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
			args = _A(args);
			this.weave.directAPI.evaluateExpression(null, "weaveTrace.apply(null, args)", {"args": args}, null, "");
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
		
		/**
		 * Gets an Array of child names under the object at the current path or relative to the current path.
		 * @param relativePath An optional Array (or multiple parameters) specifying descendant names relative to the current path.
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @return An Array of child names.
		 */
		public function getNames(...relativePath):Array
		{
			return this.weave.directAPI.getChildNames(this._path.concat(_A(relativePath, 1)));
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
			return this.weave.directAPI.getChildNames(this._path.concat(relativePath))
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
			return this.weave.directAPI.getObjectType(this._path.concat(_A(relativePath, 1)));
		}
		
		/**
		 * Gets the session state of an object at the current path or relative to the current path.
		 * @param relativePath An optional Array (or multiple parameters) specifying descendant names relative to the current path.
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @return The session state of the object at the current or descendant path.
		 */
		public function getState(...relativePath):Object
		{
			return this.weave.directAPI.getSessionState(this._path.concat(_A(relativePath, 1)));
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
				var pathcopy:Array = this._path.concat(args);
				var script:String = "return WeaveAPI.SessionManager.computeDiff(previousState, WeaveAPI.SessionManager.getSessionState(this));";
				return this.weave.directAPI.evaluateExpression(pathcopy, script, {"previousState": previousState});
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
				var pathcopy:Array = this._path.concat(args);
				var script:String = "return WeaveAPI.SessionManager.computeDiff(WeaveAPI.SessionManager.getSessionState(this), otherState);";
				return this.weave.directAPI.evaluateExpression(pathcopy, script, {"otherState": otherState});
			}
			return null;
		}
		
		/**
		 * Returns the value of an ActionScript expression or variable using the current path, vars, and libs.
		 * The 'this' context within the script will be set to the object at the current path.
		 * @param script_or_variableName The script to be evaluated by Weave, or simply a variable name.
		 * @return The result of evaluating the script or variable.
		 */
		public function getValue(script_or_variableName:*):Object
		{
			_vars[''] = Weave.objectKeys(_vars); // include a list of keys in property '' so undefined variables will be preserved
			var result:* = this.weave.directAPI.evaluateExpression(this._path, script_or_variableName, _vars);
			_deleteTempVars();
			return result;
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
				var msg:String = 'requires at least ' + ((minLength == 1) ? 'one parameter' : (minLength + ' parameters'));
				_failMessage(methodName, msg);
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
