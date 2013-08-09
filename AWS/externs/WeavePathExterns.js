/**
 * @fileoverview Externs for Weave JavaScript API
 *
 * @see http://info.oicweave.org/projects/weave/wiki/JavaScript_API
 * @externs
 */

/**
 * @typedef {Array.<string>}
 */
var WeaveObjectPath;

/**
 * @constructor
 * @return {!Weave}
 */
function Weave() {}

/**
 * Creates a WeavePath object.
 * Accepts an optional Array or list of names to serve as the base path, which cannot be removed with pop().
 * @param basePath {WeaveObjectPath=}
 * @return {WeavePath}
 */
Weave.prototype.path = function(basePath){};

/**
 * This function will add a grouped callback to an ILinkableObject.
 * @param objectPathOrExpressionName {WeaveObjectPath|string}
 * @param callback {string}
 * @param triggerCallbackNow {boolean=}
 * @return {boolean}
 */
Weave.prototype.addCallback = function(objectPathOrExpressionName, callback, triggerCallbackNow){};

/**
 * This function will evaluate an expression using the compiler.
 * @param scopeObjectPathOrExpressionName {WeaveObjectPath|string}
 * @param expression {string}
 * @param variables {Object.<string,*>=}
 * @param libraries {Array.<string>=}
 * @param assignExpressionName {string=}
 * @return {*}
 */
Weave.prototype.evaluateExpression = function(scopeObjectPathOrExpressionName, expression, variables, libraries, assignExpressionName){};

/**
 * This function gets a list of names of children of an object appearing in the session state.
 * @param objectPath {WeaveObjectPath}
 * @return {Array.<String>}
 */
Weave.prototype.getChildNames = function(objectPath){};

/**
 * This function will get the qualified class name of an object appearing in the session state.
 * @param objectPath {WeaveObjectPath}
 * @return {string}
 */
Weave.prototype.getObjectType = function(objectPath){};

/**
 * This function gets the current session state of a linkable object.
 * @param objectPath {WeaveObjectPath}
 * @return {*}
 */
Weave.prototype.getSessionState = function(objectPath){};

/**
 * This function will remove a callback that was previously added.
 * @param scopeObjectPathOrExpressionName {WeaveObjectPath|string}
 * @param callback {string}
 * @return {boolean}
 */
Weave.prototype.removeCallback = function(objectPathOrExpressionName, callback){};

/**
 * This function will remove a dynamically created object if it is the child of an ILinkableCompositeObject.
 * @param objectPath {WeaveObjectPath}
 * @return {boolean}
 */
Weave.prototype.removeObject = function(objectPath){};

/**
 * This function will dynamically create an object at the specified location in the session state if its parent implements ILinkableCompositeObject.
 * @param objectPath {WeaveObjectPath}
 * @param objectType {string}
 * @return {boolean}
 */
Weave.prototype.requestObject = function(objectPath, objectType){};

/**
 * This function will reorder children of an object implementing ILinkableHashMap.
 * @param hashMapPath {WeaveObjectPath}
 * @param orderedChildNames {Array.<string>}
 * @return {boolean}
 */
Weave.prototype.setChildNameOrder = function(hashMapPath, orderedChildNames){};

/**
 * This function updates the current session state of an object.
 * @param objectPath WeaveObjectPath
 * @param newState {*}
 * @param removeMissingObjects {boolean=}
 * @return {boolean}
 */
Weave.prototype.setSessionState = function(objectPath, newState, removeMissingObjects){};


