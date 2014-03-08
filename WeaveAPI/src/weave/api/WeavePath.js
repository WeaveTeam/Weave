/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of the Weave API.
 *
 * The Initial Developer of the Weave API is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2012
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Note: This code assumes it is being executed within a function(){} where the 'weave' variable is defined.
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

// browser backwards compatibility
if (!Array.isArray)
	Array.isArray = function(o) { return Object.prototype.toString.call(o) === '[object Array]'; }

// enhance weave.addCallback() to support function pointers
var _addCallback = weave.addCallback;
weave.addCallback = function(target, callback, triggerNow, immediateMode)
{
	if (typeof callback == 'function')
		callback = this.callbackToString(callback, Array.isArray(target) ? weave.path(target) : weave.path());
	return _addCallback.call(this, target, callback, triggerNow, immediateMode);
};
// enhance weave.removeCallback() to support function pointers
var _removeCallback = weave.removeCallback;
weave.removeCallback = function(target, callback, everywhere)
{
	if (typeof callback == 'function')
		callback = this.callbackToString(callback); // don't update 'this' context when removing callback
	return _removeCallback.call(this, target, callback, everywhere);
};
// enhance weave.loadFile() to support function pointers
var _loadFile = weave.loadFile;
weave.loadFile = function(url, callback, noCacheHack)
{
	if (typeof callback == 'function')
		callback = this.callbackToString(callback);
	return _loadFile.call(this, url, callback, noCacheHack);
};

/**
 * For internal use with weave.addCallback() and weave.removeCallback().
 * @param callback The callback function.
 * @param thisObj The 'this' context to use for the callback function.
 * @return A String containing a script for a function that invokes the callback.
 */
weave.callbackToString = function(callback, thisObj)
{
	// callback entries must be stored in a public place so they can be accessed by Weave
	var list = this.callbackToString.list;
	if (!list)
		list = this.callbackToString.list = [];
	
	// try to find the callback in the list
	for (var i in list)
	{
		if (list[i]['callback'] == callback)
		{
			// update thisObj if specified
			if (thisObj)
				list[i]['this'] = thisObj;
			// this callback has already been listed
			return list[i]['string'];
		}
	}
	
	// if this has no id, create one that is not already in use
	if (!this.id)
	{
		var id = 'weave';
		while (document.getElementById(id))
			id += '_';
		this.id = id;
	}
	
	// build a script for a function that invokes the callback
	var idStr = JSON && JSON.stringify ? JSON.stringify(this.id) : '"' + this.id + '"';
	var string = 'function(){' +
			'var weave = document.getElementById('+idStr+');' +
			'var obj = weave.callbackToString.list['+list.length+'];' +
			'obj["callback"].apply(obj["this"]);' +
		'}';
	list.push({
		"callback": callback,
		"string": string,
		"this": thisObj
	});
	return string;
}

/**
 * Creates a WeavePath object.  This is a shortcut for "new weave.WeavePath(basePath)".
 * @param basePath An optional Array (or multiple parameters) specifying the base path, which cannot be removed with pop().
 *                 A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 */
weave.path = function(/*...basePath*/)
{
	var basePath = arguments[0];
	if (!Array.isArray(basePath))
	{
		basePath = [];
		for (var i in arguments)
			basePath[i] = arguments[i];
	}
	return new weave.WeavePath(basePath);
};

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * WeavePath constructor.
 * @param basePath An optional Array (or multiple parameters) specifying the base path, which cannot be removed with pop().
 *                 A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 */
weave.WeavePath = function(/*...basePath*/)
{
	// private variables
	this._path = this._A(arguments, 1);
	this._stack = []; // stack of argument counts from push() calls, used with pop()
	this._reconstructArgs = false; // if true, JSON.parse(JSON.stringify(...)) will be used on all Object parameters
}

weave.WeavePath.prototype._vars = {}; // used with exec() and getVar()

/**
 * Private function for internal use.
 * 
 * Converts an arguments object to an Array, and then reconstructs the Array using JSON if natualize() was previously called.
 * The first parameter is an arguments object.
 * The second parameter is an integer flag for special behavior.
 *   - If set to 1, it handles arguments like (...LIST) where LIST can be either an Array or multiple arguments.
 *   - If set to 2, it handles arguments like (...LIST, REQUIRED_PARAM) where LIST can be either an Array or multiple arguments.
 */
