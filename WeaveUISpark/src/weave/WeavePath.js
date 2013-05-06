function(objectID)
{
	var weave = objectID ? document.getElementById(objectID) : document;
	
	// browser backwards compatibility
	if (!Array.isArray)
		Array.isArray = function(o) { return Object.prototype.toString.call(o) === '[object Array]'; }
	
	// variables global to this Weave instance

	/**
	 * Creates a WeavePath object.
	 * Accepts an optional Array or list of names to serve as the base path.
	 */
	weave.path = function(/*...names*/)
	{
		return new WeavePath(A(arguments, 1));
	};
	weave.path.callbacks = []; // Used by callbackToString(), maps an integer id to an object with two properties: callback and name
	weave.path.vars = {}; // used with exec() and getVar()
	
	/**
	 * Private function for internal use.
	 * 
	 * Converts an arguments object to an Array.
	 * The first parameter is an arguments object.
	 * The second parameter is an integer flag for special behavior.
	 *   - If set to 1, it handles arguments like (...LIST) where LIST can be either an Array or multiple arguments.
	 *   - If set to 2, it handles arguments like (...LIST, REQUIRED_PARAM) where LIST can be either an Array or multiple arguments.
	 */
	function A(args, option)
	{
		var array;
		var n = args.length;
		if (n && n == option && args[0] && Array.isArray(args[0].constructor))
		{
			array = args[0].concat();
			for (var i = 1; i < n; i++)
				array.push(args[i]);
		}
		else
		{
			array = [];
			while (n--)
				array[n] = args[n];
		}
		return array;
	}
	
	// constructor, accepts a single parameter - the base path Array
	function WeavePath(path)
	{
		if (!path)
			path = [];
		
		// private variables
		var stack = []; // stack of argument counts from push() calls, used with pop()
		
		// public variables and non-chainable methods
		
		/**
		 * A pointer to the Weave instance.
		 */
		this.weave = weave;
		/**
		 * Returns a copy of the current path Array.
		 * Accepts an optional list of names to be appended to the result.
		 */
		this.getPath = function(/*...names*/)
		{
			return path.concat(A(arguments, 1));
		};
		/**
		 * Gets an Array of child names under the current path.
		 * Accepts an optional list of names relative to the current path.
		 */
		this.getNames = function(/*...names*/)
		{
			return weave.getChildNames(path.concat(A(arguments, 1)));
		};
		/**
		 * Gets the object type at the current path.
		 * Accepts an optional list of names relative to the current path.
		 */
		this.getType = function(/*...names*/)
		{
			return weave.getObjectType(path.concat(A(arguments, 1)));
		};
		/**
		 * Gets the session state of an object at the current path or relative to the current path.
		 * Accepts an optional list of names relative to the current path.
		 */
		this.getState = function(/*...names*/)
		{
			return weave.getSessionState(path.concat(A(arguments, 1)));
		};
		/**
		 * Gets the changes that have occurred since previousState.
		 * Accepts an optional list of names relative to the current path.
		 */
		this.getDiff = function(/*...names, previousState*/)
		{
			var args = A(arguments, 2);
			if (assertParams('getDiff', args))
			{
				var otherState = args.pop();
				var pathcopy = path.concat(args);
				var script = "import 'weave.api.WeaveAPI';"
					+ "var sm = WeaveAPI.SessionManager, thisState = sm.getSessionState(this);"
					+ "return sm.computeDiff(otherState, thisState);";
				return weave.evaluateExpression(pathcopy, script, {"otherState": otherState});
			}
			return null;
		}
		/**
		 * Gets the changes that would have to occur to get to another state.
		 * Accepts an optional list of names relative to the current path.
		 */
		this.getReverseDiff = function(/*...names, otherState*/)
		{
			var args = A(arguments, 2);
			if (assertParams('getReverseDiff', args))
			{
				var otherState = args.pop();
				var pathcopy = path.concat(args);
				var script = "import 'weave.api.WeaveAPI';"
					+ "var sm = WeaveAPI.SessionManager, thisState = sm.getSessionState(this);"
					+ "return sm.computeDiff(thisState, otherState);";
				return weave.evaluateExpression(pathcopy, script, {"otherState": otherState});
			}
			return null;
		}
		/**
		 * Gets a variable that was previously specified in WeavePath.vars() or saved with WeavePath.exec() for this Weave instance.
		 * The first parameter is the variable name.
		 */
		this.getVar = function(name)
		{
			return weave.path.vars[name];
		};
		
		
		
		// public chainable methods
		
		/**
		 * Specify any number of names to push on to the end of the path.
		 * Accepts a list of names relative to the current path.
		 */
		this.push = function(/*...names*/)
		{
			var args = A(arguments, 1);
			if (assertParams('push', args))
			{
				// append names to path
				for (var i = 0; i < args.length; i++)
					path.push(args[i]);
				// remember the number of names we appended
				stack.push(args.length);
			}
			return this;
		};
		/**
		 * Pops off all names from previous call to push().  No arguments.
		 */
		this.pop = function()
		{
			if (stack.length)
				path.length -= stack.pop();
			else
				failMessage('pop', 'stack is empty');
			return this;
		};
		/**
		 * Request a new object without modifying the current path.
		 * Accepts an optional list of names relative to the current path.
		 * The final parameter should be the object type to be passed to weave.requestObject().
		 */
		this.request = function(/*...names, objectType*/)
		{
			var args = A(arguments, 2);
			if (assertParams('request', args))
			{
				var type = args.pop();
				var pathcopy = path.concat(args);
				weave.requestObject(pathcopy, type)
					|| failPath('request', pathcopy);
			}
			return this;
		};
		/**
		 * Remove a dynamically created object without modifying the current path.
		 * Accepts an optional list of names relative to the current path.
		 */
		this.remove = function(/*...names*/)
		{
			var pathcopy = path.concat(A(arguments, 1));
			weave.removeObject(pathcopy)
				|| failPath('remove', pathcopy);
			return this;
		};
		/**
		 * Calls weave.setChildNameOrder() for the current path.
		 * Accepts an Array or a list of ordered child names.
		 */
		this.reorder = function(/*...orderedNames*/)
		{
			var args = A(arguments, 1);
			if (assertParams('reorder', args))
			{
				weave.setChildNameOrder(path, args)
					|| failMessage('reorder', 'path does not refer to an ILinkableHashMap: ' + path);
			}
			return this;
		};
		/**
		 * Sets the session state without modifying the current path, removing any
		 * dynamically created objects that do not appear in the new state.
		 * Accepts an optional list of names relative to the current path.
		 * The final parameter should be the session state.
		 */
		this.state = function(/*...names, state*/)
		{
			var args = A(arguments, 2);
			if (assertParams('state', args))
			{
				var state = args.pop();
				var pathcopy = path.concat(args);
				weave.setSessionState(pathcopy, state, true)
					|| failObject('state', pathcopy);
			}
			return this;
		};
		/**
		 * Applies a session state as a diff, keeping any dynamically created objects that do not appear in the new state.
		 * Accepts an optional list of names relative to the current path.
		 * The final parameter should be the session state diff.
		 */
		this.diff = function(/*...names, diff*/)
		{
			var args = A(arguments, 2);
			if (assertParams('diff', args))
			{
				var diff = args.pop();
				var pathcopy = path.concat(args);
				weave.setSessionState(pathcopy, diff, false)
					|| failObject('diff', pathcopy);
			}
			return this;
		};
		/**
		 * Adds a grouped callback to the object at the current path.
		 * When the callback is called, the Weave instance will be passed as the first parameter.
		 * First parameter is the callback function.
		 * Second parameter is a Boolean, when set to true will trigger the callback now.
		 * Since this adds a grouped callback, the callback will not run immediately when addCallback() is called.
		 */
		this.addCallback = function(callback, triggerCallbackNow)
		{
			if (assertParams('addCallback', arguments))
			{
				weave.addCallback(path, callbackToString(callback), triggerCallbackNow)
					|| failObject('addCallback');
			}
			return this;
		};
		/**
		 * Removes a callback from the object at the current path.
		 */
		this.removeCallback = function(callback)
		{
			if (assertParams('removeCallback', arguments))
			{
				weave.removeCallback(path, callbackToString(callback))
					|| failObject('removeCallback');
			}
			return this;
		};
		/**
		 * Specifies additional variables to be used in subsequent calls to exec().
		 * The variables will be made globally available for any WeavePath object created from the same Weave instance.
		 * The first parameter should be an object mapping variable names to values.
		 */
		this.vars = function(newVars)
		{
			var vars = weave.path.vars;
			for (var key in newVars)
				vars[key] = newVars[key];
			return this;
		};
		/**
		 * Specifies additional libraries to be included in subsequent calls to exec().
		 */
		this.libs = function(/*...libraries*/)
		{
			var args = A(arguments, 1);
			if (assertParams('libs', args))
			{
				// include libraries for future evaluations
				weave.evaluateExpression(null, null, null, args);
			}
			return this;
		};
		/**
		 * Calls weave.evaluateExpression() using the current path, vars, and libs.
		 * First parameter is the script to be evaluated by Weave at the current path.
		 * Second parameter is an optional callback or variable name.
		 * - If given a callback function, the function will be passed the result of
		 *   evaluating the expression, setting the 'this' pointer to this WeavePath object.
		 * - If the second parameter is a variable name, the result will be stored as a variable
		 *   as if it was passed as an object property to WeavePath.vars().  It may then be used
		 *   in future calls to WeavePath.exec() or retrieved with WeavePath.getVar().
		 */
		this.exec = function(script, callback_or_variableName)
		{
			var vars = weave.path.vars;
			var result = weave.evaluateExpression(path, script, vars);
			if (typeof callback_or_variableName == 'function')
				callback_or_variableName.apply(this, [result]);
			else
				vars[callback_or_variableName] = result;
			return this;
		};
		/**
		 * Applies a function with optional parameters, setting 'this' pointer to the WeavePath object
		 */
		this.call = function(func/*[, ...args]*/)
		{
			if (assertParams('call', arguments))
			{
				var a = A(arguments);
				a.shift().apply(this, a);
			}
			return this;
		};
		/**
		 * Applies a function to each item in an Array or an Object.
		 * If items is an Array, this has the same effect as WeavePath.call(function(){ itemsArray.forEach(visitorFunction, this); }).
		 * If items is an Object, it will behave like WeavePath.call(function(){ for(var key in items) visitorFunction.call(this, items[key], key, items); }).
		 */
		this.forEach = function(items, visitorFunction)
		{
			if (assertParams('forEach', arguments, 2))
			{
				if (Array.isArray(items.constructor))
					items.forEach(visitorFunction, this);
				else
					for (var key in items) visitorFunction.call(this, items[key], key, items);
			}
			return this;
		};
		
		// private functions
		function callbackToString(callback)
		{
			var list = weave.path.callbacks;
			for (var i in list)
				if (list[i].callback == callback)
					return list[i].name;
			
			var idStr;
			try
			{
				idStr = JSON.stringify(objectID);
			}
			catch (e)
			{
				idStr = '"' + objectId + '"';
			}
			
			var name = 'function(){' +
				'  var weave = document.getElementById('+idStr+');' +
				'  weave.path.callbacks['+list.length+'].callback.call(null, weave);' +
				'}';
			
			list.push({ 'callback': callback, 'name': name });
			
			return name;
		}
		function assertParams(methodName, args, minLength)
		{
			if (!minLength)
				minLength = 1;
			if (args.length < minLength)
			{
				var msg = 'requires at least ' + ((minLength == 1) ? 'one parameter' : (minLength + ' parameters'));
				failMessage(methodName, msg);
				return false;
			}
			return true;
		}
		function failPath(methodName, path)
		{
			var msg = 'command failed (path: ' + (path || this.path) + ')';
			failMessage(methodName, msg);
		}
		function failObject(methodName, path)
		{
			var msg = 'object does not exist (path: ' + (path || this.path) + ')';
			failMessage(methodName, msg);
		}
		function failMessage(methodName, message)
		{
			var str = 'WeavePath.' + methodName + '(): ' + message;
			
			//TODO - mode where error is logged instead of thrown
			//console.log(str);
			
			throw new Error(str);
		}
	}
}
