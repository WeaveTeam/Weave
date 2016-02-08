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

package weave.api.core
{
	public interface IClassRegistry
	{
		/**
		 * Registers an implementation of an interface to be used as a singleton.
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
