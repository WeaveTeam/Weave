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

package weave.api.core
{
	/**
	 * This is an interface for a wrapper around a dynamically created ILinkableObject.
	 * 
	 * @author adufilie
	 */
	public interface ILinkableDynamicObject extends ILinkableCompositeObject
	{
		/**
		 * This function gets the internal object, whether local or global.
		 * @return The internal, dynamically created object.
		 */
		function get internalObject():ILinkableObject;
		/**
		 * This is the name of the linked global object, or null if the internal object is local.
		 */
		function get globalName():String;

		/**
		 * This function will change the internalObject if the new globalName is different, unless this object is locked.
		 * If a new global name is given, the session state of the new global object will take precedence.
		 * @param newGlobalName This is the name of the global object to link to, or null to unlink from the current global object.
		 */
		function set globalName(newGlobalName:String):void;

		/**
		 * This function creates a global object using the given Class definition if it doesn't already exist.
		 * If the object gets disposed of later, this object will still be linked to the global name.
		 * If the existing object under the specified name is locked, this function will not modify it.
		 * @param name The name of the global object to link to.
		 * @param objectType The Class used to initialize the object.
		 * @param lockObject If this is true, this object will be locked so the internal object cannot be removed or replaced.
		 * @return The global object of the requested name and type, or null if the object could not be created.
		 */
		function requestGlobalObject(name:String, objectType:Class, lockObject:Boolean):*;
		
		/**
		 * This function creates a local object using the given Class definition if it doesn't already exist.
		 * If this object is locked, this function does nothing.
		 * @param objectType The Class used to initialize the object.
		 * @param lockObject If this is true, this object will be locked so the internal object cannot be removed or replaced.
		 * @return The local object of the requested type, or null if the object could not be created.
		 */
		function requestLocalObject(objectType:Class, lockObject:Boolean):*;

		/**
		 * This function will copy the session state of an ILinkableObject to a new local internalObject of the same type.
		 * @param objectToCopy An object to copy the session state from.
		 */
		function requestLocalObjectCopy(objectToCopy:ILinkableObject):void;

		/**
		 * This function will lock the internal object in place so it will not be removed.
		 */
		function lock():void;

		/**
		 * If the internal object is local, this will remove the object (unless it is locked).
		 * If the internal object is global, this will remove the link to it.
		 */
		function removeObject():void;
	}
}
