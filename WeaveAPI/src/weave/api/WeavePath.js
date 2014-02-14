// This code assumes it is being executed within a function(){} where the 'weave' variable is defined.

if (!weave.id)
	weave.id = 'weave';

// browser backwards compatibility
if (!Array.isArray)
	Array.isArray = function(o) { return Object.prototype.toString.call(o) === '[object Array]'; }

// variables global to this Weave instance

/**
 * Creates a WeavePath object.
 * Accepts an optional Array or list of names to serve as the base path, which cannot be removed with pop().
 * A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 */
weave.path = function(/*...basePath*/)
{
	return new WeavePath(A(arguments, 1));
};
weave.path.vars = {}; // used with exec() and getVar()
weave.path.callbacks = []; // Used by callbackToString(), maps an integer id to an object with properties: callback, name, path

// enhance weave.addCallback() to support function pointers
var _addCallback = weave.addCallback;
weave.addCallback = function(target, callback, triggerNow, immediateMode)
{
	if (typeof callback == 'function')
		callback = callbackToString(callback, Array.isArray(target) ? weave.path(target) : weave.path());
	return _addCallback.call(this, target, callback, triggerNow, immediateMode);
};
// enhance weave.removeCallback() to support function pointers
var _removeCallback = weave.removeCallback;
weave.removeCallback = function(target, callback)
{
	if (typeof callback == 'function')
		callback = callbackToString(callback); // don't update path when removing callback
	return _removeCallback.call(this, target, callback);
};

/**
 * Private function for internal use with weave.addCallback() and weave.removeCallback().
 */
