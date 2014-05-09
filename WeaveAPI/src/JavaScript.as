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

package
{
	import flash.external.ExternalInterface;
	import flash.utils.getDefinitionByName;

	/**
	 * An alternative to flash.external.ExternalInterface with workarounds for its limitations.
	 * Requires Flash Player 11 or later to get the full benefit (uses native JSON support),
	 * but has backwards compatibility to Flash Player 10, or possibly earlier versions (untested).
	 * 
	 * @author adufilie
	 */
	public class JavaScript
	{
		/**
		 * This is set to true when initialize() has been called.
		 */
		private static var initialized:Boolean = false;
		
		/**
		 * Remembers the objectID returned from getExternalObjectID().
		 */
		private static var _objectID:String;
		
		/**
		 * If this is true, backslashes need to be escaped when returning a String to JavaScript.
		 */
		private static var backslashNeedsEscaping:Boolean = true;
		
		/**
		 * A pointer to JSON.
		 */
		private static var json:Object;
		
		/**
		 * Maps a method name to the corresponding Function.
		 */
		private static const registeredMethods:Object = {};
		
		/**
		 * This is the name of the generic external interface function which uses JSON input and output.
		 */
		private static const JSON_CALL:String = "_jsonCall";
		
		/**
		 * Used as the second parameter to JSON.stringify
		 */
		private static const JSON_REPLACER:String = "_jsonReplacer";
		
		/**
		 * Used as the second parameter to JSON.parse
		 */
		private static const JSON_REVIVER:String = "_jsonReviver";
		
		/**
		 * A random String which is highly unlikely to appear in any String value.
		 */
		private static const JSON_SUFFIX:String = ';' + new Date() + ';' + Math.random();
		
		private static const NOT_A_NUMBER:String = NaN + JSON_SUFFIX;
		private static const UNDEFINED:String = undefined + JSON_SUFFIX;
		private static const INFINITY:String = Infinity + JSON_SUFFIX;
		private static const NEGATIVE_INFINITY:String = -Infinity + JSON_SUFFIX;
	
		private static function initialize():void
		{
			// one-time initialization attempt
			initialized = true;
			var slashes:String = "\\\\";
			backslashNeedsEscaping = (ExternalInterface.call('function(slashes){ return slashes; }', slashes) != slashes);
			try
			{
				json = getDefinitionByName("JSON");
				ExternalInterface.addCallback(JSON_CALL, handleJsonCall);
				exec(
					{
						"JSON_REPLACER": JSON_REPLACER,
						"JSON_REVIVER": JSON_REVIVER,
						"NOT_A_NUMBER": NOT_A_NUMBER,
						"UNDEFINED": UNDEFINED,
						"INFINITY": INFINITY,
						"NEGATIVE_INFINITY": NEGATIVE_INFINITY
					},
					"this[JSON_REPLACER] = function(key, value){",
					"    if (value === undefined)",
					"        return UNDEFINED;",
					"    if (typeof value != 'number' || isFinite(value))",
					"        return value;",
					"    if (value == Infinity)",
					"        return INFINITY;",
					"    if (value == -Infinity)",
					"        return NEGATIVE_INFINITY;",
					"    return NOT_A_NUMBER;",
					"};",
					"this[JSON_REVIVER] = function(key, value){",
					"    if (value === NOT_A_NUMBER)",
					"        return NaN;",
					"    if (value === UNDEFINED)",
					"        return undefined;",
					"    if (value === INFINITY)",
					"        return Infinity;",
					"    if (value === NEGATIVE_INFINITY)",
					"        return -Infinity;",
					"    return value;",
					"};"
				);
			}
			catch (e:Error)
			{
				trace(e.getStackTrace() || "Your version of Flash Player does not have native JSON support.");
			}
		}
		
		private static function _jsonReplacer(key:String, value:*):*
		{
			if (value === undefined)
				return UNDEFINED;
			if (typeof value != 'number' || isFinite(value))
				return value;
			if (value == Infinity)
				return INFINITY;
			if (value == -Infinity)
				return NEGATIVE_INFINITY;
			return NOT_A_NUMBER;
		}
		
		private static function _jsonReviver(key:String, value:*):*
		{
			if (value === NOT_A_NUMBER)
				return NaN;
			if (value === UNDEFINED)
				return undefined;
			if (value === INFINITY)
				return Infinity;
			if (value === NEGATIVE_INFINITY)
				return -Infinity;
			return value;
		}
		
		/**
		 * Handles a JavaScript request.
		 * @param methodName The name of the method to call.
		 * @param paramsJson An Array of parameters to pass to the method, stringified with JSON.
		 * @return The result of calling the method, stringified with JSON.
		 */
		private static function handleJsonCall(methodName:String, paramsJson:String):String
		{
			var method:Function = registeredMethods[methodName] as Function;
			if (method == null)
				throw new Error("No such method: " + methodName);
			
			var params:Array = json.parse(paramsJson, _jsonReviver);
			var result:* = method.apply(null, params);
			var resultJson:String = json.stringify(result, _jsonReplacer);
			
			// work around flash player bug
			if (backslashNeedsEscaping)
				resultJson = resultJson.split('\\').join('\\\\');
	
			return resultJson;
		}
		
		/**
		 * Exposes a method to JavaScript.
		 * @param methodName The name to be used in JavaScript.
		 * @param method The method.
		 * @param requiredParamCount The number of required (non-optional) parameters.
		 */
		public static function registerMethod(methodName:String, method:Function, requiredParamCount:int = -1):void
		{
			// backwards compatibility
			if (!json)
			{
				ExternalInterface.addCallback(methodName, method);
				return;
			}
			
			if (requiredParamCount < 0)
				requiredParamCount = method.length;
			
			exec(
				{
					"JSON_CALL": JSON_CALL,
					"JSON_REPLACER": JSON_REPLACER,
					"JSON_REVIVER": JSON_REVIVER,
					"methodName": methodName,
					"requiredParamCount": requiredParamCount
				},
				"this[methodName] = function(){",
				"    var params = new Array(requiredParamCount);",
				"    for (var i in arguments)",
				"        params[i] = arguments[i];",
				"    var paramsJson = JSON.stringify(params, this[JSON_REPLACER]);",
				"    //console.log('input:', methodName, paramsJson);",
				"    var resultJson = this[JSON_CALL](methodName, paramsJson);",
				"    //console.log('output:', resultJson);",
				"    return JSON.parse(resultJson, this[JSON_REVIVER]);",
				"}"
			);
			
			registeredMethods[methodName] = method;
		}
		
		/**
		 * Generates a line of JavaScript which intializes a variable equal to this Flash object using document.getElementById().
		 * @param variableName The variable name, which must be a valid JavaScript identifier.
		 */
		public static function JS_var_this(variableName:String):String
		{
			if (!_objectID)
				_objectID = getExternalObjectID(variableName);
			return 'var ' + variableName + ' = document.getElementById("' + _objectID + '");';
		}
		
		/**
		 * The "id" property of this Flash object.
		 * Use this as a reliable alternative to ExternalInterface.objectID, which may be null in some cases even if the Flash object has an "id" property.
		 */
		public static function get objectID():String
		{
			if (!_objectID)
				_objectID = getExternalObjectID("flash");
			return _objectID;
		}
		
		/**
		 * A way to get a Flash application's external object ID when ExternalInterface.objectID is null,
		 * which may occur when using jQuery.flash().
		 * @param desiredId If the flash application really has no id, this will be used as a base for creating a new unique id.
		 * @return The id of the flash application.
		 */
		private static function getExternalObjectID(desiredId:String = null):String
		{
			var id:String = ExternalInterface.objectID;
			if (!id) // if we don't know our ID
			{
				// use addCallback() to add a property to the flash component that will allow us to be found 
				ExternalInterface.addCallback(JSON_SUFFIX, trace);
				// find the element with the unique property name and get its ID (or set the ID if it doesn't have one)
				id = ExternalInterface.call(
					"function(uid, newId){\
						while (document.getElementById(newId))\
							newId += '_';\
						var elements = document.getElementsByTagName('*');\
						for (var i in elements)\
							if (elements[i][uid])\
								return elements[i].id || (elements[i].id = newId);\
					}",
					JSON_SUFFIX,
					desiredId || JSON_SUFFIX
				);
			}
			return id;
		}
		
		/**
		 * This will execute JavaScript code inside a function(){} wrapper.
		 * @param paramsAndCode A list of lines of code, optionally including an
		 *     Object containing named parameters to be passed from ActionScript to JavaScript.
		 *     Inside the code, you can use the "this" variable to access this flash object.
		 *     If instead you prefer to use a variable name other than "this", supply an Object
		 *     containing a "this" property equal to the desired variable name.
		 * @return The result of executing the JavaScript code.
		 * 
		 * @example Example 1
		 * <listing version="3.0">
		 *     var sum = JavaScript.exec({x: 2, y: 3}, "return x + y");
		 *     trace("sum:", sum);
		 * </listing>
		 * 
		 * @example Example 2
		 * <listing version="3.0">
		 *     trace( JavaScript.exec("return this.id;") );
		 * </listing>
		 * 
		 * @example Example 3
		 * <listing version="3.0">
		 *     JavaScript.registerMethod("testme", trace);
		 *     JavaScript.exec({"this": "self"}, "return self.testme(self.id);");
		 * </listing>
		 */		
		public static function exec(...paramsAndCode):*
		{
			if (!initialized)
				initialize();
			
			if (paramsAndCode.length == 1 && paramsAndCode[0] is Array)
				paramsAndCode = paramsAndCode[0];
			
			var pNames:Array = [];
			var pValues:Array = [];
			var code:String = '';
			var json:Object;
			var thisVar:String = 'this';
			
			// If JSON is not available, settle with the flawed ExternalInterface.call() parameters feature.
			// If a parameter is an Object, we can't trust ExternalInterface.call() since it doesn't quote keys in object literals.
			// It also does not escape the backslash in String values.
			// For example, if you give {"Content-Type": "foo\\"} as a parameter, ExternalInterface generates the following invalid
			// object literal: {Content-Type: "foo\"}.
			try {
				json = getDefinitionByName("JSON");
			} catch (e:Error) { }
			
			// separate function parameters from code
			for each (var value:Object in paramsAndCode)
			{
				if (value.constructor == Object)
				{
					// We assume that all the keys in the Object are valid JavaScript identifiers,
					// since they are to be used in the code as variables.
					for (var key:String in value)
					{
						var param:Object = value[key];
						if (json)
						{
							if (key == 'this')
							{
								thisVar = String(param);
								if (thisVar)
									code = JS_var_this(thisVar) + '\n' + code;
							}
							else
							{
								// put a variable declaration at the beginning of the code
								code = "var " + key + " = " + json.stringify(param) + ";\n" + code;
							}
						}
						else
						{
							// JSON unavailable
							pNames.push(key);
							pValues.push(param);
						}
					}
				}
				else
					code += value + '\n';
			}
			
			if (thisVar == 'this')
			{
				// to make the "this" symbol work as expected we need to use Function.apply().
				thisVar = '__JavaScript_dot_as__';
				code = JS_var_this(thisVar) + '\nreturn (function(){\n' + code + '}).apply(' + thisVar + ');';
			}
			
			
			// concatenate all code inside a function wrapper
			code = 'function(' + pNames.join(',') + '){\n' + code + '}';
			
			// if there are no parameters, just run the code
			if (pNames.length == 0)
				return ExternalInterface.call(code);
			
			// call the function with the specified parameters
			pValues.unshift(code);
			return ExternalInterface.call.apply(null, pValues);
		}
	}
}
