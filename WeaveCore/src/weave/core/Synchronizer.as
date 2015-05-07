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
	import flash.utils.getTimer;
	
	import mx.binding.utils.BindingUtils;
	import mx.binding.utils.ChangeWatcher;
	import mx.core.UIComponent;
	
	import weave.api.core.ICallbackCollection;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableVariable;
	import weave.api.core.ISessionManager;
	import weave.compiler.Compiler;
	
	/**
	 * @see weave.core.SessionManager#linkBindableProperty()
	 */
	internal class Synchronizer implements IDisposableObject
	{
		public function Synchronizer(linkableVariable:ILinkableVariable, bindableParent:Object, bindablePropertyName:String, delay:uint = 0, onlyWhenFocused:Boolean = false, ignoreFocus:Boolean = false):void
		{
			sm.registerDisposableChild(bindableParent, this);
			sm.registerDisposableChild(linkableVariable, this);
			this.linkableVariable = linkableVariable;
			this.bindableParent = bindableParent;
			this.bindablePropertyName = bindablePropertyName;
			this.delay = delay;
			this.onlyWhenFocused = onlyWhenFocused;
			this.ignoreFocus = ignoreFocus;
			this.callbackCollection = sm.getCallbackCollection(linkableVariable);
			this.uiComponent = bindableParent as UIComponent;
			
			// Copy session state over to bindable property now, before calling BindingUtils.bindSetter(),
			// because that will copy from the bindable property to the sessioned property.
			this.synchronize();
			
			// below, we need to check if the variables are still set in case dispose() was called from synchronize()
			
			// when the bindable property changes, set the session state
			if (this.linkableVariable)
				this.watcher = BindingUtils.bindSetter(synchronize, bindableParent, bindablePropertyName);
			
			// when the session state changes, set the bindable property
			if (this.callbackCollection)
			{
				this.callbackCollection.addImmediateCallback(bindableParent, synchronize);
				this.callbackCollection.addDisposeCallback(bindableParent, linkableVariableDisposeCallback);
			}
		}
		
		private function linkableVariableDisposeCallback():void
		{
			WeaveAPI.SessionManager.disposeObject(this);
		}
		
		public function dispose():void
		{
			if (this.callbackCollection)
				this.callbackCollection.removeCallback(synchronize);
			if (this.watcher)
				this.watcher.unwatch();
			
			this.linkableVariable = null;
			this.bindableParent = null;
			this.bindablePropertyName = null;
			this.callbackCollection = null;
			this.watcher = null;
		}
		
		public var debug:Boolean = false;
		
		private const sm:ISessionManager = WeaveAPI.SessionManager;
		private var callbackCollection:ICallbackCollection;
		private var linkableVariable:ILinkableVariable;
		private var bindableParent:Object;
		private var bindablePropertyName:String;
		private var delay:uint;
		private var onlyWhenFocused:Boolean;
		private var ignoreFocus:Boolean;
		private var watcher:ChangeWatcher;
		private var uiComponent:UIComponent;
		private var useLinkableValue:Boolean = true;
		private var callLaterTime:int = 0;
		private var recursiveCall:Boolean = false;
		
		private function debugLink(linkVal:Object, bindVal:Object, useLinkableBefore:Boolean, useLinkableAfter:Boolean, callingLater:Boolean):void
		{
			var link:String = (useLinkableBefore && useLinkableAfter ? 'LINK' : 'link') + '(' + Compiler.stringify(linkVal) + ')';
			var bind:String = (!useLinkableBefore && !useLinkableAfter ? 'BIND' : 'bind') + '(' + Compiler.stringify(bindVal) + ')';
			var str:String = link + ', ' + bind;
			if (useLinkableBefore && !useLinkableAfter)
			str = link + ' = ' + bind;
			if (!useLinkableBefore && useLinkableAfter)
			str = bind + ' = ' + link;
			if (callingLater)
			str += ' (callingLater)';
			
			trace(str);
		}

		// When given zero parameters, this function copies the linkable value to the bindable value.
		// When given one or more parameters, this function copies the bindable value to the linkable value.
		private function synchronize(firstParam:* = undefined, callingLater:Boolean = false):void
		{
			// stop if already disposed
			if (!linkableVariable)
				return;
			
			// unlink if linkableVariable was disposed
			if (sm.objectWasDisposed(linkableVariable))
			{
				sm.disposeObject(this);
				return;
			}
			
			if (debug)
				debugLink(
					linkableVariable.getSessionState(),
					firstParam===undefined ? bindableParent[bindablePropertyName] : firstParam,
					useLinkableValue,
					firstParam===undefined,
					callingLater
				);
			
			// If bindableParent has focus:
			// When linkableVariable changes, update bindable value only when focus is lost (callLaterTime = int.MAX_VALUE).
			// When bindable value changes, update linkableVariable after a delay.
			
			if (!callingLater)
			{
				// remember which value changed last -- the linkable one or the bindable one
				useLinkableValue = firstParam === undefined; // true when called from linkable variable grouped callback
				// if we're not calling later and there is already a timestamp, just wait for the callLater to trigger
				if (callLaterTime)
				{
					// if there is a callLater waiting to trigger, update the target time
					callLaterTime = useLinkableValue ? int.MAX_VALUE : getTimer() + delay;
					
					//trace('\tdelaying the timer some more');
					
					return;
				}
			}
			
			// if the bindable value is not a boolean and the bindable parent has focus, delay synchronization
			var bindableValue:Object = bindableParent[bindablePropertyName];
			if (uiComponent && !(bindableValue is Boolean))
			{
				if (watcher && !ignoreFocus && UIUtils.hasFocus(uiComponent))
				{
					if (linkableVariable is LinkableVariable)
					{
						var verified:Boolean = false;
						try
						{
							verified = (linkableVariable as LinkableVariable).verifyValue(bindableValue);
						}
						catch (e:Error)
						{
							trace('Error calling verifier:', e.getStackTrace());
						}
						if (verified)
						{
							// clear previous error string
							if (uiComponent.errorString == VALUE_NOT_ACCEPTED)
								uiComponent.errorString = '';
						}
						else
						{
							// show error string if not already shown
							if (!uiComponent.errorString)
								uiComponent.errorString = VALUE_NOT_ACCEPTED;
						}
					}
					
					var currentTime:int = getTimer();
					
					// if we're not calling later, set the target time (int.MAX_VALUE means delay until focus is lost)
					if (!callingLater)
						callLaterTime = useLinkableValue ? int.MAX_VALUE : currentTime + delay;
					
					// if we haven't reached the target time yet or callbacks are delayed, call later
					if (currentTime < callLaterTime)
					{
						// firstParam is ignored when callingLater=true
						uiComponent.callLater(synchronize, [firstParam, true]);
						return;
					}
				}
				else if (!useLinkableValue && !ignoreFocus && onlyWhenFocused && !callingLater)
				{
					// component does not have focus, so ignore the bindableValue.
					return;
				}
				
				// otherwise, synchronize now
				// clear saved time stamp when we are about to synchronize
				callLaterTime = 0;
			}
			
			// if the linkable variable's callbacks are delayed, delay synchronization
			if (watcher && sm.getCallbackCollection(linkableVariable).callbacksAreDelayed)
			{
				// firstParam is ignored when callingLater=true
				WeaveAPI.StageUtils.callLater(this, synchronize, [firstParam, true]);
				return;
			}
			
			// synchronize
			if (useLinkableValue)
			{
				var linkableValue:Object = linkableVariable.getSessionState();
				if ((bindableValue is Number) != (linkableValue is Number))
				{
					try {
						if (linkableValue is Number)
						{
							if (isNaN(linkableValue as Number))
								linkableValue = '';
							else
								linkableValue = '' + linkableValue;
						}
						else
						{
							linkableVariable.setSessionState(Number(linkableValue));
							linkableValue = linkableVariable.getSessionState();
						}
					} catch (e:Error) { }
				}
				if (bindableValue != linkableValue)
					bindableParent[bindablePropertyName] = linkableValue;
				
				// clear previous error string
				if (uiComponent && linkableVariable is LinkableVariable && uiComponent.errorString == VALUE_NOT_ACCEPTED)
					uiComponent.errorString = '';
			}
			else
			{
				var prevCount:uint = callbackCollection.triggerCounter;
				linkableVariable.setSessionState(bindableValue);
				// Always synchronize after setting the linkableVariable because there may
				// be constraints on the session state that will prevent the callbacks
				// from triggering if the bindable value does not match those constraints.
				// This makes UIComponents update to the real value after they lose focus.
				if (callbackCollection.triggerCounter == prevCount && !recursiveCall)
				{
					// avoid infinite recursion in the case where the new value is not accepted by a verifier function
					recursiveCall = true;
					synchronize();
					recursiveCall = false;
				}
			}
		}
		
		private const VALUE_NOT_ACCEPTED:String = lang('Value not accepted.');
	}
}
