/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package weavejs.core
{
	import weavejs.api.core.DynamicState;
	import weavejs.api.core.ICallbackCollection;
	import weavejs.api.core.IDisposableObject;
	import weavejs.api.core.ILinkableVariable;
	import weavejs.compiler.StandardLib;
	import weavejs.utils.JS;
	
	/**
	 * LinkableVariable allows callbacks to be added that will be called when the value changes.
	 * A LinkableVariable has an optional type restriction on the values it holds.
	 * 
	 * @author adufilie
	 */
	public class LinkableVariable extends CallbackCollection implements ILinkableVariable, ICallbackCollection, IDisposableObject
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
		protected var _sessionStateInternal:* = undefined;
		
		/**
		 * Available externally via getSessionState()
		 */
		protected var _sessionStateExternal:* = undefined;
		
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
			super();
			
			if (sessionStateType != Object)
			{
				_sessionStateType = sessionStateType;
				_primitiveType = _sessionStateType == String
					|| _sessionStateType == Number
					|| _sessionStateType == Boolean;
			}
			
			_verifier = verifier;
			
			if (defaultValue !== undefined)
			{
				setSessionState(defaultValue);
				
				// If callbacks were triggered, make sure callbacks are triggered again one frame later when
				// it is possible for other classes to have a pointer to this object and retrieve the value.
				if (defaultValueTriggersCallbacks && triggerCounter > DEFAULT_TRIGGER_COUNT)
					Weave.callLater(this, _defaultValueTrigger);
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
			{
				// using a local variable is necessary in order to avoid an 'as' compiler bug
				var sst:Class = _sessionStateType;
				value = value as sst;
			}
			
			// stop if verifier says it's not an accepted value
			if (_verifier != null && !_verifier(value))
				return;
			
			var wasCopied:Boolean = false;
			var type:String = null;
			if (value != null)
			{
				type = typeof(value);
				if (type == 'object' && value.constructor != Object && value.constructor != Array)
				{
					// convert to dynamic Object prior to sessionStateEquals comparison
					value = JS.copyObject(value);
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
					value = JS.copyObject(value);
				
				DynamicState.alterSessionStateToBypassDiff(value);
				
				// save external copy, accessible via getSessionState()
				_sessionStateExternal = value;
				
				// save internal copy
				_sessionStateInternal = JS.copyObject(value);
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
			
			return StandardLib.compare(_sessionStateInternal, otherSessionState, objectCompare) == 0;
		}
		
		private function objectCompare(a:Object, b:Object):Number
		{
			if (DynamicState.isDynamicState(a, true) &&
				DynamicState.isDynamicState(b, true) &&
				a[DynamicState.CLASS_NAME] == b[DynamicState.CLASS_NAME] &&
				a[DynamicState.OBJECT_NAME] == b[DynamicState.OBJECT_NAME] )
			{
				return StandardLib.compare(a[DynamicState.SESSION_STATE], b[DynamicState.SESSION_STATE], objectCompare);
			}
			return NaN;
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

		public function get state():Object
		{
			return _sessionStateExternal;
		}
		public function set state(value:Object):void
		{
			setSessionState(value);
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
