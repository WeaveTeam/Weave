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
		{ /** begin static code block **/
			registerClassAlias(getQualifiedClassName(DynamicState), DynamicState);
		} /** end static code block **/
		
		public function DynamicState(objectName:String = null, className:String = null, sessionState:Object = null)
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
		public var sessionState:Object = null;
		
		/**
		 * This function can be used to detect DynamicState objects within nested, untyped session state objects.
		 * If an object has only three properties (objectName, className, sessionState), this function will
		 * return a DynamicState object having those values.  Otherwise, null is returned because the object is
		 * assumed to be incompatible.
		 * @param object An object that has all the properties that DynamicState has.
		 * @param createNewObject If this is set to true, this function will return a new DynamicState object even if the given object is already a DynamicState.
		 * @return Either a DynamicState object or null if the cast failed.
		 */
		public static function cast(object:Object, createNewObject:Boolean = false):DynamicState
		{
			try
			{
				if (object is DynamicState)
				{
					var original:DynamicState = object as DynamicState;
					if (createNewObject)
						return new DynamicState(original.objectName, original.className, original.sessionState);
					return original;
				}
				
				var matchCount:int = 0;
				for (var name:String in object)
				{
					if (name == "objectName" || name == "className" || name == "sessionState")
						matchCount++;
					else
						return null;
				}
				if (matchCount == 3) // must match all three properties with no extras
					return new DynamicState(object.objectName, object.className, object.sessionState);
			}
			catch (e:Error) { }

			return null;
		}
	}
}
