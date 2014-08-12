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

/**
 * The code below assumes it is being executed within a function(){} where the 'weave' variable is defined.
 * @namespace weave
 * @description The Weave instance.
 * @private
 */

//"use strict";

//------------------------------------------------------------
// browser backwards compatibility
if (!Object.keys) {
  Object.keys = (function () {
    'use strict';
    var hasOwnProperty = Object.prototype.hasOwnProperty,
        hasDontEnumBug = !({toString: null}).propertyIsEnumerable('toString'),
        dontEnums = [
          'toString',
          'toLocaleString',
          'valueOf',
          'hasOwnProperty',
          'isPrototypeOf',
          'propertyIsEnumerable',
          'constructor'
        ],
        dontEnumsLength = dontEnums.length;

    return function (obj) {
      if (typeof obj !== 'object' && (typeof obj !== 'function' || obj === null)) {
        throw new TypeError('Object.keys called on non-object');
      }

      var result = [], prop, i;

      for (prop in obj) {
        if (hasOwnProperty.call(obj, prop)) {
          result.push(prop);
        }
      }

      if (hasDontEnumBug) {
        for (i = 0; i < dontEnumsLength; i++) {
          if (hasOwnProperty.call(obj, dontEnums[i])) {
            result.push(dontEnums[i]);
          }
        }
      }
      return result;
    };
  }());
}
if(!Array.isArray) {
  Array.isArray = function(arg) {
    return Object.prototype.toString.call(arg) === '[object Array]';
  };
}
if (!Function.prototype.bind) {
  Function.prototype.bind = function (oThis) {
    if (typeof this !== "function") {
      // closest thing possible to the ECMAScript 5
      // internal IsCallable function
      throw new TypeError("Function.prototype.bind - what is trying to be bound is not callable");
    }

    var aArgs = Array.prototype.slice.call(arguments, 1), 
        fToBind = this, 
        fNOP = function () {},
        fBound = function () {
          return fToBind.apply(this instanceof fNOP && oThis
                 ? this
                 : oThis,
                 aArgs.concat(Array.prototype.slice.call(arguments)));
        };

    fNOP.prototype = this.prototype;
    fBound.prototype = new fNOP();

    return fBound;
  };
}
//------------------------------------------------------------

var asFunction_lookup = {};
/**
 * Provides backwards compatibility for callbacks given as strings.
 * Also sets callback['this'] = thisArg, if provided, which is used by Weave when calling the function.
 */
function asFunction(callback, thisArg)
{
	if (typeof callback === 'string')
		callback = asFunction_lookup[callback] || (asFunction_lookup[callback] = function(){ return window.eval('(' + callback + ')()'); });
	if (thisArg !== undefined)
		callback['this'] = thisArg;
	return callback;
}
var _addCallback = weave.addCallback;
weave.addCallback = function(target, callback, triggerNow, immediateMode)
{
	callback = asFunction(callback, Array.isArray(target) ? weave.path(target) : weave.path());
	return _addCallback.call(this, target, callback, triggerNow, immediateMode);
};
var _removeCallback = weave.removeCallback;
weave.removeCallback = function(target, callback, everywhere)
{
	return _removeCallback.call(this, target, asFunction(callback), everywhere);
};
var _loadFile = weave.loadFile;
weave.loadFile = function(url, callback, noCacheHack)
{
	return _loadFile.call(this, url, asFunction(callback), noCacheHack);
};

/**
 * Creates a WeavePath object.  WeavePath objects are immutable after they are created.
 * This is a shortcut for "new weave.WeavePath(basePath)".
 * @param basePath An optional Array (or multiple parameters) specifying the path to an object in the session state.
 *                 A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @return A WeavePath object.
 */
weave.path = function(/*...basePath*/)
{
	var basePath = Array.isArray(arguments[0]) ? arguments[0] : Array.prototype.slice.call(arguments);
	return new weave.WeavePath(basePath);
};

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * WeavePath constructor.  WeavePath objects are immutable after they are created.
 * @class WeavePath
 * @param basePath An optional Array (or multiple parameters) specifying the path to an object in the session state.
 *                 A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @return A WeavePath object.
 */
weave.WeavePath = function(/*...basePath*/)
{
	// "private" instance variables
	this._path = this._A(arguments, 1);
	this._parent = null; // parent WeavePath returned by pop()
};



// "private" shared properties

/**
 * Stores JavaScript variables common to all WeavePath objects.
 * Used by vars(), exec(), and getValue()
 * @private
 */
weave.WeavePath.prototype._vars = {};

/**
 * Remembers which JavaScript variables should be unset after the next call to exec() or getValue().
 * @private
 */