weave.WeavePath.prototype._A = function(args, option)
{
	var array;
	var value;
	var n = args.length;
	if (n && n == option && args[0] && Array.isArray(args[0]))
	{
		array = [].concat(args[0]);
		for (var i = 1; i < n; i++)
		{
			value = args[i];
			if (this._reconstructArgs && typeof value == 'object')
				array.push(JSON.parse(JSON.stringify(value)));
			else
				array.push(value);
		}
	}
	else // just convert Arguments to Array
	{
		array = [];
		while (n--)
		{
			value = args[n];
			if (this._reconstructArgs && typeof value == 'object')
				array[n] = JSON.parse(JSON.stringify(value));
			else
				array[n] = value;
		}
	}
	return array;
}

// public variables

/**
* A pointer to the Weave instance.
*/
weave.WeavePath.prototype.weave = weave;



// public chainable methods

/**
 * Modifies the current path by appending successive child names which specify a relative path.
 * @param relativePath An Array (or multiple parameters) specifying child names to append to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 */
weave.WeavePath.prototype.push = function(/*...relativePath*/)
{
	var args = this._A(arguments, 1);
	if (assertParams('push', args))
	{
		// append names to path
		for (var i = 0; i < args.length; i++)
			this._path.push(args[i]);
		// remember the number of names we appended
		this._stack.push(args.length);
	}
	return this;
};
/**
 * Restores the current path to what it was before the last call to push() that was not followed by a pop().
 */
weave.WeavePath.prototype.pop = function()
{
	if (this._stack.length)
		this._path.length -= this._stack.pop();
	else
		failMessage('pop', 'stack is empty');
	return this;
};
/**
 * Requests that an object be created if it doesn't already exist at the current path (or relative path, if specified).
 * @param relativePath An optional Array (or multiple parameters) specifying child names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @param objectType The name of an ActionScript class in Weave.
 */
weave.WeavePath.prototype.request = function(/*...relativePath, objectType*/)
{
	var args = this._A(arguments, 2);
	if (assertParams('request', args))
	{
		var type = args.pop();
		var pathcopy = this._path.concat(args);
		this.weave.requestObject(pathcopy, type)
			|| failPath('request', pathcopy);
	}
	return this;
};
/**
 * Removes a dynamically created object.
 * @param relativePath An optional Array (or multiple parameters) specifying child names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 */
weave.WeavePath.prototype.remove = function(/*...relativePath*/)
{
	var pathcopy = this._path.concat(this._A(arguments, 1));
	weave.removeObject(pathcopy)
		|| failPath('remove', pathcopy);
	return this;
};
/**
 * Reorders the children of an ILinkableHashMap at the current path.
 * @param orderedNames An Array (or multiple parameters) specifying ordered child names.
 */
weave.WeavePath.prototype.reorder = function(/*...orderedNames*/)
{
	var args = this._A(arguments, 1);
	if (assertParams('reorder', args))
	{
		this.weave.setChildNameOrder(this._path, args)
			|| failMessage('reorder', 'path does not refer to an ILinkableHashMap: ' + this._path);
	}
	return this;
};
/**
 * Sets the session state of the object at the current path or relative to the current path.
 * Any existing dynamically created objects that do not appear in the new state will be removed.
 * @param relativePath An optional Array (or multiple parameters) specifying child names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @param state The session state to apply.
 */
weave.WeavePath.prototype.state = function(/*...relativePath, state*/)
{
	var args = this._A(arguments, 2);
	if (assertParams('state', args))
	{
		var state = args.pop();
		var pathcopy = this._path.concat(args);
		this.weave.setSessionState(pathcopy, state, true)
			|| failObject('state', pathcopy);
	}
	return this;
};
/**
 * Applies a session state diff to the object at the current path or relative to the current path.
 * Existing dynamically created objects that do not appear in the new state will remain unchanged.
 * @param relativePath An optional Array (or multiple parameters) specifying child names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @param diff The session state diff to apply.
 */
