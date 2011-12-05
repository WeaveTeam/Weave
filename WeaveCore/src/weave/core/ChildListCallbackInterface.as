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
	import weave.core.CallbackCollection;
	import weave.api.core.ILinkableObject;
	import weave.api.core.IChildListCallbackInterface;
	
	/**
	 * @private
	 * Implementation of IChildListCallbackInterface for use with LinkableHashMap.
	 * 
	 * @author adufilie
	 */
	[ExcludeClass]
	public class ChildListCallbackInterface extends CallbackCollection implements IChildListCallbackInterface
	{
		public function ChildListCallbackInterface()
		{
			// specify the preCallback function in super() so list callback
			// variables will be set before each change callback.
			super(setCallbackVariables);
		}
	
		// these are the "callback variables" that get set before each callback runs.
		private var _lastNameAdded:String = null; // returned by public getter
		private var _lastObjectAdded:ILinkableObject = null; // returned by public getter
		private var _lastNameRemoved:String = null; // returned by public getter
		private var _lastObjectRemoved:ILinkableObject = null; // returned by public getter
		
		/**
		 * This function will set the list callback variables:
		 *     lastNameAdded, lastObjectAdded, lastNameRemoved, lastObjectRemoved, childListChanged
		 * @param name This is the name of the object that was just added or removed from the hash map.
		 * @param objectAdded This is the object that was just added to the hash map.
		 * @param objectRemoved This is the object that was just removed from the hash map.
		 */
		public function setCallbackVariables(name:String = null, objectAdded:ILinkableObject = null, objectRemoved:ILinkableObject = null):void
		{
			_lastNameAdded = objectAdded ? name : null;
			_lastObjectAdded = objectAdded;
			_lastNameRemoved = objectRemoved ? name : null;
			_lastObjectRemoved = objectRemoved;
		}
		
		/**
		 * This function will run callbacks immediately, setting the list callback variables before each one.
		 * @param name
		 * @param objectAdded
		 * @param objectRemoved
		 */	
		public function runCallbacks(name:String, objectAdded:ILinkableObject, objectRemoved:ILinkableObject):void
		{
			_runCallbacksImmediately(name, objectAdded, objectRemoved);
			setCallbackVariables(); // clear the variables
		}
	
		/**
		 * This is the name of the object that was added prior to running callbacks.
		 */
		public function get lastNameAdded():String
		{
			return _lastNameAdded;
		}
	
		/**
		 * This is the object that was added prior to running callbacks.
		 */
		public function get lastObjectAdded():ILinkableObject
		{
			return _lastObjectAdded;
		}
	
		/**
		 * This is the name of the object that was removed prior to running callbacks.
		 */
		public function get lastNameRemoved():String
		{
			return _lastNameRemoved;
		}
	
		/**
		 * This is the object that was removed prior to running callbacks.
		 */
		public function get lastObjectRemoved():ILinkableObject
		{
			return _lastObjectRemoved;
		}
	}
}