weave.WeavePath.prototype._tempVars = {};

/**
 * Cleans up temporary variables.
 * @private
 */
weave.WeavePath.prototype._deleteTempVars = function()
{
	var vars = weave.WeavePath.prototype._vars;
	var tempVars = weave.WeavePath.prototype._tempVars;
	for (var key in tempVars)
		if (tempVars[key])
			delete vars[key];
	weave.WeavePath.prototype._tempVars = {};
};

/**
 * Private function for internal use.
 * 
 * Converts an arguments object to an Array, and then reconstructs the Array using JSON if natualize() was previously called.
 * @param args An arguments object.
 * @param option An integer flag for special behavior.
 *   - If set to 1, it handles arguments like (...LIST) where LIST can be either an Array or multiple arguments.
 *   - If set to 2, it handles arguments like (...LIST, REQUIRED_PARAM) where LIST can be either an Array or multiple arguments.
 * @private
 */
weave.WeavePath.prototype._A = function(args, option)
{
	if (args.length == option && Array.isArray(args[0]))
		return [].concat(args[0], Array.prototype.slice.call(args, 1));
	return Array.prototype.slice.call(args);
};



// public shared properties

/**
 * A pointer to the Weave instance.
 */
weave.WeavePath.prototype.weave = weave;



// public chainable methods

/**
 * Creates a new WeavePath relative to the current one.
 * @param relativePath An Array (or multiple parameters) specifying successive child names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @return A new WeavePath object which remembers the current WeavePath as its parent.
 */
weave.WeavePath.prototype.push = function(/*...relativePath*/)
{
	var args = this._A(arguments, 1);
	var newWeavePath = new weave.WeavePath(this._path.concat(args));
	newWeavePath._parent = this;
	return newWeavePath;
};

/**
 * Returns to the previous WeavePath that spawned the current one with push().
 * @return The parent WeavePath object.
 */
weave.WeavePath.prototype.pop = function()
{
	if (this._parent)
		return this._parent;
	else
		this._failMessage('pop', 'stack is empty');
	return null;
};

/**
 * Requests that an object be created if it doesn't already exist at the current path (or relative path, if specified).
 * This function can also be used to assert that the object at the current path is of the type you expect it to be.
 * @param relativePath An optional Array (or multiple parameters) specifying child names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @param objectType The name of an ActionScript class in Weave.
 * @return The current WeavePath object.
 */
weave.WeavePath.prototype.request = function(/*...relativePath, objectType*/)
{
	var args = this._A(arguments, 2);
	if (this._assertParams('request', args))
	{
		var type = args.pop();
		var pathcopy = this._path.concat(args);
		this.weave.requestObject(pathcopy, type)
			|| this._failPath('request', pathcopy);
	}
	return this;
};

/**
 * Removes a dynamically created object.
 * @param relativePath An optional Array (or multiple parameters) specifying child names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @return The current WeavePath object.
 */
weave.WeavePath.prototype.remove = function(/*...relativePath*/)
{
	var pathcopy = this._path.concat(this._A(arguments, 1));
	weave.removeObject(pathcopy)
		|| this._failPath('remove', pathcopy);
	return this;
};

/**
 * Reorders the children of an ILinkableHashMap at the current path.
 * @param orderedNames An Array (or multiple parameters) specifying ordered child names.
 * @return The current WeavePath object.
 */
weave.WeavePath.prototype.reorder = function(/*...orderedNames*/)
{
	var args = this._A(arguments, 1);
	if (this._assertParams('reorder', args))
	{
		this.weave.setChildNameOrder(this._path, args)
			|| this._failMessage('reorder', 'path does not refer to an ILinkableHashMap: ' + this._path);
	}
	return this;
};

/**
 * Sets the session state of the object at the current path or relative to the current path.
 * Any existing dynamically created objects that do not appear in the new state will be removed.
 * @param relativePath An optional Array (or multiple parameters) specifying child names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @param state The session state to apply.
 * @return The current WeavePath object.
 */
weave.WeavePath.prototype.state = function(/*...relativePath, state*/)
{
	var args = this._A(arguments, 2);
	if (this._assertParams('state', args))
	{
		var state = args.pop();
		var pathcopy = this._path.concat(args);
		this.weave.setSessionState(pathcopy, state, true)
			|| this._failObject('state', pathcopy);
	}
	return this;
};

/**
 * Applies a session state diff to the object at the current path or relative to the current path.
 * Existing dynamically created objects that do not appear in the new state will remain unchanged.
 * @param relativePath An optional Array (or multiple parameters) specifying child names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @param diff The session state diff to apply.
 * @return The current WeavePath object.
 */
