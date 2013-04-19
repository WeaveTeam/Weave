function(objectID)
{
	var weave = objectID ? document.getElementById(objectID) : document;
	
	/**
	 * Creates a WeavePath object.
	 * Accepts an optional Array or list of names to serve as the base path.
	 */
	weave.path = function(names/*, ...rest*/)
	{
		// if there are multiple arguments passed to the function, create an Array
		if (arguments.length != 1 || names.constructor != Array)
			names = A(arguments);
		
		return new WeavePath(names);
	};
	
	// Used by callbackToString(), maps an integer id to an object with two properties: callback and name
	weave._WeavePathCallbacks = [];
	
	// converts an arguments object to an Array
	function A(argumentsObject)
	{
		var array = [];
		var i = argumentsObject.length;
		while (i--)
			array[i] = argumentsObject[i];
		return array;
	}
	
	// constructor, accepts a single parameter - the base path Array
	function WeavePath(path)
	{
		if (!path)
			path = [];
		
		// private variables
		var stack = []; // stack of argument counts from push() calls, used with pop()
		var vars = {}; // used with exec() and getVar()
		var libs = []; // used with exec()
		
		// public variables and non-chainable methods
		
		/**
		 * A pointer to the Weave instance.
		 */
		this.weave = weave;
		/**
		 * Makes a copy of the current path Array.
		 */
		this.getPath = function()
		{
			return this.path.concat();
		};
		/**
		 * Gets the session state of an object at the current path or relative to the current path.
		 * Accepts an optional list of names relative to the current path.
		 */
		this.getState = function(/*...names*/)
		{
			return weave.getSessionState(path.concat(A(arguments)));
		};
		/**
		 * Gets the object type at the current path.
		 */
		this.getType = function()
		{
			return weave.getObjectType(path);
		};
		/**
		 * Gets an Array of child names under the current path.
		 */
		this.getNames = function()
		{
			return weave.getChildNames(path);
		};
		/**
		 * Gets a variable that was previously specified in WeavePath.vars() or saved with WeavePath.exec().
		 * The first parameter is the variable name. 
		 */
		this.getVar = function(name)
		{
			return vars[name];
		};
		
		
		
		// public chainable methods
		
		/**
		 * Specify any number of names to push on to the end of the path.
		 * Accepts an optional list of names relative to the current path.
		 */
		this.push = function(/*...names*/)
		{
			if (assertParams('push', arguments))
			{
				// append names to path
				for (var i = 0; i < arguments.length; i++)
					path.push(arguments[i]);
				// remember the number of names we appended
				stack.push(arguments.length);
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
		 * The final parameter should be the object type passed to weave.requestObject().
		 */
		this.request = function(/*...names, objectType*/)
		{
			if (assertParams('request', arguments))
			{
				var pathcopy = path.concat(A(arguments));
				var type = pathcopy.pop();
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
			var pathcopy = path.concat(A(arguments));
			weave.removeObject(pathcopy)
				|| failPath('remove', pathcopy);
			return this;
		};
		/**
		 * Calls weave.setChildNameOrder() for the current path.
		 * Accepts a list of ordered child names.
		 */
		this.reorder = function(/*...orderedNames*/)
		{
			if (assertParams('reorder', arguments))
			{
				weave.setChildNameOrder(path, A(arguments))
					|| failMessage('reorder', 'path does not refer to an ILinkableHashMap: ' + path);
			}
			return this;
		};
		/**
		 * Sets the session state without modifying the current path, removing any
		 * dynamically created objects that do not appear in the new state.
		 * Accepts an optional list of names relative to the current path.
		 * The final parameter should be the session state diff.
		 */
		this.state = function(/*...names, state*/)
		{
			if (assertParams('state', arguments))
			{
				var pathcopy = path.concat(A(arguments));
				var state = pathcopy.pop();
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
			if (assertParams('diff', arguments))
			{
				var pathcopy = path.concat(A(arguments));
				var diff = pathcopy.pop();
				weave.setSessionState(pathcopy, diff, false)
					|| failObject('diff', pathcopy);
			}
			return this;
		};
		/**
		 * Specifies additional variables to be used in subsequent calls to exec().
		 * The parameter should be an object mapping variable names to their values.
		 */
		this.vars = function(newVars)
		{
			for (var key in newVars)
				vars[key] = newVars[key];
			return this;
		};
		/**
		 * Specifies additional libraries to be included in subsequent calls to exec().
		 */
		this.libs = function(/*...libraries*/)
		{
			if (assertParams('libs', arguments))
				A(arguments).forEach(function(lib){ if (libs.indexOf(lib) < 0) libs.push(lib); });
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
			var result = weave.evaluateExpression(path, script, vars, libs);
			if (typeof callback_or_variableName == 'function')
				callback_or_variableName.apply(this, [result]);
			else
				vars[callback_or_variableName] = result;
			return this;
		};
		/**
		 * Adds a grouped callback to the object at the current path.
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
				if (items.constructor == Array)
					items.forEach(visitorFunction, this);
				else
					for (var key in items) visitorFunction.call(this, items[key], key, items);
			}
			return this;
		};
		
		// private functions
		function callbackToString(callback)
		{
			var list = weave._WeavePathCallbacks;
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
				'  weave._WeavePathCallbacks['+list.length+'].callback.call(weave);' +
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
