/**
 * @fileoverview Externs for Weave JavaScript API
 *
 * @see http://info.oicweave.org/projects/weave/wiki/JavaScript_API
 * @externs
 */

/**
 * @typedef {Array.<string>}
 */
var WeavePathArray;

/**
 * @private
 * @constructor
 * @return {!Weave}
 */
function Weave() {}

/**
 * This function will add a grouped callback to an ILinkableObject.
 * @param {WeavePathArray|string} objectPathOrExpressionName
 * @param {string} callback
 * @param {boolean=} triggerCallbackNow
 * @return {boolean}
 */
Weave.prototype.addCallback = function(objectPathOrExpressionName, callback, triggerCallbackNow){};

/**
 * This function will evaluate an expression using the compiler.
 * @param {WeavePathArray|string} scopeObjectPathOrExpressionName
 * @param {string} expression
 * @param {Object.<string,*>=} variables
 * @param {Array.<string>=} libraries
 * @param {string=} assignExpressionName
 * @return {*}
 */
Weave.prototype.evaluateExpression = function(scopeObjectPathOrExpressionName, expression, variables, libraries, assignExpressionName){};

/**
 * This function gets a list of names of children of an object appearing in the session state.
 * @param {WeavePathArray} objectPath
 * @return {Array.<String>}
 */
Weave.prototype.getChildNames = function(objectPath){};

/**
 * This function will get the qualified class name of an object appearing in the session state.
 * @param {WeavePathArray} objectPath
 * @return {string}
 */
Weave.prototype.getObjectType = function(objectPath){};

/**
 * This function gets the current session state of a linkable object.
 * @param {WeavePathArray} objectPath
 * @return {*}
 */
Weave.prototype.getSessionState = function(objectPath){};

/**
 * This function will remove a callback that was previously added.
 * @param {WeavePathArray|string} objectPathOrExpressionName
 * @param {string} callback
 * @return {boolean}
 */
Weave.prototype.removeCallback = function(objectPathOrExpressionName, callback){};

/**
 * This function will remove a dynamically created object if it is the child of an ILinkableCompositeObject.
 * @param {WeavePathArray} objectPath
 * @return {boolean}
 */
Weave.prototype.removeObject = function(objectPath){};

/**
 * This function will dynamically create an object at the specified location in the session state if its parent implements ILinkableCompositeObject.
 * @param {WeavePathArray} objectPath
 * @param {string} objectType
 * @return {boolean}
 */
Weave.prototype.requestObject = function(objectPath, objectType){};

/**
 * This function will reorder children of an object implementing ILinkableHashMap.
 * @param {WeavePathArray} hashMapPath
 * @param {Array.<string>} orderedChildNames
 * @return {boolean}
 */
Weave.prototype.setChildNameOrder = function(hashMapPath, orderedChildNames){};

/**
 * This function updates the current session state of an object.
 * @param {WeavePathArray} objectPath
 * @param {*} newState
 * @param {boolean=} removeMissingObjects
 * @return {boolean}
 */
Weave.prototype.setSessionState = function(objectPath, newState, removeMissingObjects){};


/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////


/**
 * Creates a WeavePath object.
 * Accepts an optional Array or list of names to serve as the base path, which cannot be removed with pop().
 * @param {WeavePathArray=} basePath
 * @return {WeavePath}
 */
Weave.prototype.path = function(basePath){};

/**
 * @private
 * @constructor
 * @returns {WeavePath}
 */
function WeavePath(){
	/**
	 * @type {Weave}
	 */
	this.weave;
};

/******** WeavePath chainable methods ********/

/**
 * Specify any number of names to push on to the end of the path.
 * Accepts a list of names relative to the current path.
 * @param {...string|WeavePathArray} relativePath
 * @return {WeavePath}
 */
WeavePath.prototype.push = function(relativePath){};

/**
 * Pops off all names from previous call to push().  No arguments.
 * @return {WeavePath}
 */
WeavePath.prototype.pop = function(){};

/**
 * Requests that an object be created if it doesn't already exist at (or relative to) the current path.
 * The final parameter should be the object type to be passed to weave.requestObject().
 * @param {string} objectType
 * @return {WeavePath}
 */
WeavePath.prototype.request = function(objectType){};

/**
 * Removes a dynamically created object.
 * Accepts an optional list of names relative to the current path.
 * @param {...string|WeavePathArray} relativePath
 * @return {WeavePath}
 */
WeavePath.prototype.remove = function(relativePath){};

/**
 * Calls weave.setChildNameOrder() for the current path.
 * Accepts an Array or a list of ordered child names.
 * @param {...string|Array.<string>} orderedNames
 * @return {WeavePath}
 */
WeavePath.prototype.reorder = function(orderedNames){};

/**
 * Sets the session state of the object at the current path or relative to the current path.
 * Any existing dynamically created objects that do not appear in the new state will be removed.
 * The final parameter should be the session state.
 * @param {*} state
 * @return {WeavePath}
 */
WeavePath.prototype.state = function(state){};

