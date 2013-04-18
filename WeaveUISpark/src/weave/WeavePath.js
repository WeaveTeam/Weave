function(objectID)
{
	var weave = objectID ? document.getElementById(objectID) : document;
	
	weave.path = function(path)
	{
		// if there are multiple arguments passed to the function, create an Array
		if (arguments.length != 1 || path.constructor != Array)
			path = A(arguments);
		
		return new WeavePath(path);
	};
	
	// converts an arguments object to an Array
	function A(argumentsObject)
	{
		var array = [];
		var i = argumentsObject.length;
		while (i--)
			array[i] = argumentsObject[i];
		return array;
	}
	
	function WeavePath(path)
	{
		if (!path)
			path = [];
		
		// public variable
		this.weave = weave; // pointer to Weave instance

		// private variables
		var stack = []; // stack of argument counts from push() calls
		var vars = null; // passed to weave.evaluateExpression()
		var libs = []; // passed to weave.evaluateExpression()
		
		/**
		 * Makes a copy of the current path Array.
		 */
		this.getPath = function()
		{
			return this.path.concat();
		};
		
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
				failMessage('pop', 'nothing to pop');
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
					|| failPath('reorder');
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
					|| failPath('state', pathcopy);
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
					|| failPath('diff', pathcopy);
			}
			return this;
		};
		/**
		 * Specifies a variables object to be used in subsequent calls to exec().
		 */
		this.vars = function(newVars)
		{
			vars = newVars;
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
		 * Second parameter is an optional callback that will be passed the result of
		 * evaluating the expression, setting the 'this' pointer to this WeavePath object.
		 */
		this.exec = function(script, callback)
		{
			var result = weave.evaluateExpression(path, script, vars, libs);
			if (callback)
				callback.apply(this, [result]);
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
		function assertParams(methodName, args, minLength)
		{
			if (!minLength)
				minLength = 1;
			if (args.length < minLength)
			{
				var msg = "requires at least " + ((minLength == 1) ? "one parameter" : (minLength + " parameters"));
				failMessage(methodName, msg);
				return false;
			}
			return true;
		}
		function failPath(methodName, path)
		{
			var msg = "command failed (path=" + (path || this.path) + ")";
			failMessage(methodName, msg);
		}
		function failMessage(methodName, message)
		{
			//TODO - mode where error is logged instead of thrown
			throw new Error("WeavePath." + methodName + "(): " + message);
		}
	}
}
