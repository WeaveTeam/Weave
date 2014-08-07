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

package weave.core
{
	import avmplus.DescribeType;
	
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import weave.api.core.IClassRegistry;
	
	/**
	 * Manages a set of implementations of interfaces.
	 */
	public class ClassRegistryImpl implements IClassRegistry
	{
		public function ClassRegistryImpl()
		{
			try
			{
				MX_Singleton = getDefinitionByName('mx.core.Singleton');
			}
			catch (e:Error)
			{
				// it doesn't matter if it failed - we have backup functionality
			}
		}
		
		/**
		 * mx.core.Singleton
		 */
		private var MX_Singleton:Object;
		
		/**
		 * interface Class -&gt; singleton implementation instance.
		 */
		public const singletonInstances:Dictionary = new Dictionary();
		
		/**
		 * interface Class -&gt; implementation Class
		 */
		public const singletonImplementations:Dictionary = new Dictionary();
		
		/**
		 * interface Class -&gt; Array<implementation Class>
		 */
		public const implementations:Dictionary = new Dictionary();
		
		/**
		 * implementation Class -&gt; String
		 */
		public const displayNames:Dictionary = new Dictionary();
		
		/**
		 * This registers an implementation for a singleton interface.
		 * @param theInterface The interface to register.
		 * @param theImplementation The implementation to register.
		 * @return A value of true if the implementation was successfully registered.
		 */
		public function registerSingletonImplementation(theInterface:Class, theImplementation:Class):Boolean
		{
			if (!singletonImplementations[theInterface])
			{
				verifyImplementation(theInterface, theImplementation);
				singletonImplementations[theInterface] = theImplementation;
				
				// let mx.core.Singleton take precedence if it is available
				if (MX_Singleton)
				{
					try
					{
						var interfaceName:String = getQualifiedClassName(theInterface);
						MX_Singleton['registerClass'](interfaceName, theImplementation);
						singletonImplementations[theInterface] = MX_Singleton['getClass'](interfaceName);
					}
					catch (e:Error)
					{
						// registerClass() and getClass() should not have failed, so give up on MX_Singleton
						MX_Singleton = null;
						trace(e.getStackTrace());
					}
				}
			}
			return singletonImplementations[theInterface] == theImplementation;
		}
		
		/**
		 * Gets the registered implementation of an interface.
		 * @return The registered implementation Class for the given interface Class.
		 */
		public function getSingletonImplementation(theInterface:Class):Class
		{
			if (!singletonImplementations[theInterface] && MX_Singleton)
			{
				try
				{
					var interfaceName:String = getQualifiedClassName(theInterface);
					singletonImplementations[theInterface] = MX_Singleton['getClass'](interfaceName);
				}
				catch (e:Error)
				{
					// getClass() should not have failed, so give up on MX_Singleton
					MX_Singleton = null;
					trace(e.getStackTrace());
				}
			}
			return singletonImplementations[theInterface];
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
		public function getSingletonInstance(theInterface:Class):*
		{
			if (!singletonInstances[theInterface])
			{
				if (MX_Singleton)
				{
					try
					{
						var interfaceName:String = getQualifiedClassName(theInterface);
						// This may fail if there is no registered class,
						// or the class doesn't have a getInstance() method.
						return singletonInstances[theInterface] = MX_Singleton['getInstance'](interfaceName);
					}
					catch (e:Error)
					{
						if (!getSingletonImplementation(theInterface))
							throw e; // no class registered for interface
					}
				}
				
				var classDef:Class = getSingletonImplementation(theInterface);
				if (classDef)
					singletonInstances[theInterface] = new classDef();
			}
			
			return singletonInstances[theInterface];
		}
		
		/**
		 * This will register an implementation of an interface.
		 * @param theInterface The interface class.
		 * @param theImplementation An implementation of the interface.
		 * @param displayName An optional display name for the implementation.
		 */
		public function registerImplementation(theInterface:Class, theImplementation:Class, displayName:String = null):void
		{
			verifyImplementation(theInterface, theImplementation);
			
			var array:Array = implementations[theInterface] as Array;
			if (!array)
				implementations[theInterface] = array = [];
			
			// overwrite existing displayName if specified
			if (displayName || !displayNames[theImplementation])
				displayNames[theImplementation] = displayName || getQualifiedClassName(theImplementation).split(':').pop();
			
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
		public function getImplementations(theInterface:Class):Array
		{
			var array:Array = implementations[theInterface] as Array;
			return array ? array.concat() : [];
		}
		
		/**
		 * This will get the displayName that was specified when an implementation was registered with registerImplementation().
		 * @param theImplementation An implementation that was registered with registerImplementation().
		 * @return The display name for the implementation.
		 */
		public function getDisplayName(theImplementation:Class):String
		{
			var str:String = displayNames[theImplementation] as String;
			return str && lang(str);
		}
		
		/**
		 * @private
		 * sort by displayName
		 */
		private function _sortImplementations(impl1:Class, impl2:Class):int
		{
			var name1:String = displayNames[impl1] as String;
			var name2:String = displayNames[impl2] as String;
			if (name1 < name2)
				return -1;
			if (name1 > name2)
				return 1;
			return 0;
		}
		
		/**
		 * Verifies that a Class implements an interface.
		 */
		public static function verifyImplementation(theInterface:Class, theImplementation:Class):void
		{
			var interfaceName:String = getQualifiedClassName(theInterface);
			var classInfo:Object = DescribeType.getInfo(theImplementation, DescribeType.INCLUDE_TRAITS | DescribeType.INCLUDE_INTERFACES | DescribeType.USE_ITRAITS);
			if (classInfo.traits.interfaces.indexOf(interfaceName) < 0)
				throw new Error(getQualifiedClassName(theImplementation) + ' does not implement ' + interfaceName);
		}
	}
}
