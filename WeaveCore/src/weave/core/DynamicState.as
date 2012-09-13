/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package weave.core
{
	import flash.net.registerClassAlias;
	import flash.utils.getQualifiedClassName;

	/**
	 * This contains a session state object plus some metadata: objectName and className.
	 * 
	 * @author adufilie
	 */
	public class DynamicState
	{
		public function DynamicState(objectName:String = null, className:String = null, sessionState:* = null)
		{
			this.objectName = objectName;
			this.className = className;
			this.sessionState = sessionState;
		}
		
		/**
		 * This is the name assigned to the object when the session state is generated.
		 */
		public var objectName:String = null;

		/**
		 * This is the qualified class name of the original object providing the session state.
		 */
		public var className:String = null;

		/**
		 * This is the session state for an object of the type specified by className.
		 */
		public var sessionState:* = null;
		
		
		///////////////////////////////////////////////////////////
		
		
		public static const OBJECT_NAME:String = 'objectName';
		public static const CLASS_NAME:String = 'className';
		public static const SESSION_STATE:String = 'sessionState';
		
		{ /** begin static code block **/
			registerClassAlias(getQualifiedClassName(DynamicState), DynamicState);
		} /** end static code block **/
		
		/**
		 * This function can be used to detect DynamicState objects within nested, untyped session state objects.
		 * This function will check if the given object has the same properties as an actual DynamicState object instance. 
		 * @param object An object to check.
		 * @return A value of true if the object has all three properties that a DynamicState object has. 
		 */
		public static function objectHasProperties(object:Object):Boolean
		{
			if (object is DynamicState)
				return true;
			
			try
			{
				var matchCount:int = 0;
				for (var name:String in object)
				{
					if (name == OBJECT_NAME || name == CLASS_NAME || name == SESSION_STATE)
						matchCount++;
					else
						return false;
				}
				return (matchCount == 3); // must match all three properties with no extras
			}
			catch (e:Error)
			{
			}
			return false;
		}
	}
}