/**
 * Applies a session state diff to the object at the current path or relative to the current path.
 * Existing dynamically created objects that do not appear in the new state will remain unchanged.
 * The final parameter should be the session state diff.
 * @param {*} diff
 * @return {WeavePath}
 */
WeavePath.prototype.diff = function(diff){};

/**
 * Adds a grouped callback to the object at the current path.
 * When the callback is called, a WeavePath object initialized at the current path will be used as the 'this' context.
 * First parameter is the callback function.
 * Second parameter is a Boolean, when set to true will trigger the callback now.
 * Third parameter is a Boolean, when set to true means the callback will receive the session state as a parameter.
 * Since this adds a grouped callback, the callback will not run immediately when addCallback() is called.
 * @param {function(this:WeavePath, ...)} callback
 * @param {boolean=} triggerCallbackNow
 * @param {boolean=} callbackReceivesState
 * @return {WeavePath}
 */
WeavePath.prototype.addCallback = function(callback, triggerCallbackNow, callbackReceivesState){};

/**
 * Removes a callback from the object at the current path.
 * @param {function(this:WeavePath, ...)} callback
 * @return {WeavePath}
 */
WeavePath.prototype.removeCallback = function(callback){};

/**
 * Specifies additional variables to be used in subsequent calls to exec().
 * The variables will be made globally available for any WeavePath object created from the same Weave instance.
 * The first parameter should be an object mapping variable names to values.
 * @param {Object.<string,*>} newVars
 * @return {WeavePath}
 */
WeavePath.prototype.vars = function(newVars){};

/**
 * Specifies additional libraries to be included in subsequent calls to exec().
 * @param {...string|Array.<String>} libraries
 * @return {WeavePath}
 */
WeavePath.prototype.libs = function(libraries){};

/**
 * Calls weave.evaluateExpression() using the current path, vars, and libs.
 * First parameter is the script to be evaluated by Weave at the current path.
 * Second parameter is an optional callback or variable name.
 * - If given a callback function, the function will be passed the result of
 *   evaluating the expression, setting the 'this' pointer to this WeavePath object.
 * - If the second parameter is a variable name, the result will be stored as a variable
 *   as if it was passed as an object property to WeavePath.vars().  It may then be used
 *   in future calls to WeavePath.exec() or retrieved with WeavePath.getValue().
 * @param {string} script
 * @param {(function(this:WeavePath, *)|string)=} callback_or_variableName
 * @return {WeavePath}
 */
WeavePath.prototype.exec = function(script, callback_or_variableName){};

/**
 * Applies a function with optional parameters, setting 'this' pointer to the WeavePath object
 * @param {function(this:WeavePath, ...)} func
 * @param {...} args
 * @return {WeavePath}
 */
WeavePath.prototype.call = function(func, args){};

/**
 * Applies a function to each item in an Array or an Object.
 * If items is an Array, this has the same effect as WeavePath.call(function(){ itemsArray.forEach(visitorFunction, this); }).
 * If items is an Object, it will behave like WeavePath.call(function(){ for(var key in items) visitorFunction.call(this, items[key], key, items); }).
 * @param {Object.<string,*>|Array} items
 * @param {function(this:WeavePath, *=, string=, (Object.<String,*>|Array)=)} visitorFunction
 * @return {WeavePath}
 */
WeavePath.prototype.forEach = function(items, visitorFunction){};

/******** WeavePath non-chainable methods ********/


/**
 * Returns a copy of the current path Array.
 * Accepts an optional list of names to be appended to the result.
 * @param {...string|WeavePathArray} relativePath
 * @return {Array.<string>}
 */
WeavePath.prototype.getPath = function(relativePath){};

/**
 * Gets an Array of child names under the object at the current path or relative to the current path.
 * Accepts an optional list of names relative to the current path.
 * @param {...string|WeavePathArray} relativePath
 * @return {Array.<string>}
 */
WeavePath.prototype.getNames = function(relativePath){};

/**
 * Gets the type (qualified class name) of the object at the current path or relative to the current path.
 * Accepts an optional list of names relative to the current path.
 * @param {...string|WeavePathArray} relativePath
 * @return {string}
 */
WeavePath.prototype.getType = function(relativePath){};

/**
 * Gets the session state of an object at the current path or relative to the current path.
 * Accepts an optional list of names relative to the current path.
 * @param {...string|WeavePathArray} relativePath
 * @return {*}
 */
WeavePath.prototype.getState = function(relativePath){};

/**
 * Gets the changes that have occurred since previousState for the object at the current path or relative to the current path.
 * @param {*} previousState
 * @return {*}
 */
WeavePath.prototype.getDiff = function(previousState){};

/**
 * Gets the changes that would have to occur to get to another state for the object at the current path or relative to the current path.
 * @param {*} otherState
 * @return {*}
 */
WeavePath.prototype.getReverseDiff = function(otherState){};

/**
 * Calls weave.evaluateExpression() using the current path, vars, and libs and returns the resulting value.
 * First parameter is the script to be evaluated by Weave at the current path, or simply a variable name.
 * @param {string} script_or_variableName
 * @return {*}
 */
WeavePath.prototype.getValue = function(script_or_variableName){};