weave.WeavePath.prototype.diff = function(/*...relativePath, diff*/)
{
	var args = this._A(arguments, 2);
	if (assertParams('diff', args))
	{
		var diff = args.pop();
		var pathcopy = this._path.concat(args);
		this.weave.setSessionState(pathcopy, diff, false)
			|| failObject('diff', pathcopy);
	}
	return this;
};
/**
 * Adds a callback to the object at the current path.
 * When the callback is called, a WeavePath object initialized at the current path will be used as the 'this' context.
 * If the same callback is added to multiple paths, only the last path will be used as the 'this' context.
 * @param callback The callback function.
 * @param triggerCallbackNow Optional parameter, when set to true will trigger the callback now.
 * @param immediateMode Optional parameter, when set to true will use an immediate callback instead of a grouped callback.
 */
weave.WeavePath.prototype.addCallback = function(callback, triggerCallbackNow, immediateMode)
{
	if (assertParams('addCallback', arguments))
	{
		callback = this.weave.callbackToString(callback, new this.constructor(this._path));
		this.weave.addCallback(this._path, callback, triggerCallbackNow, immediateMode)
			|| failObject('addCallback', this._path);
	}
	return this;
};
/**
 * Removes a callback from the object at the current path or from everywhere.
 * @param callback The callback function.
 * @param everywhere Optional paramter, if set to true will remove the callback from every object to which it was added.
 */
weave.WeavePath.prototype.removeCallback = function(callback, everywhere)
{
	if (assertParams('removeCallback', arguments))
	{
		this.weave.removeCallback(this._path, callback, everywhere)
			|| failObject('removeCallback', this._path);
	}
	return this;
};
/**
 * Specifies additional variables to be used in subsequent calls to exec() and getValue().
 * The variables will be made globally available for any WeavePath object created from the same Weave instance.
 * @param newVars An object mapping variable names to values.
 */
weave.WeavePath.prototype.vars = function(newVars)
{
	for (var key in newVars)
	{
		var value = newVars[key];
		if (this._reconstructArgs && typeof value == 'object')
			this._vars[key] = JSON.parse(JSON.stringify(value));
		else
			this._vars[key] = value;
	}
	return this;
};
/**
 * Specifies additional libraries to be included in subsequent calls to exec() and getValue().
 * @param libraries An Array (or multiple parameters) specifying ActionScript class names to include as libraries.
 */
weave.WeavePath.prototype.libs = function(/*...libraries*/)
{
	var args = this._A(arguments, 1);
	if (assertParams('libs', args))
	{
		// include libraries for future evaluations
		this.weave.evaluateExpression(null, null, null, args);
	}
	return this;
};
/**
 * Evaluates an ActionScript expression using the current path, vars, and libs.
 * The 'this' context within the script will be the object at the current path.
 * @param script The script to be evaluated by Weave using the object at the current path as the 'this' context.
 * @param callback_or_variableName Optional callback function or variable name.
 * - If given a callback function, the function will be passed the result of
 *   evaluating the expression, setting the 'this' pointer to this WeavePath object.
 * - If given a variable name, the result will be stored as a variable
 *   as if it was passed as an object property to WeavePath.vars().  It may then be used
 *   in future calls to WeavePath.exec() or retrieved with WeavePath.getValue().
 */
weave.WeavePath.prototype.exec = function(script, callback_or_variableName)
{
	var type = typeof callback_or_variableName;
	var callback = type == 'function' ? callback_or_variableName : null;
	// Passing "" as the variable name avoids the overhead of converting the ActionScript object to a JavaScript object.
	var variableName = type == 'string' ? callback_or_variableName : "";
	var result = weave.evaluateExpression(this._path, script, this._vars, null, variableName);
	// if an AS var was saved, delete the corresponding JS var if present to avoid overriding it in future expressions
	if (variableName)
		delete this._vars[variableName];
	if (callback)
		callback.apply(this, [result]);
	
	return this;
};
/**
 * Applies a function with optional parameters, setting 'this' pointer to the WeavePath object
 * @param func The function to call.
 * @param args An optional list of arguments to pass to the function.
 */
weave.WeavePath.prototype.call = function(func/*[, ...args]*/)
{
	if (assertParams('call', arguments))
	{
		var a = this._A(arguments);
		a.shift().apply(this, a);
	}
	return this;
};
/**
 * Applies a function to each item in an Array or an Object.
 * @param items Either an Array or an Object to iterate over.
 *              If items is an Array, this has the same effect as WeavePath.call(function(){ itemsArray.forEach(visitorFunction, this); }).
 *              If items is an Object, it will behave like WeavePath.call(function(){ for(var key in items) visitorFunction.call(this, items[key], key, items); }).
 * @param visitorFunction A function to be called for each item. The function will receive three parameters:  item, key, items.
 */