function callbackToString(callback, path)
{
	var list = weave.path.callbacks;
	for (var i in list)
	{
		if (list[i].callback == callback)
		{
			// update path if specified
			if (path)
				list[i]['path'] = path;
			return list[i]['string'];
		}
	}
	
	var list = weave.path.callbacks;
	var idStr = JSON && JSON.stringify ? JSON.stringify(weave.id) : '"' + weave.id + '"';
	var string = 'function(){' +
			'var weave = document.getElementById('+idStr+');' +
			'var obj = weave.path.callbacks['+list.length+'];' +
			'obj.callback.apply(obj.path);' +
		'}';
	list.push({
		"callback": callback,
		"string": string,
		"path": path
	});
	return string;
}

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
	var array = [];
	var n = args.length;
	if (n && n == option && args[0] && Array.isArray(args[0]))
	{
		// this will support foreign arrays
		array = array.concat(args[0]);
		for (var i = 1; i < n; i++)
			array.push(args[i]);
	}
	else
	{
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
	this.getPath = function(/*...relativePath*/)
	{
		return path.concat(A(arguments, 1));
	};
	/**
	 * Gets an Array of child names under the object at the current path or relative to the current path.
	 * Accepts an optional list of names relative to the current path.
	 */
	this.getNames = function(/*...relativePath*/)
	{
		return weave.getChildNames(path.concat(A(arguments, 1)));
	};
	/**
	 * Gets the type (qualified class name) of the object at the current path or relative to the current path.
	 * Accepts an optional list of names relative to the current path.
	 */
	this.getType = function(/*...relativePath*/)
	{
		return weave.getObjectType(path.concat(A(arguments, 1)));
	};
	/**
	 * Gets the session state of an object at the current path or relative to the current path.
	 * Accepts an optional list of names relative to the current path.
	 */
	this.getState = function(/*...relativePath*/)
	{
		return weave.getSessionState(path.concat(A(arguments, 1)));
	};
	/**
	 * Gets the changes that have occurred since previousState for the object at the current path or relative to the current path.
	 * Accepts an optional list of names relative to the current path.
	 */
	this.getDiff = function(/*...relativePath, previousState*/)
	{
		var args = A(arguments, 2);
		if (assertParams('getDiff', args))
		{
			var otherState = args.pop();
			var pathcopy = path.concat(args);
			var script = "import 'weave.api.WeaveAPI';"
				+ "import 'weave.api.core.ILinkableObject';"
				+ "return WeaveAPI.SessionManager.computeDiff(otherState, this is ILinkableObject ? WeaveAPI.SessionManager.getSessionState(this) : null);";
			return weave.evaluateExpression(pathcopy, script, {"otherState": otherState});
		}
		return null;
	}
	/**
	 * Gets the changes that would have to occur to get to another state for the object at the current path or relative to the current path.
	 * Accepts an optional list of names relative to the current path.
	 */
	this.getReverseDiff = function(/*...relativePath, otherState*/)
	{
		var args = A(arguments, 2);
		if (assertParams('getReverseDiff', args))
		{
			var otherState = args.pop();
			var pathcopy = path.concat(args);
			var script = "import 'weave.api.WeaveAPI';"
				+ "import 'weave.api.core.ILinkableObject';"
				+ "return WeaveAPI.SessionManager.computeDiff(this is ILinkableObject ? WeaveAPI.SessionManager.getSessionState(this) : null, otherState);";
			return weave.evaluateExpression(pathcopy, script, {"otherState": otherState});
		}
		return null;
	}
	/**
	 * Returns the value of an ActionScript expression or variable using the current path, vars, and libs.
	 * The 'this' context within the script will be set to the object at the current path.
	 * First parameter is the script to be evaluated by Weave, or simply a variable name.
	 */
	this.getValue = function(script_or_variableName)
	{
		return weave.evaluateExpression(path, script_or_variableName, weave.path.vars);
	};
	
	
	
	// public chainable methods
	
	/**
	 * Specify any number of names to push on to the end of the path.
	 * Accepts a list of names relative to the current path.
	 * A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
	 */
	this.push = function(/*...relativePath*/)
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
	 * Requests that an object be created if it doesn't already exist at (or relative to) the current path.
	 * Accepts an optional list of names relative to the current path.
	 * The final parameter should be the name of an ActionScript class in Weave.
	 */
	this.request = function(/*...relativePath, objectType*/)
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
	 * Removes a dynamically created object.
	 * Accepts an optional list of names relative to the current path.
	 */
	this.remove = function(/*...relativePath*/)
	{
		var pathcopy = path.concat(A(arguments, 1));
		weave.removeObject(pathcopy)
			|| failPath('remove', pathcopy);
		return this;
	};
	/**
	 * Reorders the children of an ILinkableHashMap at the current path.
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
	 * Sets the session state of the object at the current path or relative to the current path.
	 * Any existing dynamically created objects that do not appear in the new state will be removed.
	 * Accepts an optional list of names relative to the current path.
	 * The final parameter should be the session state.
	 */
	this.state = function(/*...relativePath, state*/)
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
	 * Applies a session state diff to the object at the current path or relative to the current path.
	 * Existing dynamically created objects that do not appear in the new state will remain unchanged.
	 * Accepts an optional list of names relative to the current path.
	 * The final parameter should be the session state diff.
	 */
	this.diff = function(/*...relativePath, diff*/)
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
	 * Adds a callback to the object at the current path.
	 * When the callback is called, a WeavePath object initialized at the current path will be used as the 'this' context.
	 * First parameter is the callback function.
	 * Second parameter is a Boolean, when set to true will trigger the callback now.
	 * Third parameter is a Boolean, when set to true will use an immediate callback instead of a grouped callback.
	 * If the same callback is added to multiple paths, only the last path will be used as the 'this' context.
	 */
	this.addCallback = function(callback, triggerCallbackNow, immediateMode)
	{
		if (assertParams('addCallback', arguments))
		{
			callback = callbackToString(callback, weave.path(path.concat()));
			weave.addCallback(path, callback, triggerCallbackNow, immediateMode)
				|| failObject('addCallback', path);
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
			weave.removeCallback(path, callback)
				|| failObject('removeCallback', path);
		}
		return this;
	};
	/**
	 * Specifies additional variables to be used in subsequent calls to exec().
	 * The variables will be made globally available for any WeavePath object created from the same Weave instance.
	 * The first parameter should be an object mapping variable names to values.
	 * The second parameter should be set to true when the variables contain Arrays which were created by a different window.
	 * Note that if you set containsForeignArrays to true, any nested values of NaN or Infinity will be converted to null.
	 */
	this.vars = function(newVars, containsForeignArrays)
	{
		var vars = weave.path.vars;
		for (var key in newVars)
		{
			var value = newVars[key];
			if (containsForeignArrays && typeof val == 'object')
				vars[key] = JSON.parse(JSON.stringify(value));
			else
				vars[key] = value;
		}
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
	 * Evaluates an ActionScript expression using the current path, vars, and libs.
	 * The 'this' context within the script will be the object at the current path.
	 * First parameter is the script to be evaluated by Weave using the object at the current path as the 'this' context.
	 * Second parameter is an optional callback or variable name.
	 * - If given a callback function, the function will be passed the result of
	 *   evaluating the expression, setting the 'this' pointer to this WeavePath object.
	 * - If the second parameter is a variable name, the result will be stored as a variable
	 *   as if it was passed as an object property to WeavePath.vars().  It may then be used
	 *   in future calls to WeavePath.exec() or retrieved with WeavePath.getValue().
	 */
	this.exec = function(script, callback_or_variableName)
	{
		var type = typeof callback_or_variableName;
		var callback = type == 'function' ? callback_or_variableName : null;
		// Passing "" as the variable name avoids the overhead of converting the ActionScript object to a JavaScript object.
		var variableName = type == 'string' ? callback_or_variableName : "";
		var vars = weave.path.vars;
		var result = weave.evaluateExpression(path, script, vars, null, variableName);
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
			if (Array.isArray(items))
				items.forEach(visitorFunction, this);
			else
				for (var key in items) visitorFunction.call(this, items[key], key, items);
		}
		return this;
	};
	
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
		var msg = 'command failed (path: ' + path + ')';
		failMessage(methodName, msg);
	}
	function failObject(methodName, path)
	{
		var msg = 'object does not exist (path: ' + path + ')';
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
