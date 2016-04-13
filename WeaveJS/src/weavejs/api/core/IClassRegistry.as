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

package weavejs.api.core
{
	public interface IClassRegistry
	{
		/**
		 * Registers a class under a given qualified name and adds metadata about implementing interfaces.
		 * @param definition The class definition.
		 * @param qualifiedName The qualified class name under which to register the class definition.
		 * @param interfaces An Array of Class objects that are the interfaces the class implements.
		 * @param displayName An optional display name for the class definition.
		 */
		function registerClass(definition:Class, qualifiedName:String, interfaces:Array = null, displayName:String = null):void;
		
		/**
		 * Gets the qualified class name from a class definition or an object instance.
		 */
		function getClassName(definition:Object):String;
		
		/**
		 * Looks up a static definition by name.
		 */
		function getDefinition(name:String):*;
		
		/**
		 * Gets FlexJS class info.
		 * @param class_or_instance Either a Class or an instance of a Class.
		 * @return FlexJS class info object containing properties "variables", "accessors", and "methods",
		 *         each being an Array of Objects like {type:String, declaredBy:String}
		 */
		function getClassInfo(class_or_instance:Object):/*/{
				variables: {[name:string]:{type: string}}[],
				accessors: {[name:string]:{type: string, declaredBy: string}}[],
				methods: {[name:string]:{type: string, declaredBy: string}}[]
			}/*/Object;
		
		/**
		 * Registers an implementation of an interface to be used as a singleton.
		 * @param theInterface The interface to register.
		 * @param theImplementation The implementation to register.
		 * @return A value of true if the implementation was successfully registered.
		 */
		function registerSingletonImplementation(theInterface:Class, theImplementation:Class):Boolean;
		
		/**
		 * Gets the registered implementation of an interface.
		 * @param theInterface An interface to a singleton class.
		 * @return The registered implementation Class for the given interface Class.
		 */
		function getSingletonImplementation(theInterface:Class):Class;
		
		/**
		 * This function returns the singleton instance for a registered interface.
		 *
		 * This method should not be called at static initialization time,
		 * because the implementation may not have been registered yet.
		 * 
		 * @param theInterface An interface to a singleton class.
		 * @return The singleton instance that implements the specified interface.
		 */
		function getSingletonInstance(theInterface:Class):*;
		
		/**
		 * This will register an implementation of an interface.
		 * @param theInterface The interface class.
		 * @param theImplementation An implementation of the interface.
		 * @param displayName An optional display name for the implementation.
		 */
		function registerImplementation(theInterface:Class, theImplementation:Class, displayName:String = null):void;
		
		/**
		 * This will get an Array of class definitions that were previously registered as implementations of the specified interface.
		 * @param theInterface The interface class.
		 * @return An Array of class definitions that were previously registered as implementations of the specified interface.
		 */
		function getImplementations(theInterface:Class):Array;
		
		/**
		 * This will get the displayName that was specified when an implementation was registered with registerImplementation().
		 * @param theImplementation An implementation that was registered with registerImplementation().
		 * @return The display name for the implementation.
		 */
		function getDisplayName(theImplementation:Class):String;
	}
}
