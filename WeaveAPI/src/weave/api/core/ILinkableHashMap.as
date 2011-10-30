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

package weave.api.core
{
	/**
	 * This is the interface for an ordered list of name-to-object mappings.
	 * 
	 * @author adufilie
	 */
	public interface ILinkableHashMap extends ILinkableCompositeObject
	{
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
		function setNameOrder(newOrder:Array):void;

		/**
		 * This function returns an ordered list of names in the hash map.
		 * @param filter If specified, names of objects that are not of this type will be filtered out.
		 * @return A copy of the ordered list of names of objects contained in this LinkableHashMap.
		 */
		function getNames(filter:Class = null):Array;
		
		/**
		 * This function returns an ordered list of objects in the hash map. 
		 * @param filter If specified, objects that are not of this type will be filtered out.
		 * @return An ordered Array of objects that correspond to the names returned by getNames(filter).
		 */
		function getObjects(filter:Class = null):Array;

		/**
		 * This function gets the name of the specified object in the hash map.
		 * @param object An object contained in this LinkableHashMap.
		 * @return The name associated with the object, or null if the object was not found. 
		 */
		function getName(object:ILinkableObject):String;

		/**
		 * This function gets the object associated with the specified name.
		 * @param name The identifying name to associate with an object.
		 * @return The object associated with the given name.
		 */
		function getObject(name:String):ILinkableObject;

		/**
		 * This function creates an object in the hash map if it doesn't already exist.
		 * If there is an existing object associated with the specified name, it will be kept if it
		 * is the specified type, or replaced with a new instance of the specified type if it is not.
		 * @param name The identifying name of a new or existing object.
		 * @param classDef The Class of the desired object type.
		 * @param lockObject If this is true, the object will be locked in place under the specified name.
		 * @return The object under the requested name of the requested type, or null if an error occurred.
		 */
		function requestObject(name:String, classDef:Class, lockObject:Boolean):*;

		/**
		 * This function will call lockObject() on all objects in this LinkableHashMap.
		 * The LinkableHashMap will also be locked so that no new objects can be initialized.
		 */
		function lock():void;

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
		 * This will generate a new name for an object that is different from all the names of objects in this LinkableHashMap.
		 * @param baseName The name to start with.  If the name is already in use, an integer will be appended to create a unique name.
		 */
		function generateUniqueName(baseName:String):String;
	}
}
