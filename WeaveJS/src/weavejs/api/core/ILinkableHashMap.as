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
	/**
	 * Allows dynamically creating instances of objects implementing ILinkableObject at runtime.
	 * The session state is an Array of DynamicState objects.
	 * @see weave.core.DynamicState
	 * 
	 * @author adufilie
	 */
	public interface ILinkableHashMap extends ILinkableCompositeObject
	{
		/**
		 * The child type restriction, or null if there is none.
		 */
		function get typeRestriction():Class;
		
		/**
		 * This is an interface for adding and removing callbacks that will get triggered immediately
		 * when an object is added or removed.
		 * @return An interface for adding callbacks that get triggered when the list of child objects changes.
		 */
		function get childListCallbacks():IChildListCallbackInterface;
		
		/**
		 * This will reorder the names returned by getNames().
		 * Any names appearing in newOrder that do not appear in getNames() will be ignored.
		 * Callbacks will be called if the new name order differs from the old order.
		 * @param newOrder The new desired ordering of names.
		 */
		function setNameOrder(newOrder:Array/*/<string>/*/):void;

		/**
		 * This function returns an ordered list of names in the hash map.
		 * @param filter If specified, names of objects that are not of this type will be filtered out.
		 * @param filterIncludesPlaceholders If true, matching LinkablePlaceholders will be included in the results.
		 * @return A copy of the ordered list of names of objects contained in this LinkableHashMap.
		 */
		function getNames(filter:/*/new(..._:any[])=>any | string/*/Class = null, filterIncludesPlaceholders:Boolean = false):Array/*/<string>/*/;
		
		/**
		 * This function returns an ordered list of objects in the hash map. 
		 * @param filter If specified, objects that are not of this type will be filtered out.
		 * @param filterIncludesPlaceholders If true, matching LinkablePlaceholders will be included in the results.
		 * @return An ordered Array of objects that correspond to the names returned by getNames(filter).
		 */
		function getObjects/*/<T>/*/(filter:/*/new(..._:any[])=>T | string/*/Class = null, filterIncludesPlaceholders:Boolean = false):Array/*/<T & ILinkableObject>/*/;

		/**
		 * This function gets the name of the specified object in the hash map.
		 * @param object An object contained in this LinkableHashMap.
		 * @return The name associated with the object, or null if the object was not found. 
		 */
		function getName(object:ILinkableObject):String;

		/**
		 * This function gets the object associated with the specified name.
		 * @param name The name identifying an object in the hash map.
		 * @return The object associated with the given name.
		 */
		function getObject(name:String):ILinkableObject;
		
		/**
		 * Sets an entry in the hash map, replacing any existing object under the same name.
		 * @param name The identifying name to associate with an object.
		 * @param lockObject If this is true, the object will be locked in place under the specified name.
		 * @return The object to be associated with the given name.
		 */
		function setObject(name:String, object:ILinkableObject, lockObject:Boolean = false):void;

		/**
		 * This function creates an object in the hash map if it doesn't already exist.
		 * If there is an existing object associated with the specified name, it will be kept if it
		 * is the specified type, or replaced with a new instance of the specified type if it is not.
		 * @param name The identifying name of a new or existing object.
		 * @param classDef The Class of the desired object type.
		 * @param lockObject If this is true, the object will be locked in place under the specified name.
		 * @return The object under the requested name of the requested type, or null if an error occurred.
		 */
		function requestObject/*/<T>/*/(name:String, classDef:/*/new(..._:any[])=>T | string/*/Class, lockObject:Boolean = false):/*/T/*/*;

		/**
		 * This function will copy the session state of an ILinkableObject to a new object under the given name in this LinkableHashMap.
		 * @param newName A name for the object to be initialized in this LinkableHashMap.
		 * @param objectToCopy An object to copy the session state from.
		 * @return The new object of the same type, or null if an error occurred.
		 */
		function requestObjectCopy/*/<T extends ILinkableObject>/*/(name:String, objectToCopy:/*/T/*/ILinkableObject):/*/T/*/ILinkableObject;

		/**
		 * This function will rename an object by making a copy and removing the original.
		 * @param oldName The name of an object to replace.
		 * @param newName The new name to use for the copied object.
		 * @return The copied object associated with the new name, or the original object if newName is the same as oldName.
		 */
		function renameObject(oldName:String, newName:String):ILinkableObject;
		
		/**
		 * This function will return true if the specified object was previously locked.
		 * @param name The name of an object.
		 */
		function objectIsLocked(name:String):Boolean;

		/**
		 * This function removes an object from the hash map.
		 * @param name The identifying name of an object previously saved with setObject().
		 */
		function removeObject(name:String):void;

		/**
		 * This function attempts to removes all objects from this LinkableHashMap.
		 * Any objects that are locked will remain.
		 */
		function removeAllObjects():void;

		/**
		 * This will generate a new name for an object that is different from all the names of objects previously used in this LinkableHashMap.
		 * @param baseName The name to start with.  If the name is already in use, an integer will be appended to create a unique name.
		 */
		function generateUniqueName(baseName:String):String;
	}
}
