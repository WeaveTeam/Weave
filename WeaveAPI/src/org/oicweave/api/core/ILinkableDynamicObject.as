/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Weave API.
 *
 * The Initial Developer of the Original Code is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2011
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

package org.oicweave.api.core
{
	/**
	 * This is an interface for a wrapper around a dynamically created ILinkableObject.
	 * 
	 * @author adufilie
	 */
	public interface ILinkableDynamicObject extends ILinkableCompositeObject
	{
		/**
		 * This function will copy the session state of an ILinkableObject to the local internalObject.
		 * @param objectToCopy An object to copy the session state from.
		 */
		function copyLocalObject(objectToCopy:ILinkableObject):void;

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
