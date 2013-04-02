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
	import weave.api.ui.ICollabCursorManager;

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
		public static const TASK_PRIORITY_IMMEDIATE:uint = 0;
		/**
		 * For use with StageUtils.startTask(); this priority is associated with rendering.
		 */
		public static const TASK_PRIORITY_RENDERING:uint = 1;
		/**
		 * For use with StageUtils.startTask(); this priority is associated with data manipulation tasks such as building an index.
		 */
		public static const TASK_PRIORITY_BUILDING:uint = 2;
		/**
		 * For use with StageUtils.startTask(); this priority is associated with parsing raw data.
		 */
		public static const TASK_PRIORITY_PARSING:uint = 3;
		
		/**
		 * This is the singleton instance of the registered ISessionManager implementation.
		 */
		public static function get SessionManager():ISessionManager
		{
			return getSingletonInstance(ISessionManager);
		}
		/**
		 * This is the singleton instance of the registered ICollabCursorManger implementation.
		 */
		public static function get CollaborationCursorManager():ICollabCursorManager
		{
			return getSingletonInstance(ICollabCursorManager);
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
		
		/**
		 * This function will initialize the external interfaces so calls can be made from JavaScript to Weave.
		 * After initializing, this will call an external function weaveReady(weave) if it exists, where the
		 * 'weave' parameter is a pointer to the instance of Weave that is ready.
		 */
		public static function initializeExternalInterface():void
		{
			if (!ExternalInterface.available)
				return;
			
			try
			{
				var interfaces:Array = [IExternalSessionStateInterface]; // add more interfaces here if necessary
				for each (var theInterface:Class in interfaces)
				{
					var instance:Object = getSingletonInstance(theInterface);
					var classInfo:Object = describeTypeJSON(theInterface, DescribeType.INCLUDE_TRAITS | DescribeType.INCLUDE_METHODS | DescribeType.HIDE_NSURI_METHODS | DescribeType.USE_ITRAITS);
					// add a callback for each external interface function
					for each (var methodInfo:Object in classInfo.traits.methods)
						generateExternalInterfaceCallback(instance, methodInfo);
				}
				var prev:Boolean = ExternalInterface.marshallExceptions;
				ExternalInterface.marshallExceptions = false;
				ExternalInterface.call(
					'function(objectID) {' +
					'  var weave = document.getElementById(objectID);' +
					'  if (window && window.weaveReady) {' +
					'    window.weaveReady(weave);' +
					'  }' +
					'  else if (weaveReady) {' +
					'    weaveReady(weave);' +
					'  }' +
					'}',
					[ExternalInterface.objectID]
				);
				ExternalInterface.marshallExceptions = prev;
			}
			catch (e:Error)
			{
				if (e.errorID == 2060)
					ErrorManager.reportError(e, "In the HTML embedded object tag, make sure that the parameter 'allowScriptAccess' is set to 'always'. " + e.message);
				else
					ErrorManager.reportError(e);
			}
		}
		
		/**
		 * @private
		 */
		private static function generateExternalInterfaceCallback(instance:Object, methodInfo:Object):void
		{
			var method:Function = instance[methodInfo.name] as Function;
			// find the number of required parameters
			var paramCount:int = 0;
			while (paramCount < method.length && !methodInfo.parameters[paramCount].optional)
				paramCount++;
			function callback(...args):*
			{
				if (args.length < paramCount)
					args.length = paramCount;
				return method.apply(null, args);
			}
			ExternalInterface.addCallback(methodInfo.name, callback);
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
			return _implementationDisplayNames[theImplementation] as String;
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
					trace(e.message);
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
		
		public static function externalTrace(...params):void
		{
			params.unshift('console.log');
			ExternalInterface.call.apply(null, params);
		}
	}
}
