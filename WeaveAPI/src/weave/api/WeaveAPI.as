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
	import flash.external.ExternalInterface;
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import mx.core.Singleton;
	
	import weave.api.core.IErrorManager;
	import weave.api.core.IExternalSessionStateInterface;
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
		MXClasses; // Referencing this allows all Flex classes to be dynamically created at runtime.
		
		/**
		 * For use with StageUtils.startTask(); this priority is associated with rendering.
		 */		
		public static const TASK_PRIORITY_RENDERING:int = 1;
		/**
		 * For use with StageUtils.startTask(); this priority is associated with data manipulation tasks such as building an index.
		 */
		public static const TASK_PRIORITY_BUILDING:int = 2;
		/**
		 * For use with StageUtils.startTask(); this priority is associated with parsing raw data.
		 */
		public static const TASK_PRIORITY_PARSING:int = 3;
		
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
		/**************************************/

		
		/**
		 * This returns the top level application as defined by FlexGlobals.topLevelApplication
		 * or Application.application if FlexGlobals isn't defined.
		 */
		public static function get topLevelApplication():Object
		{
			//TODO: Application.application is deprecated
			/*try {
			return FlexGlobals.topLevelApplication;
			} catch (e:Error) { }*/
			
			return getDefinitionByName('mx.core.Application').application;
		}
		
		
		/**
		 * This function will initialize the external interfaces so calls can be made from JavaScript to Weave.
		 * After initializing, this will call an external function weaveReady(weave) if it exists, where the
		 * 'weave' parameter is a pointer to the instance of Weave that is ready.
		 */
		public static function initializeExternalInterface():void
		{
			try
			{
				var interfaces:Array = [IExternalSessionStateInterface]; // add more interfaces here if necessary
				for each (var theInterface:Class in interfaces)
				{
					var classInfo:XML = describeType(theInterface);
					// add a callback for each external interface function
					for each (var methodName:String in classInfo.factory.method.@name)
					{
						ExternalInterface.addCallback(methodName, generateExternalInterfaceCallback(methodName, theInterface));
					}
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
					ErrorManager.reportError(e, "In the HTML embedded object tag, make sure that the parameter 'allowScriptAccess' is set properly.");
				else
					ErrorManager.reportError(e);
			}
		}
		
		/**
		 * @private 
		 */
		private static function generateExternalInterfaceCallback(methodName:String, theInterface:Class):Function
		{
			return function (...args):* {
				var instance:Object = getSingletonInstance(theInterface);
				return (instance[methodName] as Function).apply(null, args);
			}
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
			
			_implementationDisplayNames[theImplementation] = displayName || getQualifiedClassName(theImplementation).split(':').pop();
			if (array.indexOf(theImplementation) < 0)
			{
				array.push(theImplementation);
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
			var classInfo:XML = describeType(theImplementation);
			if (classInfo.factory.implementsInterface.(@type == interfaceName).length() == 0)
				throw new Error(getQualifiedClassName(theImplementation) + ' does not implement ' + theInterface);
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
			var result:* = _singletonDictionary[singletonInterface];
			// If no instance has been created yet, create one now.
			if (!result)
			{
				var interfaceName:String = getQualifiedClassName(singletonInterface);
				try
				{
					// This may fail if there is no registered class,
					// or the class doesn't have a getInstance() method.
					return Singleton.getInstance(interfaceName);
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
		 * This is used to save a mapping from an interface to its singleton implementation instance.
		 */
		private static const _singletonDictionary:Dictionary = new Dictionary();
	}
}
