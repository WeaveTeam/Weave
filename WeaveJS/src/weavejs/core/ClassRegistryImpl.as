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
	import weavejs.api.core.IClassRegistry;
	import weavejs.util.JS;
	
	/**
	 * Manages a set of implementations of interfaces.
	 */
	public class ClassRegistryImpl implements IClassRegistry
	{
		public function ClassRegistryImpl()
		{
		}
		
		/**
		 * interface Class -&gt; singleton implementation instance.
		 */
		public const map_interface_singletonInstance:Object = new JS.Map();
		
		/**
		 * interface Class -&gt; implementation Class
		 */
		public const map_interface_singletonImplementation:Object = new JS.Map();
		
		/**
		 * interface Class -&gt; Array&lt;implementation Class&gt;
		 */
		public const map_interface_implementations:Object = new JS.Map();
		
		/**
		 * implementation Class -&gt; String
		 */
		public const map_class_displayName:Object = new JS.Map();
		
		/**
		 * qualifiedName:String -> definition:Class
		 */
		public const map_name_class:Object = new JS.Map();
		
		/**
		 * definition:Class -> qualifiedName:String
		 */
		public const map_class_name:Object = new JS.Map();
		
		/**
		 * An Array of default packages to check when looking up a class by name.
		 */
		public const defaultPackages:Array = [];
		
		private static const FLEXJS_CLASS_INFO:String = "FLEXJS_CLASS_INFO";
		
		/**
		 * Registers a class for use with Weave.className() and Weave.getDefinition().
		 */
		public function registerClass(qualifiedName:String, definition:Class, interfaces:Array = null):void
		{
			map_name_class.set(qualifiedName, definition);
			if (!map_class_name.has(definition))
				map_class_name.set(definition, qualifiedName);
			
			if (!definition.prototype[FLEXJS_CLASS_INFO])
				definition.prototype[FLEXJS_CLASS_INFO] = {
					names: [{ name: shortName, qName: qualifiedName}],
					interfaces: interfaces || []
				};
			
			var shortName:String = qualifiedName.split('.').pop().split(':').pop();
			if (shortName != qualifiedName)
				registerClass(shortName, definition);
		}
		
		/**
		 * Gets the qualified class name from a class definition or an object instance.
		 */
		public function getClassName(definition:Object):String
		{
			if (!definition)
				return null;
			
			if (!definition.prototype)
				definition = definition.constructor;
			
			if (definition.prototype && definition.prototype[FLEXJS_CLASS_INFO])
				return definition.prototype[FLEXJS_CLASS_INFO].names[0].qName;
			
			if (map_class_name.has(definition))
				return map_class_name.get(definition);
			
			return definition.name;
		}
		
		/**
		 * Looks up a static definition by name.
		 */
		public function getDefinition(name:String):*
		{
			if (!name)
				return undefined;
			
			var def:* = JS.global;
			var names:Array = name.split('.');
			for each (var key:String in names)
			{
				if (def !== undefined)
					def = def[key];
				else
					break;
			}
			if (def)
				return def;
			
			if (names.length == 1)
			{
				for each (var pkg:String in defaultPackages)
				{
					def = getDefinition(pkg + '.' + name);
					if (def)
						return def;
				}
			}
			
			def = map_name_class.get(name);
			if (def)
				return def;
			
			if (name.indexOf("::") > 0)
				return getDefinition(name.split('::').pop());
		}
		
		/**
		 * This registers an implementation for a singleton interface.
		 * @param theInterface The interface to register.
		 * @param theImplementation The implementation to register.
		 * @return A value of true if the implementation was successfully registered.
		 */
		public function registerSingletonImplementation(theInterface:Class, theImplementation:Class):Boolean
		{
			if (!map_interface_singletonImplementation.get(theInterface))
			{
				verifyImplementation(theInterface, theImplementation);
				map_interface_singletonImplementation.set(theInterface, theImplementation);
			}
			return map_interface_singletonImplementation.get(theInterface) == theImplementation;
		}
		
		/**
		 * Gets the registered implementation of an interface.
		 * @return The registered implementation Class for the given interface Class.
		 */
		public function getSingletonImplementation(theInterface:Class):Class
		{
			return map_interface_singletonImplementation.get(theInterface);
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
			if (!map_interface_singletonInstance.get(theInterface))
			{
				var classDef:Class = getSingletonImplementation(theInterface);
				if (classDef)
					map_interface_singletonInstance.set(theInterface, new classDef());
			}
			
			return map_interface_singletonInstance.get(theInterface);
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
			
			var array:Array = map_interface_implementations.get(theInterface);
			if (!array)
				map_interface_implementations.set(theInterface, array = []);
			
			// overwrite existing displayName if specified
			if (displayName || !map_class_displayName.get(theImplementation))
				map_class_displayName.set(theImplementation, displayName || getClassName(theImplementation).split(':').pop());
			
			if (array.indexOf(theImplementation) < 0)
			{
				array.push(theImplementation);
				// sort by displayName
				array.sort(compareDisplayNames);
			}
		}
		
		/**
		 * This will get an Array of class definitions that were previously registered as map_interface_implementations of the specified interface.
		 * @param theInterface The interface class.
		 * @return An Array of class definitions that were previously registered as map_interface_implementations of the specified interface.
		 */
		public function getImplementations(theInterface:Class):Array
		{
			var array:Array = map_interface_implementations.get(theInterface);
			return array ? array.concat() : [];
		}
		
		/**
		 * This will get the displayName that was specified when an implementation was registered with registerImplementation().
		 * @param theImplementation An implementation that was registered with registerImplementation().
		 * @return The display name for the implementation.
		 */
		public function getDisplayName(theImplementation:Class):String
		{
			var str:String = map_class_displayName.get(theImplementation);
			return str;// && lang(str);
		}
		
		/**
		 * @private
		 * sort by displayName
		 */
		private function compareDisplayNames(impl1:Class, impl2:Class):int
		{
			var name1:String = map_class_displayName.get(impl1);
			var name2:String = map_class_displayName.get(impl2);
			if (name1 < name2)
				return -1;
			if (name1 > name2)
				return 1;
			return 0;
		}
		
		/**
		 * Verifies that a Class implements an interface.
		 */
		public function verifyImplementation(theInterface:Class, theImplementation:Class):void
		{
			if (!(theImplementation.prototype is theInterface))
				throw new Error(getClassName(theImplementation) + ' does not implement ' + getClassName(theInterface));
		}
	}
}
