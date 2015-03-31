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
	/**
	 * Dynamic state objects have three properties: objectName, className, sessionState
	 * 
	 * @author adufilie
	 */
	public class DynamicState
	{
		/**
		 * Creates an Object having three properties: objectName, className, sessionState
		 * @param objectName The name assigned to the object when the session state is generated.
		 * @param className The qualified class name of the original object providing the session state.
		 * @param sessionState The session state for an object of the type specified by className.
		 */
		public static function create(objectName:String = null, className:String = null, sessionState:Object = null):Object
		{
			var obj:Object = {};
			// convert empty strings ("") to null
			obj[OBJECT_NAME] = objectName || null;
			obj[CLASS_NAME] = className || null;
			obj[SESSION_STATE] = sessionState;
			return obj;
		}
		
		/**
		 * The name of the property containing the name assigned to the object when the session state is generated.
		 */
		public static const OBJECT_NAME:String = 'objectName';
		
		/**
		 * The name of the property containing the qualified class name of the original object providing the session state.
		 */
		public static const CLASS_NAME:String = 'className';
		
		/**
		 * The name of the property containing the session state for an object of the type specified by className.
		 */
		public static const SESSION_STATE:String = 'sessionState';
		
		/**
		 * This function can be used to detect dynamic state objects within nested, untyped session state objects.
		 * This function will check if the given object has the three properties of a dynamic state object.
		 * @param object An object to check.
		 * @return true if the object has all three properties and no extras.
		 */
		public static function isDynamicState(object:Object):Boolean
		{
			var matchCount:int = 0;
			for (var name:* in object)
			{
				if (name === OBJECT_NAME || name === CLASS_NAME || name === SESSION_STATE)
					matchCount++;
				else
					return false;
			}
			return (matchCount == 3); // must match all three properties with no extras
		}
		
		/**
		 * This function checks whether or not a session state is an Array containing at least one
		 * object that looks like a DynamicState and has no other non-String items.
		 * @return A value of true if the Array looks like a dynamic session state or diff.
		 */
		public static function isDynamicStateArray(state:*):Boolean
		{
			var array:Array = state as Array;
			if (!array)
				return false;
			var result:Boolean = false;
			for each (var item:* in array)
			{
				if (item is String)
					continue; // dynamic state diffs can contain String values.
				if (isDynamicState(item))
					result = true;
				else
					return false;
			}
			return result;
		}
	}
}