weave.WeavePath.prototype.diff = function(/*...relativePath, diff*/)
{
	var args = this._A(arguments, 2);
	if (this._assertParams('diff', args))
	{
		var diff = args.pop();
		var pathcopy = this._path.concat(args);
		this.weave.setSessionState(pathcopy, diff, false)
			|| this._failObject('diff', pathcopy);
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
 * @return The current WeavePath object.
 */
weave.WeavePath.prototype.addCallback = function(callback, triggerCallbackNow, immediateMode)
{
	if (this._assertParams('addCallback', arguments))
	{
		this.weave.addCallback(this._path, callback, triggerCallbackNow, immediateMode)
			|| this._failObject('addCallback', this._path);
	}
	return this;
};

/**
 * Removes a callback from the object at the current path or from everywhere.
 * @param callback The callback function.
 * @param everywhere Optional paramter, if set to true will remove the callback from every object to which it was added.
 * @return The current WeavePath object.
 */
weave.WeavePath.prototype.removeCallback = function(callback, everywhere)
{
	if (this._assertParams('removeCallback', arguments))
	{
		this.weave.removeCallback(this._path, callback, everywhere)
			|| this._failObject('removeCallback', this._path);
	}
	return this;
};

/**
 * Specifies additional variables to be used in subsequent calls to exec() and getValue().
 * The variables will be made globally available for any WeavePath object created from the same Weave instance.
 * @param newVars An object mapping variable names to values.
 * @param temporary Optional parameter. If set to true, these variables will be unset after the next call to exec() or getValue()
 *                  no matter how either function is called, including from inside custom WeavePath functions.
 * @return The current WeavePath object.
 */
weave.WeavePath.prototype.vars = function(newVars, temporary)
{
	for (var key in newVars)
	{
		this._tempVars[key] = !!temporary;
		this._vars[key] = newVars[key];
	}
	return this;
};

/**
 * Specifies additional libraries to be included in subsequent calls to exec() and getValue().
 * @param libraries An Array (or multiple parameters) specifying ActionScript class names to include as libraries.
 * @return The current WeavePath object.
 */
weave.WeavePath.prototype.libs = function(/*...libraries*/)
{
	var args = this._A(arguments, 1);
	if (this._assertParams('libs', args))
	{
		// include libraries for future evaluations
		this.weave.evaluateExpression(null, null, null, args);
	}
	return this;
};

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
weave.WeavePath.prototype.exec = function(script, callback_or_variableName)
{
	var type = typeof callback_or_variableName;
	var callback = type == 'function' ? callback_or_variableName : null;
	// Passing "" as the variable name avoids the overhead of converting the ActionScript object to a JavaScript object.
	var variableName = type == 'string' ? callback_or_variableName : "";
	var result = this.weave.evaluateExpression(this._path, script, this._vars, null, variableName);
	this._deleteTempVars();
	// if an AS var was saved, delete the corresponding JS var if present to avoid overriding it in future expressions
	if (variableName)
		delete this._vars[variableName];
	if (callback)
		callback.apply(this, [result]);
	
	return this;
};

/**
 * Calls a function using the current WeavePath object as the 'this' value.
 * @param func The function to call.
 * @param args An optional list of arguments to pass to the function.
 * @return The current WeavePath object.
 */
weave.WeavePath.prototype.call = function(func/*[, ...args]*/)
{
	if (this._assertParams('call', arguments))
	{
		var a = this._A(arguments);
		a.shift().apply(this, a);
	}
	return this;
};

/**
 * Applies a function to each item in an Array or an Object.
 * @param items Either an Array or an Object to iterate over.
 * @param visitorFunction A function to be called for each item in items. The function will be called using the current
 *                        WeavePath object as the 'this' value and will receive three parameters:  item, key, items.
 *                        If items is an Array, the key will be an integer. If items is an Object, the key will be a String.
 * @return The current WeavePath object.
 */
weave.WeavePath.prototype.forEach = function(items, visitorFunction)
{
	if (this._assertParams('forEach', arguments, 2))
	{
		if (Array.isArray(items) && Array.prototype.forEach)
			items.forEach(visitorFunction, this);
		else
			for (var key in items) visitorFunction.call(this, items[key], key, items);
	}
	return this;
};

/**
 * Calls weaveTrace() in Weave to print to the log window.
 * @param args A list of parameters to pass to weaveTrace().
 * @return The current WeavePath object.
 */
weave.WeavePath.prototype.trace = function(/* ...args */)
{
	var args = this._A(arguments);
	this.weave.evaluateExpression(this._path, "weaveTrace.apply(null, args)", {"args": args}, null, "");
	return this;
};


// non-chainable methods

/**
 * Returns a copy of the current path Array or the path Array of a descendant object.
 * @param relativePath An optional Array (or multiple parameters) specifying child names to be appended to the result.
 * @return An Array of successive child names used to identify an object in a Weave session state.
 */
weave.WeavePath.prototype.getPath = function(/*...relativePath*/)
{
	return this._path.concat(this._A(arguments, 1));
};

/**
 * Gets an Array of child names under the object at the current path or relative to the current path.
 * @param relativePath An optional Array (or multiple parameters) specifying child names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @return An Array of child names.
 */
weave.WeavePath.prototype.getNames = function(/*...relativePath*/)
{
	return this.weave.getChildNames(this._path.concat(this._A(arguments, 1)));
};

/**
 * Gets the type (qualified class name) of the object at the current path or relative to the current path.
 * @param relativePath An optional Array (or multiple parameters) specifying child names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @return The qualified class name of the object at the current or descendant path, or null if there is no object.
 */
weave.WeavePath.prototype.getType = function(/*...relativePath*/)
{
	return this.weave.getObjectType(this._path.concat(this._A(arguments, 1)));
};

/**
 * Gets the session state of an object at the current path or relative to the current path.
 * @param relativePath An optional Array (or multiple parameters) specifying child names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @return The session state of the object at the current or descendant path.
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
 * @return A session state diff.
 */
weave.WeavePath.prototype.getDiff = function(/*...relativePath, previousState*/)
{
	var args = this._A(arguments, 2);
	if (this._assertParams('getDiff', args))
	{
		var previousState = args.pop();
		var pathcopy = this._path.concat(args);
		var script = "return WeaveAPI.SessionManager.computeDiff(previousState, WeaveAPI.SessionManager.getSessionState(this));";
		return this.weave.evaluateExpression(pathcopy, script, {"previousState": previousState});
	}
	return null;
};

/**
 * Gets the changes that would have to occur to get to another state for the object at the current path or relative to the current path.
 * @param relativePath An optional Array (or multiple parameters) specifying child names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @param otherState The other state for comparison.
 * @return A session state diff.
 */
weave.WeavePath.prototype.getReverseDiff = function(/*...relativePath, otherState*/)
{
	var args = this._A(arguments, 2);
	if (this._assertParams('getReverseDiff', args))
	{
		var otherState = args.pop();
		var pathcopy = this._path.concat(args);
		var script = "return WeaveAPI.SessionManager.computeDiff(WeaveAPI.SessionManager.getSessionState(this), otherState);";
		return this.weave.evaluateExpression(pathcopy, script, {"otherState": otherState});
	}
	return null;
};

/**
 * Returns the value of an ActionScript expression or variable using the current path, vars, and libs.
 * The 'this' context within the script will be set to the object at the current path.
 * @param script_or_variableName The script to be evaluated by Weave, or simply a variable name.
 * @return The result of evaluating the script or variable.
 */
weave.WeavePath.prototype.getValue = function(script_or_variableName)
{
	var result = this.weave.evaluateExpression(this._path, script_or_variableName, this._vars);
	this._deleteTempVars();
	return result;
};

/**
 * Provides a human-readable string containing the path.
 */
weave.WeavePath.prototype.toString = function()
{
	var pathStr = JSON && JSON.stringify ? JSON.stringify(this._path) : this._path.toString();
	return "WeavePath(" + pathStr + ")";
};

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// helper functions
weave.WeavePath.prototype._assertParams = function(methodName, args, minLength)
{
	if (!minLength)
		minLength = 1;
	if (args.length < minLength)
	{
		var msg = 'requires at least ' + ((minLength == 1) ? 'one parameter' : (minLength + ' parameters'));
		this._failMessage(methodName, msg);
		return false;
	}
	return true;
};

weave.WeavePath.prototype._failPath = function(methodName, path)
{
	var pathStr = JSON && JSON.stringify ? JSON.stringify(path) : path;
	var msg = 'command failed (path: ' + pathStr + ')';
	this._failMessage(methodName, msg);
};

weave.WeavePath.prototype._failObject = function(methodName, path)
{
	var pathStr = JSON && JSON.stringify ? JSON.stringify(path) : path;
	var msg = 'object does not exist (path: ' + pathStr + ')';
	this._failMessage(methodName, msg);
};

weave.WeavePath.prototype._failMessage = function(methodName, message)
{
	var str = 'WeavePath.' + methodName + '(): ' + message;
	
	//TODO - mode where error is logged instead of thrown?
	//console.error(str);
	
	throw new Error(str);
};
