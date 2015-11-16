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

package weavejs.core
{
	import weavejs.Weave;
	import weavejs.api.core.IClassRegistry;
	import weavejs.utils.Utils;
	
	/**
	 * Manages a set of implementations of interfaces.
	 */
	public class ClassRegistryImpl implements IClassRegistry
	{
		public function ClassRegistryImpl()
		{
			this.singletonInstances = new Utils.Map();
			this.singletonImplementations = new Utils.Map();
			this.implementations = new Utils.Map();
			this.displayNames = new Utils.Map();
		}
		
		/**
		 * interface Class -&gt; singleton implementation instance.
		 */
		public var singletonInstances:Object;
		
		/**
		 * interface Class -&gt; implementation Class
		 */
		public var singletonImplementations:Object;
		
		/**
		 * interface Class -&gt; Array&lt;implementation Class&gt;
		 */
		public var implementations:Object;
		
		/**
		 * implementation Class -&gt; String
		 */
		public var displayNames:Object;
		
		/**
		 * This registers an implementation for a singleton interface.
		 * @param theInterface The interface to register.
		 * @param theImplementation The implementation to register.
		 * @return A value of true if the implementation was successfully registered.
		 */
		public function registerSingletonImplementation(theInterface:Class, theImplementation:Class):Boolean
		{
			if (!singletonImplementations.get(theInterface))
			{
				verifyImplementation(theInterface, theImplementation);
				singletonImplementations.set(theInterface, theImplementation);
			}
			return singletonImplementations.get(theInterface) == theImplementation;
		}
		
		/**
		 * Gets the registered implementation of an interface.
		 * @return The registered implementation Class for the given interface Class.
		 */
		public function getSingletonImplementation(theInterface:Class):Class
		{
			return singletonImplementations.get(theInterface);
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
			if (!singletonInstances.get(theInterface))
			{
				var classDef:Class = getSingletonImplementation(theInterface);
				if (classDef)
					singletonInstances.set(theInterface, new classDef());
			}
			
			return singletonInstances.get(theInterface);
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
			
			var array:Array = implementations.get(theInterface);
			if (!array)
				implementations.set(theInterface, array = []);
			
			// overwrite existing displayName if specified
			if (displayName || !displayNames.get(theImplementation))
				displayNames.set(theImplementation, displayName || Weave.className(theImplementation).split(':').pop());
			
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
			var array:Array = implementations.get(theInterface);
			return array ? array.concat() : [];
		}
		
		/**
		 * This will get the displayName that was specified when an implementation was registered with registerImplementation().
		 * @param theImplementation An implementation that was registered with registerImplementation().
		 * @return The display name for the implementation.
		 */
		public function getDisplayName(theImplementation:Class):String
		{
			var str:String = displayNames.get(theImplementation);
			return str;// && lang(str);
		}
		
		/**
		 * @private
		 * sort by displayName
		 */
		private function _sortImplementations(impl1:Class, impl2:Class):int
		{
			var name1:String = displayNames.get(impl1);
			var name2:String = displayNames.get(impl2);
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
			if (!theImplementation.prototype is theInterface)
				throw new Error(Weave.className(theImplementation) + ' does not implement ' + Weave.className(theInterface));
		}
	}
}
