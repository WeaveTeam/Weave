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
	import flash.utils.getDefinitionByName;
	
	import mx.utils.ObjectUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableVariable;
	import weave.api.reportError;
	import weave.utils.AsyncSort;
	
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
		 * @param defaultValue The default value for the session state.
		 * @param defaultValueTriggersCallbacks Set this to false if you do not want the callbacks to be triggered one frame later after setting the default value.
		 */
		public function LinkableVariable(sessionStateType:Class = null, verifier:Function = null, defaultValue:* = undefined, defaultValueTriggersCallbacks:Boolean = true)
		{
			// not supporting XML directly
			if (sessionStateType == _XML_CLASS)
			{
				reportError("XML is not supported directly as a session state primitive type. Using String instead.");
				_sessionStateType = String;
			}
			else
			{
				_sessionStateType = sessionStateType;
			}
			_verifier = verifier;
			
			if (!sessionStateEquals(defaultValue))
			{
				setSessionState(defaultValue);
				
				// If callbacks were triggered, make sure callbacks are triggered again one frame later when
				// it is possible for other classes to have a pointer to this object and retrieve the value.
				if (defaultValueTriggersCallbacks && triggerCounter > DEFAULT_TRIGGER_COUNT)
					WeaveAPI.StageUtils.callLater(this, _defaultValueTrigger, null, WeaveAPI.TASK_PRIORITY_IMMEDIATE);
			}
		}
		
		private static const _XML_CLASS:Class = getDefinitionByName('XML') as Class; // this avoids a weird asdoc build error
		
		/**
		 * @private
		 */		
		private function _defaultValueTrigger():void
		{
			// unless callbacks were triggered again since the default value was set, trigger callbacks now
			if (!wasDisposed && triggerCounter == DEFAULT_TRIGGER_COUNT + 1)
				triggerCallbacks();
		}

		/**
		 * This function is used in setSessionState() to determine if the value has changed or not.
		 * Classes that extend this class may override this function.
		 */
		protected function sessionStateEquals(otherSessionState:*):Boolean
		{
			if (_sessionStateType == null) // if no type restriction...
				return AsyncSort.defaultCompare(_sessionState, otherSessionState) == 0;
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
		
		/**
		 * This function will verify if a given value is a valid session state for this linkable variable.
		 * @param value The value to verify.
		 * @return A value of true if the value is accepted by this linkable variable.
		 */
		internal function verifyValue(value:Object):Boolean
		{
			return _verifier == null || _verifier(value);
		}

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
				// not supporting XML directly
				var type:String = typeof(value);
				if (type == 'xml')
				{
					reportError("XML is not supported directly as a session state primitive type. Using String instead.");
					value = XML(value).toXMLString();
				}
				
				else if (type == 'object')
					value = ObjectUtil.copy(value);
			}
			
			// stop if the value did not change
			if (_sessionStateWasSet && sessionStateEquals(value))
				return;
			
			_sessionStateWasSet = true;

			_sessionState = value;

			triggerCallbacks();
		}

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
