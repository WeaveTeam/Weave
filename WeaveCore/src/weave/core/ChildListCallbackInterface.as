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

package weave.core
{
	import weave.api.core.IChildListCallbackInterface;
	import weave.api.core.ILinkableObject;
	
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
		private function setCallbackVariables(name:String = null, objectAdded:ILinkableObject = null, objectRemoved:ILinkableObject = null):void
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
			// remember previous values
			var _name:String = _lastNameAdded || _lastNameRemoved;
			var _added:ILinkableObject = _lastObjectAdded;
			var _removed:ILinkableObject = _lastObjectRemoved;
			
			_runCallbacksImmediately(name, objectAdded, objectRemoved);
			
			// restore previous values (in case an external JavaScript popup caused us to interrupt something else)
			setCallbackVariables(_name, _added, _removed);
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