weave.WeavePath.prototype.forEach = function(items, visitorFunction)
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

/**
 * Enables automatic conversion of foreign Arrays from windows other than the one Weave is in.
 * Only the WeavePath object you are currently working with will be affected by this call.
 * Note that if you use this mode, any occurrences of NaN and Infinity will be converted to null
 * because this mode uses JSON.parse(JSON.stringify(...)) and those values are not supported by JSON.
 */
weave.WeavePath.prototype.naturalize = function()
{
	this._reconstructArgs = true;
	return this;
}



// non-chainable methods

/**
 * Returns a copy of the current path Array.
 * @param relativePath An optional Array (or multiple parameters) specifying child names to be appended to the result.
 */
weave.WeavePath.prototype.getPath = function(/*...relativePath*/)
{
	return this._path.concat(this._A(arguments, 1));
};
/**
 * Gets an Array of child names under the object at the current path or relative to the current path.
 * @param relativePath An optional Array (or multiple parameters) specifying child names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 */
weave.WeavePath.prototype.getNames = function(/*...relativePath*/)
{
	return this.weave.getChildNames(this._path.concat(this._A(arguments, 1)));
};
/**
 * Gets the type (qualified class name) of the object at the current path or relative to the current path.
 * @param relativePath An optional Array (or multiple parameters) specifying child names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 */
weave.WeavePath.prototype.getType = function(/*...relativePath*/)
{
	return this.weave.getObjectType(this._path.concat(this._A(arguments, 1)));
};
/**
 * Gets the session state of an object at the current path or relative to the current path.
 * @param relativePath An optional Array (or multiple parameters) specifying child names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 */
weave.WeavePath.prototype.getState = function(/*...relativePath*/)
{
	return this.weave.getSessionState(this._path.concat(this._A(arguments, 1)));
};
/**
 * Gets the changes that have occurred since previousState for the object at the current path or relative to the current path.
 * @param relativePath An optional Array (or multiple parameters) specifying child names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @param previousState The previous state for comparison.
 */
weave.WeavePath.prototype.getDiff = function(/*...relativePath, previousState*/)
{
	var args = this._A(arguments, 2);
	if (assertParams('getDiff', args))
	{
		var otherState = args.pop();
		var pathcopy = this._path.concat(args);
		var script = "import 'weave.api.WeaveAPI';"
			+ "import 'weave.api.core.ILinkableObject';"
			+ "return WeaveAPI.SessionManager.computeDiff(otherState, this is ILinkableObject ? WeaveAPI.SessionManager.getSessionState(this) : null);";
		return this.weave.evaluateExpression(pathcopy, script, {"otherState": otherState});
	}
	return null;
}
/**
 * Gets the changes that would have to occur to get to another state for the object at the current path or relative to the current path.
 * @param relativePath An optional Array (or multiple parameters) specifying child names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @param otherState The other state for comparison.
 */
weave.WeavePath.prototype.getReverseDiff = function(/*...relativePath, otherState*/)
{
	var args = this._A(arguments, 2);
	if (assertParams('getReverseDiff', args))
	{
		var otherState = args.pop();
		var pathcopy = this._path.concat(args);
		var script = "import 'weave.api.WeaveAPI';"
			+ "import 'weave.api.core.ILinkableObject';"
			+ "return WeaveAPI.SessionManager.computeDiff(this is ILinkableObject ? WeaveAPI.SessionManager.getSessionState(this) : null, otherState);";
		return this.weave.evaluateExpression(pathcopy, script, {"otherState": otherState});
	}
	return null;
}
/**
 * Returns the value of an ActionScript expression or variable using the current path, vars, and libs.
 * The 'this' context within the script will be set to the object at the current path.
 * @param script_or_variableName The script to be evaluated by Weave, or simply a variable name.
 */
weave.WeavePath.prototype.getValue = function(script_or_variableName)
{
	return this.weave.evaluateExpression(this._path, script_or_variableName, this._vars);
};

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// helper functions
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
	
	//TODO - mode where error is logged instead of thrown?
	//console.log(str);
	
	throw new Error(str);
}
