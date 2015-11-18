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
	import weavejs.path.WeavePath;

	/**
	 * This interface is a set of functions intended to be exposed as an external JavaScript API.
	 * 
	 * The user interface in Weave is initially generated from a saved session state.
	 * User interactions affect the session state, and changes in the session state affect
	 * the display at runtime.  The API provides a window into the session state so most
	 * interactions that can be made through the GUI can also be made through JavaScript calls.
	 * 
	 * @author adufilie
	 */
	public interface IExternalSessionStateInterface
	{
//		/**
//		 * This function gets the current session state of a linkable object.  Nested XML objects will be converted to Strings before returning.
//		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
//		 *                   A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
//		 * @return An object containing the values from the sessioned properties.
//		 */
//		function getSessionState(path:WeavePath):Object;
//		
//		/**
//		 * This function updates the current session state of an object.
//		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
//		 *                   A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
//		 * @param newState An object containing the new values for sessioned properties in the sessioned object.
//		 * @param removeMissingDynamicObjects If true, this will remove any properties from an ILinkableCompositeObject that do not appear in the new session state.
//		 * @return true if objectPath refers to an existing object in the session state.
//		 */
//		function setSessionState(path:WeavePath, newState:Object, removeMissingObjects:Boolean = true):Boolean;
//
//		/**
//		 * This function will get the qualified class name of an object appearing in the session state.
//		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
//		 *                   A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
//		 * @return The qualified class name of the object referred to by objectPath, or null if there is no object.
//		 */
//		function getObjectType(path:WeavePath):String;
//
//		/**
//		 * This function gets a list of names of children of an object appearing in the session state.
//		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
//		 *                   A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
//		 * @return An Array of names of sessioned children of the object referred to by objectPath.
//		 */
//		function getChildNames(path:WeavePath):Array;
//
//		/**
//		 * This function will reorder children of an object implementing ILinkableHashMap.
//		 * @param hashMapPath A sequence of child names used to refer to an object appearing in the session state.
//		 *                   A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
//		 * @param orderedChildNames The new order to use for the children of the object specified by objectPath.
//		 * @return true if objectPath refers to the location of an ILinkableHashMap.
//		 */
//		function setChildNameOrder(hashMapPath:WeavePath, orderedChildNames:Array):Boolean;
//
//		/**
//		 * This function will dynamically create an object at the specified location in the session state if its parent implements
//		 * ILinkableCompositeObject.  If the object at the specified location already exists and is of the requested type,
//		 * this function does nothing.
//		 * If the parent of the dynamic object to be created implements ILinkableHashMap, a value of null for the child name
//		 * will cause a new name to be generated.
//		 * If the parent of the dynamic object to be created implements ILinkableDynamicObject, the name of the child refers to
//		 * the name of a static object appearing at the top level of the session state.  A child name equal to null in this case
//		 * will create a local object that does not appear at the top level of the session state.
//		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
//		 *                   A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
//		 * @param objectType The qualified name of a class implementing ILinkableObject.
//		 * @return true if, after calling this function, an object of the requested type exists at the requested location.
//		 */
//		function requestObject(path:WeavePath, objectType:String):Boolean;
//
//		/**
//		 * This function will remove a dynamically created object if it is the child of an ILinkableCompositeObject.
//		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
//		 *                   A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
//		 * @return true if objectPath refers to a valid location where dynamically created objects can exist.
//		 */
//		function removeObject(path:WeavePath):Boolean;
//
//		/**
//		 * This function will add a callback to an ILinkableObject.
//		 * @param scopeObjectPathOrVariableName A sequence of child names used to refer to an object appearing in the session state, or the name of a previously saved expression result.
//		 * @param callback The callback function.
//		 * @param triggerCallbackNow If this is set to true, the callback will be triggered after it is added.
//		 * @param immediateMode If this is set to true, addImmediateCallback() will be used.  Otherwise, addGroupedCallback() will be used.
//		 * @param delayWhileBusy Specifies whether to delay the callback while the object is busy.
//		 * @return true if successful.
//		 * @see weave.api.core.ICallbackCollection#addGroupedCallback
//		 */
//		function addCallback(path:WeavePath, callback:Function, triggerCallbackNow:Boolean = false, immediateMode:Boolean = false, delayWhileBusy:Boolean = true):Boolean;
//		
//		/**
//		 * This function will remove a callback that was previously added.
//		 * @param scopeObjectPathOrVariableName A sequence of child names used to refer to an object appearing in the session state, or the name of a previously saved expression result.
//		 * @param callback The callback function.
//		 * @param everywhere If set to true, removes the callback from every object to which it was added.
//		 * @return true if successful.
//		 */
//		function removeCallback(path:WeavePath, callback:Function, everywhere:Boolean = false):Boolean;
//		
//		/**
//		 * This function will remove all callbacks that were previously added using addCallback().
//		 * You may want to call this before calling loadFile() to prevent unwanted behavior due to scripts previously executed.
//		 */
//		function removeAllCallbacks():void;
	}
}
