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

package weave.api
{
	import avmplus.DescribeType;
	
	import flash.external.ExternalInterface;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import mx.core.FlexGlobals;
	import mx.core.Singleton;
	
	import weave.api.core.IErrorManager;
	import weave.api.core.IExternalSessionStateInterface;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILocaleManager;
	import weave.api.core.IProgressIndicator;
	import weave.api.core.ISessionManager;
	import weave.api.core.IStageUtils;
	import weave.api.data.IAttributeColumnCache;
	import weave.api.data.ICSVParser;
	import weave.api.data.IProjectionManager;
	import weave.api.data.IQualifiedKeyManager;
	import weave.api.data.IStatisticsCache;
	import weave.api.services.IURLRequestUtils;

	/**
	 * Static functions for managing implementations of Weave framework classes.
	 * 
	 * @author adufilie
	 */
	public class WeaveAPI
	{
		/**
		 * For use with StageUtils.startTask(); this priority is used for things that must be done before anything else.
		 * Tasks having this priority will take over the scheduler and prevent any other asynchronous task from running until it is completed.
		 */
		public static const TASK_PRIORITY_0_IMMEDIATE:uint = 0;
		/**
		 * For use with StageUtils.startTask(); this priority is associated with rendering.
		 */
		public static const TASK_PRIORITY_1_RENDERING:uint = 1;
		/**
		 * For use with StageUtils.startTask(); this priority is associated with data manipulation tasks such as building an index.
		 */
		public static const TASK_PRIORITY_2_BUILDING:uint = 2;
		/**
		 * For use with StageUtils.startTask(); this priority is associated with parsing raw data.
		 */
		public static const TASK_PRIORITY_3_PARSING:uint = 3;
		
		/**
		 * This is the singleton instance of the registered ISessionManager implementation.
		 */
		public static function get SessionManager():ISessionManager
		{
			return getSingletonInstance(ISessionManager);
		}
		/**
		 * This is the singleton instance of the registered IStageUtils implementation.
		 */
		public static function get StageUtils():IStageUtils
		{
			return getSingletonInstance(IStageUtils);
		}
		/**
		 * This is the singleton instance of the registered IErrorManager implementation.
		 */
		public static function get ErrorManager():IErrorManager
		{
			return getSingletonInstance(IErrorManager);
		}
		/**
		 * This is the singleton instance of the registered IExternalSessionStateInterface implementation.
		 */
		public static function get ExternalSessionStateInterface():IExternalSessionStateInterface
		{
			return getSingletonInstance(IExternalSessionStateInterface);
		}
		/**
		 * This is the singleton instance of the registered IProgressIndicator implementation.
		 */
		public static function get ProgressIndicator():IProgressIndicator
		{
			return getSingletonInstance(IProgressIndicator);
		}
		/**
		 * This is the singleton instance of the registered IAttributeColumnCache implementation.
		 */
		public static function get AttributeColumnCache():IAttributeColumnCache
		{
			return getSingletonInstance(IAttributeColumnCache);
		}
		/**
		 * This is the singleton instance of the registered IStatisticsCache implementation.
		 */
		public static function get StatisticsCache():IStatisticsCache
		{
			return getSingletonInstance(IStatisticsCache);
		}
		/**
		 * This is the singleton instance of the registered IProjectionManager implementation.
		 */
		public static function get ProjectionManager():IProjectionManager
		{
			return getSingletonInstance(IProjectionManager);
		}
		/**
		 * This is the singleton instance of the registered IQualifiedKeyManager implementation.
		 */
		public static function get QKeyManager():IQualifiedKeyManager
		{
			return getSingletonInstance(IQualifiedKeyManager);
		}
		/**
		 * This is the singleton instance of the registered ICSVParser implementation.
		 */
		public static function get CSVParser():ICSVParser
		{
			return getSingletonInstance(ICSVParser);
		}
		/**
		 * This is the singleton instance of the registered IURLRequestUtils implementation.
		 */
		public static function get URLRequestUtils():IURLRequestUtils
		{
			return getSingletonInstance(IURLRequestUtils);
		}
		/**
		 * This is the singleton instance of the registered ILocaleManager implementation.
		 */
		public static function get LocaleManager():ILocaleManager
		{
			return getSingletonInstance(ILocaleManager);
		}
		/**
		 * This is the top-level object in Weave.
		 */		
		public static function get globalHashMap():ILinkableHashMap
		{
			return getSingletonInstance(ILinkableHashMap);
		}
		/**************************************/

		
		/**
		 * This returns the top level application as defined by FlexGlobals.topLevelApplication
		 * or WeaveAPI.topLevelApplication if FlexGlobals isn't defined.
		 */
		public static function get topLevelApplication():Object
		{
			return FlexGlobals.topLevelApplication;
		}
		
		/**
		 * avmplus.describeTypeJSON(o:*, flags:uint):Object
		 */
		private static const describeTypeJSON:Function = DescribeType.getJSONFunction();
		
		private static var _externalInterfaceInitialized:Boolean = false;
		
		/**
		 * This will be true after initializeExternalInterface() completes successfully.
		 */
		public static function get externalInterfaceInitialized():Boolean
		{
			return _externalInterfaceInitialized;
		}
		
		/**
		 * This function will initialize the external API so calls can be made from JavaScript to Weave.
		 * After initializing, this will call an external function weave.apiReady(weave) if it exists, where
		 * 'weave' is a pointer to the instance of Weave that was initialized.
		 */
		public static function initializeExternalInterface():void
		{
			if (!ExternalInterface.available || _externalInterfaceInitialized)
				return;
			
			try
			{
				// initialize Direct API
				var interfaces:Array = [IExternalSessionStateInterface]; // add more interfaces here if necessary
				for each (var theInterface:Class in interfaces)
					registerJavaScriptInterface(getSingletonInstance(theInterface), theInterface);

				var prev:Boolean = ExternalInterface.marshallExceptions;
				ExternalInterface.marshallExceptions = false;
				
				// initialize WeavePath API
				executeJavaScript(new WeavePath());
				
				// set flag before calling external apiReady()
				_externalInterfaceInitialized = true;
				
				// call external weaveApiReady(weave)
				executeJavaScript(
					'if (weave.hasOwnProperty("weaveApiReady")) { weave.weaveApiReady(weave); }',
					'if (window && window.weaveApiReady) { window.weaveApiReady(weave); }',
					'else if (weaveApiReady) { weaveApiReady(weave); }'
				);
				
				ExternalInterface.marshallExceptions = prev;
			}
			catch (e:Error)
			{
				handleExternalError(e);
			}
		}

		[Embed(source="WeavePath.js", mimeType="application/octet-stream")]
		private static const WeavePath:Class;

		/**
		 * Calls external function(s) weave.weaveReady(weave) and/or window.weaveReady(weave).
		 */		
		public static function callExternalWeaveReady():void
		{
			initializeExternalInterface();
			
			if (!ExternalInterface.available)
				return;
			
			try
			{
				var prev:Boolean = ExternalInterface.marshallExceptions;
				ExternalInterface.marshallExceptions = false;
				executeJavaScript(
					'if (weave.hasOwnProperty("weaveReady")) { weave.weaveReady(weave); }',
					'if (window && window.weaveReady) { window.weaveReady(weave); }',
					'else if (weaveReady) { weaveReady(weave); }'
				);
				ExternalInterface.marshallExceptions = prev;
			}
			catch (e:Error)
			{
				handleExternalError(e);
			}
		}

		/**
		 * Exposes an interface to JavaScript.
		 * @param host The host object containing methods to expose to JavaScript.
		 * @param theInterface An interface listing methods on the host to be exposed.
		 */
		public static function registerJavaScriptInterface(host:Object, theInterface:Class = null):void
		{
			var classInfo:Object = describeTypeJSON(theInterface || host, DescribeType.INCLUDE_TRAITS | DescribeType.INCLUDE_METHODS | DescribeType.HIDE_NSURI_METHODS | DescribeType.USE_ITRAITS);
			// register each external interface function
			for each (var methodInfo:Object in classInfo.traits.methods)
			{
				var methodName:String = methodInfo.name;
				var method:Function = host[methodName];
				// find the number of required parameters
				var paramCount:int = 0;
				while (paramCount < method.length && !methodInfo.parameters[paramCount].optional)
					paramCount++;
				
				JavaScript.registerMethod(methodName, method, paramCount);
			}
		}

		/**
		 * This will execute JavaScript code that uses a 'weave' variable.
		 * @param paramsAndCode A list of lines of code, optionally including an
		 *     Object containing named parameters to be passed from ActionScript to JavaScript.
		 *     Inside the code, you can use a variable named "weave" which will be a pointer
		 *     to the Weave instance.
		 * @return The result of executing the JavaScript code.
		 * 
		 * @example Example 1
		 * <listing version="3.0">
		 *     var sum = WeaveAPI.executeJavaScript({x: 2, y: 3}, "return x + y");
		 *     trace("sum:", sum);
		 * </listing>
		 * 
		 * @example Example 2
		 * <listing version="3.0">
		 *     var sum = WeaveAPI.executeJavaScript(
		 *         {x: 2, y: 3},
		 *         'return weave.path().vars({x: x, y: y}).getValue("x + y");'
		 *     );
		 *     trace("sum:", sum);
		 * </listing>
		 */		
		public static function executeJavaScript(...paramsAndCode):*
		{
			// insert weave variable declaration
			paramsAndCode.unshift({"this": "weave"});
			return JavaScript.exec(paramsAndCode);
		}
		
		private static function handleExternalError(e:Error):void
		{
			if (e.errorID == 2060)
				ErrorManager.reportError(e, "In the HTML embedded object tag, make sure that the parameter 'allowScriptAccess' is set appropriately. " + e.message);
			else
				ErrorManager.reportError(e);
		}
		
		/**************************************/
		
		/**
		 * This will register an implementation of an interface.
		 * @param theInterface The interface class.
		 * @param theImplementation An implementation of the interface.
		 * @param displayName An optional display name for the implementation.
		 */
		public static function registerImplementation(theInterface:Class, theImplementation:Class, displayName:String = null):void
		{
			_verifyImplementation(theInterface, theImplementation);
			
			var array:Array = _implementations[theInterface] as Array;
			if (!array)
				_implementations[theInterface] = array = [];
			
			// overwrite existing displayName if specified
			if (displayName || !_implementationDisplayNames[theImplementation])
				_implementationDisplayNames[theImplementation] = displayName || getQualifiedClassName(theImplementation).split(':').pop();

			if (array.indexOf(theImplementation) < 0)
			{
				array.push(theImplementation);
				// sort by displayName
				array.sort(_sortImplementations);
			}
		}
		
		/**
		 * This will get an Array of class definitions that were previously registered as implementations of the specified interface.
		 * @param theInterface The interface class.
		 * @return An Array of class definitions that were previously registered as implementations of the specified interface.
		 */
		public static function getRegisteredImplementations(theInterface:Class):Array
		{
			var array:Array = _implementations[theInterface] as Array;
			return array ? array.concat() : [];
		}
		
		/**
		 * This will get the displayName that was specified when an implementation was registered with registerImplementation().
		 * @param theImplementation An implementation that was registered with registerImplementation().
		 * @return The display name for the implementation.
		 */
		public static function getRegisteredImplementationDisplayName(theImplementation:Class):String
		{
			var str:String = _implementationDisplayNames[theImplementation] as String;
			return str && lang(str);
		}
		
		/**
		 * @private
		 * sort by displayName
		 */
		private static function _sortImplementations(impl1:Class, impl2:Class):int
		{
			var name1:String = _implementationDisplayNames[impl1] as String;
			var name2:String = _implementationDisplayNames[impl2] as String;
			if (name1 < name2)
				return -1;
			if (name1 > name2)
				return 1;
			return 0;
		}
		
		private static const _implementations:Dictionary = new Dictionary(); // Class -> Array<Class>
		private static const _implementationDisplayNames:Dictionary = new Dictionary(); // Class -> String
		
		/**
		 * @private
		 */
		private static function _verifyImplementation(theInterface:Class, theImplementation:Class):void
		{
			var interfaceName:String = getQualifiedClassName(theInterface);
			var classInfo:Object = describeTypeJSON(theImplementation, DescribeType.INCLUDE_TRAITS | DescribeType.INCLUDE_INTERFACES | DescribeType.USE_ITRAITS);
			if (classInfo.traits.interfaces.indexOf(interfaceName) < 0)
				throw new Error(getQualifiedClassName(theImplementation) + ' does not implement ' + interfaceName);
		}
		
		/**
		 * This registers an implementation for a singleton interface.
		 * @param theInterface The interface to register.
		 * @param theImplementation The implementation to register.
		 * @return A value of true if the implementation was successfully registered.
		 */
		public static function registerSingleton(theInterface:Class, theImplementation:Class):Boolean
		{
			_verifyImplementation(theInterface, theImplementation);
			
			var interfaceName:String = getQualifiedClassName(theInterface);
			Singleton.registerClass(interfaceName, theImplementation);
			return Singleton.getClass(interfaceName) == theImplementation;
		}
		
		/**
		 * This function returns the singleton instance for a registered interface.
		 *
		 * This method should not be called at static initialization time,
		 * because the implementation may not have been registered yet.
		 * 
		 * @param singletonInterface An interface to a singleton class.
		 * @return The singleton instance that implements the specified interface.
		 */
		public static function getSingletonInstance(singletonInterface:Class):*
		{
			///////////////////////
			// TEMPORARY SOLUTION (until everything is a plug-in.)
			if (!_initialized)
			{
				_initialized = true;
				// run static initialization code to register weave implementations
				try
				{
					getDefinitionByName("_InitializeWeaveCore");
					getDefinitionByName("_InitializeWeaveData"); 
					getDefinitionByName("_InitializeWeaveUISpark");
					getDefinitionByName("_InitializeWeaveUI");
				}
				catch (e:Error)
				{
					trace(e.getStackTrace() || e);
				}
			}
			// END TEMPORARY SOLUTION
			///////////////////////////
			
			var result:* = _singletonDictionary[singletonInterface];
			// If no instance has been created yet, create one now.
			if (!result)
			{
				var interfaceName:String = getQualifiedClassName(singletonInterface);
				try
				{
					// This may fail if there is no registered class,
					// or the class doesn't have a getInstance() method.
					result = Singleton.getInstance(interfaceName);
				}
				catch (e:Error)
				{
					var classDef:Class = Singleton.getClass(interfaceName);
					// If there is a registered class, use the local dictionary.
					if (classDef)
					{
						result = new classDef();
					}
					else
					{
						// Throw the error from Singleton.getInstance().
						throw e;
					}
				}
				_singletonDictionary[singletonInterface] = result;
			}
			// Return saved instance.
			return result;
		}
		
		/**
		 * Used by getSingletonInstance.
		 */		
		private static var _initialized:Boolean = false;
		
		/**
		 * This is used to save a mapping from an interface to its singleton implementation instance.
		 */
		private static const _singletonDictionary:Dictionary = new Dictionary();
		
		/**
		 * Outputs to external console.log
		 */
		public static function externalTrace(...params):void
		{
			executeJavaScript(
				{"params": params},
				"console.log.apply(console, params)"
			);
		}
	}
}

import flash.external.ExternalInterface;
import flash.utils.getDefinitionByName;

/**
 * An alternative to flash.external.ExternalInterface with workarounds for its limitations.
 * Requires Flash Player 11 or later to get the full benefit (uses native JSON support),
 * but has backwards compatibility to Flash Player 10, or possibly earlier versions (untested).
 * 
 * @author adufilie
 */
internal class JavaScript
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
		return 'var ' + variableName + ' = document.getElementById("' + objectID + '");';
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
