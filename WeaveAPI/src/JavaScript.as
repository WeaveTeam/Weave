/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
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
	import flash.system.Capabilities;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;

	/**
	 * An alternative to flash.external.ExternalInterface with workarounds for its limitations.
	 * Requires Flash Player 11 or later to get the full benefit (uses native JSON support),
	 * but has backwards compatibility to Flash Player 10, or possibly earlier versions (untested).
	 * 
	 * If there is a syntax error, JavaScript.exec() will throw the Error while ExternalInterface.call() would return null.
	 * 
	 * When parameters are passed to ExternalInterface.call() it attempts to stringify the parameters
	 * to JavaScript object literals, but it does not quote keys and it does not escape backslashes
	 * in String values. For example, if you give <code>{"Content-Type": "foo\\"}</code> as a parameter,
	 * ExternalInterface generates the following invalid code: <code>{Content-Type: "foo\"}</code>.
	 * The same problem occurs when returning an Object from an ActionScript function that was invoked
	 * from JavaScript. This class works around the limitation by using JSON.stringify() and JSON.parse()
	 * and escaping backslashes in resulting JSON strings. The values <code>NaN, Infinity, -Infinity</code>
	 * are preserved, as well as function pointers. When a JavaScript function is called from ActionScript,
	 * it uses a property called "this" as the <code>this</code> argument for the function.
	 * 
	 * This class also provides an objectID accessor which is more reliable than ExternalInterface.objectID,
	 * which may be null if the Flash object was created using jQuery.flash() even if the Flash object
	 * has an "id" property in JavaScript.
	 * 
	 * @see flash.external.ExternalInterface
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
		 * This is the name of the generic external interface function which uses JSON input and output.
		 */
		private static const JSON_CALL:String = "_jsonCall";
		
		/**
		 * The name of the property used to store a replacer function for the second parameter of JSON.stringify
		 */
		private static const JSON_REPLACER:String = "_jsonReplacer";
		
		/**
		 * The name of the property used to store a reviver function for the second parameter of JSON.parse
		 */
		private static const JSON_REVIVER:String = "_jsonReviver";
		
		/**
		 * JSON extension property name for the needsReviving function.
		 */
		private static const NEEDS_REVIVING:String = "_needsReviving";
		
		/**
		 * The name of the property used to store a lookup from JSON IDs to values.
		 */
		private static const JSON_LOOKUP:String = "_jsonLookup";
		
		/**
		 * The name of the property used to store a function that will cache a debounced version of a function to be used when reviving functions from JSON.
		 */
		private static const DEBOUNCE:String = "_debounce";
		
		/**
		 * A random String which is highly unlikely to appear in any String value.  Used as a suffix for <code>NaN, -Infinity, Infinity</code>.
		 */
		private static const JSON_SUFFIX:String = ';' + Math.random() + ';' + new Date();
		
		/**
		 * A random String which is highly unlikely to appear in any String value.  Used as a prefix for function identifiers in JSON.
		 */
		private static const JSON_FUNCTION_PREFIX:String = 'function' + JSON_SUFFIX + ';';
		
		/**
		 * Maps an ID to its corresponding value for use with _jsonReviver/_jsonReplacer.
		 * Also maps a Function to its corresponding ID.
		 */
		private static const _jsonLookup:Dictionary = new Dictionary();
		
		/**
		 * Used for generating unique function IDs.
		 * Use a positive increment for ActionScript functions.
		 * The JavaScript equivalent uses a negative increment to avoid collisions.
		 */
		private static var _functionCounter:int = 0;
		
		/**
		 * This flag will be set to true whenever _jsonReplacer makes a replacement that requires _jsonReviver to interpret.
		 */
		private static var _needsReviving:Boolean = false;
		
		/**
		 * Extensions to _jsonReplacer/_jsonReviver.
		 */
		private static const _jsonExtensions:Array = [];
		
		/**
		 * The name of a JavaScript property of this flash instance which contains an Array of JSON replacer/reviver extensions.
		 * Each object in the Array can contain "replacer" and "reviver" properties containing the extension functions.
		 */
		public static const JSON_EXTENSIONS:String = "_jsonExtensions";
		
		/**
		 * Alias for ExternalInterface.available
		 * @see flash.external.ExternalInterface#available
		 */
		public static const available:Boolean = ExternalInterface.available;
		
		/**
		 * The "id" property of this Flash object.
		 * Use this as a reliable alternative to ExternalInterface.objectID, which may be null in some cases even if the Flash object has an "id" property.
		 */
		public static function get objectID():String
		{
			if (!_objectID)
				_objectID = getExternalObjectID();
			return _objectID;
		}
		
		/**
		 * A JavaScript expression which gets a pointer to this Flash object.
		 */
		public static function get JS_this():String
		{
			if (!_objectID)
				_objectID = getExternalObjectID();
			return 'document.getElementById("' + _objectID + '")';
		}
		
		/**
		 * A way to get a Flash application's external object ID when ExternalInterface.objectID is null,
		 * which may occur when using jQuery.flash().
		 * @param desiredId If the flash application really has no id, this will be used as a base for creating a new unique id.
		 * @return The id of the flash application.
		 */
		private static function getExternalObjectID(desiredId:String = "flash"):String
		{
			if (!_objectID)
				_objectID = ExternalInterface.objectID;
			if (!_objectID) // if we don't know our ID
			{
				// use addCallback() to add a property to the flash component that will allow us to be found 
				ExternalInterface.addCallback(JSON_SUFFIX, trace);
				// find the element with the unique property name and get its ID (or set the ID if it doesn't have one)
				_objectID = ExternalInterface.call(
					<![CDATA[
						function(uid, newId) {
							while (document.getElementById(newId))
								newId += '_';
							var elements = document.getElementsByTagName('*');
							for (var i in elements)
								if (elements[i][uid])
									return elements[i].id || (elements[i].id = newId);
						}
					]]>,
					JSON_SUFFIX,
					desiredId
				);
			}
			return _objectID;
		}
		
		/**
		 * Initializes json variable and required external JSON interface.
		 */
		private static function initialize():void
		{
			// one-time initialization attempt
			initialized = true;
			
			// save special IDs for values not supported by JSON
			for each (var symbol:Object in [NaN, Infinity, -Infinity])
				_jsonLookup[symbol + JSON_SUFFIX] = symbol;
			
			// determine if backslashes need to be escaped
			var slashes:String = "\\\\";
			backslashNeedsEscaping = (ExternalInterface.call('function(slashes){ return slashes; }', slashes) != slashes);
			
			try
			{
				if (ExternalInterface.call('function(){ return typeof JSON == "undefined"; }'))
					trace("The web browser does not have JSON support.");
				else
					json = getDefinitionByName("JSON");
			}
			catch (e:Error)
			{
				trace("Your version of Flash Player (" + Capabilities.version + " " + Capabilities.playerType + ") does not have native JSON support.");
			}
			
			ExternalInterface.addCallback(JSON_CALL, _jsonCall);
			exec(
				{
					"JSON_FUNCTION_PREFIX": JSON_FUNCTION_PREFIX,
					"JSON_EXTENSIONS": JSON_EXTENSIONS,
					"JSON_REPLACER": JSON_REPLACER,
					"JSON_REVIVER": JSON_REVIVER,
					"JSON_SUFFIX": JSON_SUFFIX,
					"JSON_LOOKUP": JSON_LOOKUP,
					"JSON_CALL": JSON_CALL,
					"DEBOUNCE": DEBOUNCE,
					"useJson": json != null
				},
				POLYFILLS,
				LODASH_DEBOUNCE,
				<![CDATA[
					var flash = this;
				
					var toJson, fromJson;
					if (useJson)
					{
						toJson = function(value) { return JSON.stringify(value, flash[JSON_REPLACER]); };
						fromJson = function(value) { return JSON.parse(value, flash[JSON_REVIVER]); };
					}
					else
					{
						toJson = function(value) {
							return Array.isArray(value) ? value.map(toJson) : flash[JSON_REPLACER]('', value);
						};
						fromJson = function(value) {
							return Array.isArray(value) ? value.map(fromJson) : flash[JSON_REVIVER]('', value);
						};
					}
				
					var functionCounter = 0;
					var lookup = flash[JSON_LOOKUP] = {};
					var extensions = flash[JSON_EXTENSIONS] = [];
					var symbols = [NaN, Infinity, -Infinity];
					for (var i in symbols)
						lookup[symbols[i] + JSON_SUFFIX] = symbols[i];
					
					function cacheProxyFunction(id) {
						var func = function() {
							if (!flash[JSON_CALL])
								throw new Error("Cannot use the JavaScript API of a Flash object after it has been removed from the DOM.");
							var params = Array.prototype.slice.call(arguments);
							var paramsJson = toJson(params);
							var resultJson = flash[JSON_CALL](id, paramsJson);
							return fromJson(resultJson);
						};
						func[JSON_FUNCTION_PREFIX] = id;
						return lookup[id] = func;
					}
	
					flash[JSON_REPLACER] = function(key, value) {
						if (typeof value === 'function') {
							if (!value[JSON_FUNCTION_PREFIX]) {
								var id = JSON_FUNCTION_PREFIX + (--functionCounter);
								value[JSON_FUNCTION_PREFIX] = id;
								lookup[id] = value;
							}
							value = value[JSON_FUNCTION_PREFIX];
						}
						else if (typeof value === 'number' && !isFinite(value))
							value = value + JSON_SUFFIX;
						else if (Array.isArray(value) && !(value instanceof Array))
							value = Array.prototype.slice.call(value);
						for (var i in extensions)
							if (typeof extensions[i] === 'object' && typeof extensions[i].replacer === 'function')
								value = extensions[i].replacer.call(flash, key, value);
						return value;
					};
					
					flash[JSON_REVIVER] = function(key, value) {
						if (typeof value === 'string') {
							if (lookup.hasOwnProperty(value))
								value = lookup[value];
							else if (value.substr(0, JSON_FUNCTION_PREFIX.length) == JSON_FUNCTION_PREFIX)
								value = cacheProxyFunction(value);
						}
						for (var i in extensions)
							if (typeof extensions[i] === 'object' && typeof extensions[i].reviver === 'function')
								value = extensions[i].reviver.call(flash, key, value);
						return value;
					};
					
					flash[DEBOUNCE] = function(func, wait) {
						if (func.hasOwnProperty('cancel') && func.hasOwnProperty('flush') && func.hasOwnProperty(JSON_FUNCTION_PREFIX))
							return func;
						var id = flash[JSON_REPLACER]('', func);
						var debounced = debounce(func, wait);
						debounced[JSON_FUNCTION_PREFIX] = id;
						return lookup[id] = debounced;
					};
				]]>
			);
		}
		
		/**
		 * Handles a JavaScript request.
		 * @param methodId The ID of the method to call.
		 * @param paramsJson An Array of parameters to pass to the method, stringified with JSON.
		 * @return The result of calling the method, stringified with JSON.
		 */
		private static function _jsonCall(methodId:String, paramsJson:Object):Object
		{
			ExternalInterface.marshallExceptions = true; // let the external code handle errors
			
			var method:Function = _jsonReviver('', methodId) as Function;
			if (method == null)
				throw new Error('No method with id="' + methodId + '"');
			
			// json to object
			var params:Array;
			if (json)
				params = json.parse(paramsJson, _jsonReviver);
			else
				params = (paramsJson as Array).map(_mapJsonReviver);
			
			var result:* = method.apply(null, params);
			
			// object to json
			var resultJson:*;
			if (json)
				resultJson = json.stringify(result, _jsonReplacer) || 'null';
			else
				resultJson = result is Array ? (result as Array).map(_mapJsonReplacer) : _jsonReplacer('', result);
			
			// work around unescaped backslash bug
			if (resultJson is String && backslashNeedsEscaping && (resultJson as String).indexOf('\\') >= 0)
				resultJson = (resultJson as String).split('\\').join('\\\\');
			
			return resultJson;
		}
		
		private static function _mapJsonReplacer(value:*, i:*, a:*):* { return _jsonReplacer('', value); }
		private static function _mapJsonReviver(value:*, i:*, a:*):* { return _jsonReviver('', value); }
		
		/**
		 * Preserves primitive values not supported by JSON: NaN, Infinity, -Infinity
		 * Also looks up or generates an ID corresponding to a Function value.
		 */
		private static function _jsonReplacer(key:String, value:*):*
		{
			// Function -> ID
			if (value is Function)
			{
				var id:String = _jsonLookup[value] as String;
				if (!id)
				{
					id = JSON_FUNCTION_PREFIX + (++_functionCounter);
					_jsonLookup[value] = id;
					_jsonLookup[id] = value;
				}
				_needsReviving = true;
				value = id;
			}
			else if (value is Number && !isFinite(value as Number))
			{
				_needsReviving = true;
				value = value + JSON_SUFFIX;
			}
			for each (var extension:Object in _jsonExtensions)
			{
				if (extension[NEEDS_REVIVING] is Function && extension[NEEDS_REVIVING](key, value))
					_needsReviving = true;
				if (extension[JSON_REPLACER] is Function)
					value = extension[JSON_REPLACER](key, value);
			}
			return value;
		}
		
		/**
		 * Preserves primitive values not supported by JSON: undefined, NaN, Infinity, -Infinity
		 * Also looks up or generates a Function corresponding to its ID value.
		 */
		private static function _jsonReviver(key:String, value:*):*
		{
			if (value is String)
			{
				if (_jsonLookup.hasOwnProperty(value))
					value = _jsonLookup[value];
				else if ((value as String).substr(0, JSON_FUNCTION_PREFIX.length) == JSON_FUNCTION_PREFIX)
					value = _cacheProxyFunction(value as String); // ID -> Function
			}
			for each (var extension:Object in _jsonExtensions)
				if (extension[JSON_REVIVER] is Function)
					value = extension[JSON_REVIVER](key, value);
			return value;
		}
		
		/**
		 * Caches a new proxy function for a JavaScript function in _jsonLookup.
		 * @param id The ID of the JavaScript function.
		 * @return The proxy function.
		 */
		private static function _cacheProxyFunction(id:String):Function
		{
			var params:Object = {"id": id, "catch": false };
			var script:String = [
				"var func = this." + JSON_REVIVER + "('', id);",
				"return func.apply(func['this'], args);"
			].join('\n');
			
			var func:Function = function():*{
				params['args'] = arguments;
				return exec(params, script);
			} as Function;
			
			_jsonLookup[func] = id;
			_jsonLookup[id] = func;
			
			return func;
		}
		
		/**
		 * Extends JavaScript JSON communication to support new types of objects passed between ActionScript and JavaScript.
		 * This only extends the ActionScript side. Corresponding JavaScript code must written if specialized JavaScript
		 * Objects are to be supported.
		 * @param replacer function(key:String, value:*):* ; Replaces an Object with a JSON-serializable representation. 
		 * @param reviver function(key:String, value:*):* ; Revives an Object from its JSON representation.
		 * @param needsReviving function(key:String, value:*):Boolean ; Determines if a value requires reviving in JavaScript once replaced in ActionScript.
		 * @see #jsonAvailable
		 * 
		 * @example Example JavaScript code (func1 and func2 should be function definitions)
		 * <listing version="3.0">
		 * JavaScript.exec(
		 *     {"JSON_EXTENSIONS": JavaScript.JSON_EXTENSIONS},
		 *     'this[JSON_EXTENSIONS].push({"replacer": func1, "reviver": func2});'
		 * );
		 * </listing>
		 */
		public static function extendJson(replacer:Function, reviver:Function, needsReviving:Function):void
		{
			var extension:Object = {};
			extension[JSON_REPLACER] = replacer;
			extension[JSON_REVIVER] = reviver;
			extension[NEEDS_REVIVING] = needsReviving;
			_jsonExtensions.push(extension);
		}
		
		/**
		 * Exposes a method to JavaScript.
		 * @param methodName The name to be used in JavaScript.
		 * @param method The method.
		 */
		public static function registerMethod(methodName:String, method:Function):void
		{
			if (!initialized)
				initialize();
			
			exec(
				{
					"JSON_REVIVER": JSON_REVIVER,
					"methodName": methodName,
					"jsonId": _jsonReplacer('', method)
				},
				"this[methodName] = this[JSON_REVIVER]('', jsonId);"
			);
		}
		
		/**
		 * This will execute JavaScript code inside a function(){} wrapper.
		 * @param paramsAndCode A list of lines of code, optionally including an
		 *     Object containing named parameters to be passed from ActionScript to JavaScript.
		 * 
		 *     Inside the code, you can use the "this" variable to access this flash object.
		 *     If instead you prefer to use a variable name other than "this", supply an Object
		 *     like <code>{"this": "yourDesiredVariableName"}</code>.
		 * 
		 *     By default, a JavaScript Error will be marshalled to an ActionScript Error.
		 *     To disable this behavior, supply an Object like <code>{"catch": false}</code>.
		 *     You can also provide an ActionScript function to handle errors: <code>{"catch": myErrorHandler}</code>.
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
		 *     JavaScript.exec({"this": "self"}, "self.testme(self.id);");
		 * </listing>
		 */		
		public static function exec(...paramsAndCode):*
		{
			if (!initialized)
				initialize();
			
			if (paramsAndCode.length == 1 && paramsAndCode[0] is Array)
				paramsAndCode = paramsAndCode[0];
			
			var pNames:Array = json ? null : [];
			var pValues:Array = json ? null : [];
			var code:Array = [];
			var marshallExceptions:Object = true;
			
			// separate function parameters from code
			for each (var item:Object in paramsAndCode)
			{
				if (getQualifiedClassName(item) == 'Object')
				{
					// We assume that all the keys in the Object are valid JavaScript identifiers,
					// since they are to be used in the code as variables.
					for (var key:String in item)
					{
						var value:* = item[key];
						if (key == 'this')
						{
							// put a variable declaration at the beginning of the code
							var thisVar:String = value as String;
							if (thisVar)
							{
								if (!_objectID)
									getExternalObjectID(thisVar);
								code.unshift("var " + thisVar + " = this;");
							}
						}
						else if (key == 'catch')
						{
							// save error handler
							marshallExceptions = value;
						}
						else if (json)
						{
							// put a variable declaration at the beginning of the code
							var jsValue:String;
							if (value === null || value === undefined || value is Number || value is Boolean)
								jsValue = String(value);
							else if (value is Function)
								jsValue = 'this.' + JSON_REVIVER + '("", ' + json.stringify(value, _jsonReplacer) + ')';
							else if (typeof value === 'object')
							{
								_needsReviving = false;
								jsValue = json.stringify(value, _jsonReplacer);
								if (_needsReviving)
									jsValue = 'JSON.parse(' + json.stringify(jsValue) + ', this.' + JSON_REVIVER + ')';
							}
							else
								jsValue = json.stringify(value);
							
							code.unshift("var " + key + " = " + jsValue + ";");
						}
						else
						{
							// JSON unavailable
							value = _jsonReplacer('', value);
							
							// work around unescaped backslash bug
							// this backwards compatibility code doesn't handle Strings inside Objects.
							if (value is String && backslashNeedsEscaping)
								value = (value as String).split('\\').join('\\\\');
							
							pNames.push(key);
							pValues.push(value);
						}
					}
				}
				else
				{
					code.push(String(item));
				}
			}
			
			var CODE_PARAM:String = '__code_from_flash__';
			var ARGS_PARAM:String = '__arguments_from_flash__';
			var RESULT_VAR:String = '__result_for_flash__';
			
			// if the code references "this", we need to use Function.apply() to make the symbol work as expected
			var appliedCode:String;
			if (json)
				appliedCode = '(function(){\n' + code.join('\n') + '\n}).apply(' + JS_this + ')';
			else
				appliedCode = '(function(' + pNames.join(',') + '){\n' + code.join('\n') + '\n}).apply(' + JS_this + ', ' + ARGS_PARAM + ')';
			
			var result:* = undefined;
			var prevMarshallExceptions:Boolean = ExternalInterface.marshallExceptions;
			ExternalInterface.marshallExceptions = !!marshallExceptions;
			try
			{
				// we need to use eval() in order to receive syntax errors
				var TRY_CODE:String = json
					? 'return JSON.stringify(window.eval(' + CODE_PARAM + '), ' + JS_this + '.' + JSON_REPLACER + ');'
					: 'var ' + RESULT_VAR + ' = eval(' + CODE_PARAM + '); return ' + JS_this + '.' + JSON_REPLACER + '("", ' + RESULT_VAR + ');';
				
				var CATCH_CODE:String = marshallExceptions
					? 'if (e.toString() == "[object Error]") e.toString = function(){ return this.name + ": " + this.message; }; throw e;'
					: 'e.message += "\\n" + ' + CODE_PARAM + '; if (typeof console != "undefined") console.error(e);';
				
				var evalFunc:String = 'function(' + CODE_PARAM + ', ' + ARGS_PARAM + '){ try {\n' + TRY_CODE + '\n} catch (e) {\n' + CATCH_CODE + '\n} }';
				
				// work around unescaped backslash bug
				if (backslashNeedsEscaping && appliedCode.indexOf('\\') >= 0)
					appliedCode = appliedCode.split('\\').join('\\\\');
				
				result = ExternalInterface.call(evalFunc, appliedCode, pValues);
				
				// parse stringified results
				if (json)
				{
					if (result)
						result = json.parse(result, _jsonReviver);
				}
				else
				{
					result = _jsonReviver('', result);
				}
			}
			catch (e:*)
			{
				if (marshallExceptions is Function)
				{
					marshallExceptions(e);
				}
				else
				{
					ExternalInterface.marshallExceptions = prevMarshallExceptions;
					throw e;
				}
			}
			// we can't put this in a finally{} block because it prevents catch() from happening if set to false.
			ExternalInterface.marshallExceptions = prevMarshallExceptions;
			
			return result;
		}
		
		private static const POLYFILLS:String = <![CDATA[
			if (!Array.isArray)
				Array.isArray = function(arg) { return Object.prototype.toString.call(arg) === '[object Array]'; };
	
			if (!Array.prototype.map)
				Array.prototype.map = function(callback, thisArg) {
					var T, A, k;
					if (this == null)
						throw new TypeError(" this is null or not defined");
					var O = Object(this);
					var len = O.length >>> 0;
					if (typeof callback !== "function")
						throw new TypeError(callback + " is not a function");
					if (arguments.length > 1)
						T = thisArg;
					A = new Array(len);
					k = 0;
					while (k < len) {
						var kValue, mappedValue;
						if (k in O) {
							kValue = O[k];
							mappedValue = callback.call(T, kValue, k, O);
							A[k] = mappedValue;
						}
						k++;
					}
					return A;
				};
			
			if (!Object.keys)
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
						if (typeof obj !== 'object' && (typeof obj !== 'function' || obj === null))
							throw new TypeError('Object.keys called on non-object');
						
						var result = [], prop, i;
						
						for (prop in obj)
							if (hasOwnProperty.call(obj, prop))
								result.push(prop);
						
						if (hasDontEnumBug)
							for (i = 0; i < dontEnumsLength; i++)
								if (hasOwnProperty.call(obj, dontEnums[i]))
									result.push(dontEnums[i]);
						return result;
					};
				}());
			
			if (!Function.prototype.bind)
				Function.prototype.bind = function (oThis) {
					if (typeof this !== "function")
						throw new TypeError("Function.prototype.bind - what is trying to be bound is not callable");
					
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
		]]>;
		
		private static const LODASH_DEBOUNCE:String = <![CDATA[
			/**
			 * lodash 4.0.0-pre <https://lodash.com/>
			 * Copyright 2012-2015 The Dojo Foundation <http://dojofoundation.org/>
			 * Based on Underscore.js 1.8.3 <http://underscorejs.org/LICENSE>
			 * Copyright 2009-2015 Jeremy Ashkenas, DocumentCloud and Investigative Reporters & Editors
			 * Available under MIT license <https://lodash.com/license>
			 */
			
			/**
			 * Checks if `value` is the [language type](https://es5.github.io/#x8) of `Object`.
			 * (e.g. arrays, functions, objects, regexes, `new Number(0)`, and `new String('')`)
			 *
			 * @static
			 * @memberOf _
			 * @category Lang
			 * @param {*} value The value to check.
			 * @returns {boolean} Returns `true` if `value` is an object, else `false`.
			 * @example
			 *
			 * _.isObject({});
			 * // => true
			 *
			 * _.isObject([1, 2, 3]);
			 * // => true
			 *
			 * _.isObject(_.noop);
			 * // => true
			 *
			 * _.isObject(null);
			 * // => false
			 */
			function isObject(value) {
			  // Avoid a V8 JIT bug in Chrome 19-20.
			  // See https://code.google.com/p/v8/issues/detail?id=2291 for more details.
			  var type = typeof value;
			  return !!value && (type == 'object' || type == 'function');
			}
			
			/**
			 * Creates a debounced function that delays invoking `func` until after `wait`
			 * milliseconds have elapsed since the last time the debounced function was
			 * invoked. The debounced function comes with a `cancel` method to cancel
			 * delayed `func` invocations and a `flush` method to immediately invoke them.
			 * Provide an options object to indicate that `func` should be invoked on the
			 * leading and/or trailing edge of the `wait` timeout. Subsequent calls to the
			 * debounced function return the result of the last `func` invocation.
			 *
			 * **Note:** If `leading` and `trailing` options are `true`, `func` is invoked
			 * on the trailing edge of the timeout only if the the debounced function is
			 * invoked more than once during the `wait` timeout.
			 *
			 * See [David Corbacho's article](http://drupalmotion.com/article/debounce-and-throttle-visual-explanation)
			 * for details over the differences between `_.debounce` and `_.throttle`.
			 *
			 * @static
			 * @memberOf _
			 * @category Function
			 * @param {Function} func The function to debounce.
			 * @param {number} [wait=0] The number of milliseconds to delay.
			 * @param {Object} [options] The options object.
			 * @param {boolean} [options.leading=false] Specify invoking on the leading
			 *  edge of the timeout.
			 * @param {number} [options.maxWait] The maximum time `func` is allowed to be
			 *  delayed before it's invoked.
			 * @param {boolean} [options.trailing=true] Specify invoking on the trailing
			 *  edge of the timeout.
			 * @returns {Function} Returns the new debounced function.
			 * @example
			 *
			 * // avoid costly calculations while the window size is in flux
			 * jQuery(window).on('resize', _.debounce(calculateLayout, 150));
			 *
			 * // invoke `sendMail` when the click event is fired, debouncing subsequent calls
			 * jQuery('#postbox').on('click', _.debounce(sendMail, 300, {
			 *   'leading': true,
			 *   'trailing': false
			 * }));
			 *
			 * // ensure `batchLog` is invoked once after 1 second of debounced calls
			 * var source = new EventSource('/stream');
			 * jQuery(source).on('message', _.debounce(batchLog, 250, {
			 *   'maxWait': 1000
			 * }));
			 *
			 * // cancel a debounced call
			 * var todoChanges = _.debounce(batchLog, 1000);
			 * Object.observe(models.todo, todoChanges);
			 *
			 * Object.observe(models, function(changes) {
			 *   if (_.find(changes, { 'user': 'todo', 'type': 'delete'})) {
			 *     todoChanges.cancel();
			 *   }
			 * }, ['delete']);
			 *
			 * // ...at some point `models.todo` is changed
			 * models.todo.completed = true;
			 *
			 * // ...before 1 second has passed `models.todo` is deleted
			 * // which cancels the debounced `todoChanges` call
			 * delete models.todo;
			 */
			function debounce(func, wait, options) {
			  var args,
			      maxTimeoutId,
			      result,
			      stamp,
			      thisArg,
			      timeoutId,
			      trailingCall,
			      lastCalled = 0,
			      leading = false,
			      maxWait = false,
			      trailing = true;
			
			  if (typeof func != 'function') {
			    throw new TypeError(FUNC_ERROR_TEXT);
			  }
			  wait = wait < 0 ? 0 : (+wait || 0);
			  if (isObject(options)) {
			    leading = !!options.leading;
			    maxWait = 'maxWait' in options && Math.max(+options.maxWait || 0, wait);
			    trailing = 'trailing' in options ? !!options.trailing : trailing;
			  }
			
			  function cancel() {
			    if (timeoutId) {
			      clearTimeout(timeoutId);
			    }
			    if (maxTimeoutId) {
			      clearTimeout(maxTimeoutId);
			    }
			    lastCalled = 0;
			    args = maxTimeoutId = thisArg = timeoutId = trailingCall = undefined;
			  }
			
			  function complete(isCalled, id) {
			    if (id) {
			      clearTimeout(id);
			    }
			    maxTimeoutId = timeoutId = trailingCall = undefined;
			    if (isCalled) {
			      lastCalled = Date.now();
			      result = func.apply(thisArg, args);
			      if (!timeoutId && !maxTimeoutId) {
			        args = thisArg = undefined;
			      }
			    }
			  }
			
			  function delayed() {
			    var remaining = wait - (Date.now() - stamp);
			    if (remaining <= 0 || remaining > wait) {
			      complete(trailingCall, maxTimeoutId);
			    } else {
			      timeoutId = setTimeout(delayed, remaining);
			    }
			  }
			
			  function flush() {
			    if ((timeoutId && trailingCall) || (maxTimeoutId && trailing)) {
			      result = func.apply(thisArg, args);
			    }
			    cancel();
			    return result;
			  }
			
			  function maxDelayed() {
			    complete(trailing, timeoutId);
			  }
			
			  function debounced() {
			    args = arguments;
			    stamp = Date.now();
			    thisArg = this;
			    trailingCall = trailing && (timeoutId || !leading);
			
			    if (maxWait === false) {
			      var leadingCall = leading && !timeoutId;
			    } else {
			      if (!maxTimeoutId && !leading) {
			        lastCalled = stamp;
			      }
			      var remaining = maxWait - (stamp - lastCalled),
			          isCalled = remaining <= 0 || remaining > maxWait;
			
			      if (isCalled) {
			        if (maxTimeoutId) {
			          maxTimeoutId = clearTimeout(maxTimeoutId);
			        }
			        lastCalled = stamp;
			        result = func.apply(thisArg, args);
			      }
			      else if (!maxTimeoutId) {
			        maxTimeoutId = setTimeout(maxDelayed, remaining);
			      }
			    }
			    if (isCalled && timeoutId) {
			      timeoutId = clearTimeout(timeoutId);
			    }
			    else if (!timeoutId && wait !== maxWait) {
			      timeoutId = setTimeout(delayed, wait);
			    }
			    if (leadingCall) {
			      isCalled = true;
			      result = func.apply(thisArg, args);
			    }
			    if (isCalled && !timeoutId && !maxTimeoutId) {
			      args = thisArg = undefined;
			    }
			    return result;
			  }
			  debounced.cancel = cancel;
			  debounced.flush = flush;
			  return debounced;
			}
		]]>;
	}
}
