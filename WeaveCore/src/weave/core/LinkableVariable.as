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
	import mx.utils.ObjectUtil;
	
	import weave.api.core.ILinkableVariable;
	
	/**
	 * LinkableVariable allows callbacks to be added that will be called when the value changes.
	 * A LinkableVariable has an optional type restriction on the values it holds.
	 * 
	 * @author adufilie
	 */
	public class LinkableVariable extends CallbackCollection implements ILinkableVariable
	{
		/**
		 * This constructor does not allow an initial value to be specified, because no other class has a pointer to this object until the
		 * constructor completes, which means the value cannot be retrieved during any callbacks that would run in the constructor.  This
		 * forces the developer to set default values outside the constructor of the LinkableVariable, which means the callbacks will run
		 * the first time the value is set.  This behavior is desirable because it allows the initial value to be handled by the same code
		 * that handles new values.
		 * @param sessionStateType The type of values accepted for this sessioned property.
		 * @param verifier A function that returns true or false to verify that a value is accepted as a session state or not.  The function signature should be  function(value:*):Boolean.
		 */
		public function LinkableVariable(sessionStateType:Class = null, verifier:Function = null)
		{
			_sessionStateType = sessionStateType;
			_verifier = verifier;
		}

		/**
		 * This function is used in setSessionState() to determine if the value has changed or not.
		 * Classes that extend this class may override this function.
		 */
		protected function sessionStateEquals(otherSessionState:*):Boolean
		{
			if (_sessionStateType == null) // if no type restriction...
			{
				var type:String = typeof(otherSessionState);
				if (type != typeof(_sessionState))
					return false; // types differ, so not equal
				if (type == 'object')
					return false; // do not attempt an object compare.. assume not equal
				return ObjectUtil.compare(_sessionState, otherSessionState) == 0; // compare primitive value
			}
			return _sessionState == otherSessionState;
		}
		
		/**
		 * @return true if the session state is considered undefined.
		 */
		public function isUndefined():Boolean
		{
			return !_sessionStateWasSet || _sessionState == null;
		}
		
		/**
		 * This function is used to prevent the session state from having unwanted values.
		 * Function signature should be  function(value:*):Boolean
		 */		
		protected var _verifier:Function = null;

		protected var _sessionStateType:Class = null;
		public function getSessionStateType():Class
		{
			return _sessionStateType;
		}

		protected var _sessionState:* = null;
		public function getSessionState():Object
		{
			return _sessionState;
		}

		/**
		 * This is true if the session state has been set at least once.
		 */
		protected var _sessionStateWasSet:Boolean = false;
		
		/**
		 * Unless callbacks have been delayed with delayCallbacks(), this function will update _value and run callbacks.
		 * If this is not the first time setSessionState() is called and the new value equals the current value, this function has no effect.
		 * @param value The new value.  If the value given is of the wrong type, the value will be set to null.
		 */
		public function setSessionState(value:Object):void
		{
			if (_locked)
				return;

			// cast value now in case it is not the appropriate type
			if (_sessionStateType != null)
				value = value as _sessionStateType;
			
			// stop if verifier says it's not an accepted value
			if (_verifier != null && !_verifier(value))
				return;
			
			// If the value is non-primitive, save a copy because we don't want
			// two LinkableVariables to share the same object as their session state.
			if (value !== null)
			{
				if (value is XML)
					value = (value as XML).copy();
				else if (typeof(value) == 'object')
					value = ObjectUtil.copy(value);
			}
			
			// stop if the value did not change
			if (_sessionStateWasSet && sessionStateEquals(value))
				return;
			
			_sessionStateWasSet = true;

//			if (_sessionState is XML)
//				(_sessionState as XML).setNotification(null); // stop the old XML from triggering callbacks
//			if (value is XML)
//				(value as XML).setNotification(handleChange); // this will trigger callbacks when the new xml is modified.
			_sessionState = value;

			triggerCallbacks();
		}

//		/**
//		 * This function gets called if the session state is an XML object and it changes.
//		 */		
//		private function handleChange(..._):void
//		{
//			triggerCallbacks();
//		}
		
		/**
		 * Call this function when you do not want to allow any more changes to the value of this sessioned property.
		 */
		public function lock():void
		{
			_locked = true;
		}
		
		/**
		 * This is set to true when lock() is called.
		 * Subsequent calls to setSessionState() will have no effect.
		 */
		public function get locked():Boolean
		{
			return _locked;
		}
		protected var _locked:Boolean = false;

		override public function dispose():void
		{
			super.dispose();
			setSessionState(null);
		}
	}
}