///******** WeavePath chainable methods ********/
//
///**
// * Specify any number of names to push on to the end of the path.
// * Accepts a list of names relative to the current path.
// */
//function push(...relativePath)
//
///**
// * Pops off all names from previous call to push().  No arguments.
// */
//function pop()
//
///**
// * Requests that an object be created if it doesn't already exist at (or relative to) the current path.
// * Accepts an optional list of names relative to the current path.
// * The final parameter should be the object type to be passed to weave.requestObject().
// */
//function request(...relativePath, objectType)
//
///**
// * Removes a dynamically created object.
// * Accepts an optional list of names relative to the current path.
// */
//function remove(...relativePath)
//
///**
// * Calls weave.setChildNameOrder() for the current path.
// * Accepts an Array or a list of ordered child names.
// */
//function reorder(...orderedNames)
//
///**
// * Sets the session state of the object at the current path or relative to the current path.
// * Any existing dynamically created objects that do not appear in the new state will be removed.
// * Accepts an optional list of names relative to the current path.
// * The final parameter should be the session state.
// */
//function state(...relativePath, state)
//
///**
// * Applies a session state diff to the object at the current path or relative to the current path.
// * Existing dynamically created objects that do not appear in the new state will remain unchanged.
// * Accepts an optional list of names relative to the current path.
// * The final parameter should be the session state diff.
// */
//function diff(...relativePath, diff)
//
///**
// * Adds a grouped callback to the object at the current path.
// * When the callback is called, a WeavePath object initialized at the current path will be used as the 'this' context.
// * First parameter is the callback function.
// * Second parameter is a Boolean, when set to true will trigger the callback now.
// * Third parameter is a Boolean, when set to true means the callback will receive the session state as a parameter.
// * Since this adds a grouped callback, the callback will not run immediately when addCallback() is called.
// */
//function addCallback(callback, triggerCallbackNow, callbackReceivesState)
//
///**
// * Removes a callback from the object at the current path.
// */
//function removeCallback(callback)
//
///**
// * Specifies additional variables to be used in subsequent calls to exec().
// * The variables will be made globally available for any WeavePath object created from the same Weave instance.
// * The first parameter should be an object mapping variable names to values.
// */
//function vars(newVars)
//
///**
// * Specifies additional libraries to be included in subsequent calls to exec().
// */
//function libs(...libraries)
//
///**
// * Calls weave.evaluateExpression() using the current path, vars, and libs.
// * First parameter is the script to be evaluated by Weave at the current path.
// * Second parameter is an optional callback or variable name.
// * - If given a callback function, the function will be passed the result of
// *   evaluating the expression, setting the 'this' pointer to this WeavePath object.
// * - If the second parameter is a variable name, the result will be stored as a variable
// *   as if it was passed as an object property to WeavePath.vars().  It may then be used
// *   in future calls to WeavePath.exec() or retrieved with WeavePath.getValue().
// */
//function exec(script, callback_or_variableName)
//
///**
// * Applies a function with optional parameters, setting 'this' pointer to the WeavePath object
// */
//function call(func, ...args)
//
///**
// * Applies a function to each item in an Array or an Object.
// * If items is an Array, this has the same effect as WeavePath.call(function(){ itemsArray.forEach(visitorFunction, this); }).
// * If items is an Object, it will behave like WeavePath.call(function(){ for(var key in items) visitorFunction.call(this, items[key], key, items); }).
// */
//function forEach(items, visitorFunction)
//
///******** WeavePath properties and non-chainable methods ********/
//
///**
// * A pointer to the Weave instance.
// */
//var weave
//
///**
// * Returns a copy of the current path Array.
// * Accepts an optional list of names to be appended to the result.
// */
//function getPath(...relativePath)
//
///**
// * Gets an Array of child names under the object at the current path or relative to the current path.
// * Accepts an optional list of names relative to the current path.
// */
//function getNames(...relativePath)
//
///**
// * Gets the type (qualified class name) of the object at the current path or relative to the current path.
// * Accepts an optional list of names relative to the current path.
// */
//function getType(...relativePath)
//
///**
// * Gets the session state of an object at the current path or relative to the current path.
// * Accepts an optional list of names relative to the current path.
// */
//function getState(...relativePath)
//
///**
// * Gets the changes that have occurred since previousState for the object at the current path or relative to the current path.
// * Accepts an optional list of names relative to the current path.
// */
//function getDiff(...relativePath, previousState)
//
///**
// * Gets the changes that would have to occur to get to another state for the object at the current path or relative to the current path.
// * Accepts an optional list of names relative to the current path.
// */
//function getReverseDiff(...relativePath, otherState)
//
///**
// * Calls weave.evaluateExpression() using the current path, vars, and libs and returns the resulting value.
// * First parameter is the script to be evaluated by Weave at the current path, or simply a variable name.
// */
//function getValue(script_or_variableName)