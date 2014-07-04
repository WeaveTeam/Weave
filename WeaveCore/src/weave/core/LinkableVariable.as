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
	import weave.compiler.StandardLib;
	
	/**
	 * LinkableVariable allows callbacks to be added that will be called when the value changes.
	 * A LinkableVariable has an optional type restriction on the values it holds.
	 * 
	 * @author adufilie
	 */
	public class LinkableVariable extends CallbackCollection implements ILinkableVariable
	{
		/**
		 * This function is used to prevent the session state from having unwanted values.
		 * Function signature should be  function(value:*):Boolean
		 */		
		protected var _verifier:Function = null;
		
		/**
		 * This is true if the session state has been set at least once.
		 */
		protected var _sessionStateWasSet:Boolean = false;
		
		/**
		 * This is true if the _sessionStateType is a primitive type.
		 */
		protected var _primitiveType:Boolean = false;
		
		/**
		 * Type restriction passed in to the constructor.
		 */
		protected var _sessionStateType:Class = null;
		
		/**
		 * Cannot be modified externally because it is not returned by getSessionState()
		 */
		protected var _sessionStateInternal:* = null;
		
		/**
		 * Available externally via getSessionState()
		 */
		protected var _sessionStateExternal:* = null;
		
		/**
		 * This is set to true when lock() is called.
		 */
		protected var _locked:Boolean = false;
		
		/**
		 * If a defaultValue is specified, callbacks will be triggered in a later frame unless they have already been triggered before then.
		 * This behavior is desirable because it allows the initial value to be handled by the same callbacks that handles new values.
		 * @param sessionStateType The type of values accepted for this sessioned property.
		 * @param verifier A function that returns true or false to verify that a value is accepted as a session state or not.  The function signature should be  function(value:*):Boolean.
		 * @param defaultValue The default value for the session state.
		 * @param defaultValueTriggersCallbacks Set this to false if you do not want the callbacks to be triggered one frame later after setting the default value.
		 */
		public function LinkableVariable(sessionStateType:Class = null, verifier:Function = null, defaultValue:* = undefined, defaultValueTriggersCallbacks:Boolean = true)
		{
			// not supporting XML directly
			if (sessionStateType == XML_Class)
				throw new Error("XML is not supported directly as a session state primitive type. Using String instead.");
			
			if (sessionStateType != Object)
			{
				_sessionStateType = sessionStateType;
				_primitiveType = _sessionStateType == String
					|| _sessionStateType == Number
					|| _sessionStateType == Boolean
					|| _sessionStateType == int
					|| _sessionStateType == uint;
			}
			
			_verifier = verifier;
			
			if (!sessionStateEquals(defaultValue))
			{
				setSessionState(defaultValue);
				
				// If callbacks were triggered, make sure callbacks are triggered again one frame later when
				// it is possible for other classes to have a pointer to this object and retrieve the value.
				if (defaultValueTriggersCallbacks && triggerCounter > DEFAULT_TRIGGER_COUNT)
					WeaveAPI.StageUtils.callLater(this, _defaultValueTrigger, null, WeaveAPI.TASK_PRIORITY_0_IMMEDIATE);
			}
		}
		
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
		 * @return true if the session state is considered undefined.
		 */
		public function isUndefined():Boolean
		{
			return !_sessionStateWasSet || _sessionStateInternal == null;
		}
		
		/**
		 * This function will verify if a given value is a valid session state for this linkable variable.
		 * @param value The value to verify.
		 * @return A value of true if the value is accepted by this linkable variable.
		 */
		internal function verifyValue(value:Object):Boolean
		{
			return _verifier == null || _verifier(value);
		}
		
		/**
		 * The type restriction passed in to the constructor.
		 */
		public function getSessionStateType():Class
		{
			return _sessionStateType;
		}

		/**
		 * @inheritDoc
		 */
		public function getSessionState():Object
		{
			return _sessionStateExternal;
		}
		
		/**
		 * @inheritDoc
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
			
			var wasCopied:Boolean = false;
			var type:String = null;
			if (value !== null)
			{
				type = typeof(value);
				// not supporting XML directly because XMLs are difficult to compare
				// and we don't want two LinkableVariables to share the same object as their session state.
				if (type == 'xml')
				{
					WeaveAPI.ErrorManager.reportError("XML is not supported directly as a session state primitive type. Using String instead.");
					value = XML(value).toXMLString();
				}
				else if (type == 'object' && value.constructor != Object && value.constructor != Array)
				{
					// convert to dynamic Object prior to sessionStateEquals comparison
					value = ObjectUtil.copy(value);
					wasCopied = true;
				}
			}
			
			// If this is the first time we are calling setSessionState(), including
			// from the constructor, don't bother checking sessionStateEquals().
			// Otherwise, stop if the value did not change.
			if (_sessionStateWasSet && sessionStateEquals(value))
				return;
			
			// If the value is a dynamic object, save a copy because we don't want
			// two LinkableVariables to share the same object as their session state.
			if (type == 'object')
			{
				if (!wasCopied)
					value = ObjectUtil.copy(value);
				
				// save external copy, accessible via getSessionState()
				_sessionStateExternal = value;
				
				// save internal copy
				_sessionStateInternal = ObjectUtil.copy(value);
			}
			else
			{
				// save primitive value
				_sessionStateExternal = _sessionStateInternal = value;
			}
			
			// remember that we have set the session state at least once.
			_sessionStateWasSet = true;
			
			triggerCallbacks();
		}
		
		/**
		 * This function is used in setSessionState() to determine if the value has changed or not.
		 * Classes that extend this class may override this function.
		 */
		protected function sessionStateEquals(otherSessionState:*):Boolean
		{
			if (_primitiveType)
				return _sessionStateInternal == otherSessionState;
			
			return StandardLib.compareDynamicObjects(_sessionStateInternal, otherSessionState) == 0;
		}
		
		/**
		 * This function may be called to detect change to a non-primitive session state in case it has been modified externally.
		 */
		public function detectChanges():void
		{
			if (!sessionStateEquals(_sessionStateExternal))
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

		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			super.dispose();
			setSessionState(null);
		}
	}
}
