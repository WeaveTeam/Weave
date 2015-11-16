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

package weavejs.core
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.ICallbackCollection;
	import weavejs.api.core.ILinkableObject;
	
	public class LinkableSynchronizer implements ILinkableObject
	{
		public static const VAR_STATE:String = 'state';
		public static const VAR_PRIMARY:String = 'primary';
		public static const VAR_SECONDARY:String = 'secondary';
		
		public function LinkableSynchronizer()
		{
			_callbacks = WeaveAPI.SessionManager.getCallbackCollection(this);
			_callbacks.addImmediateCallback(null, selfCallback);
		}
		
		public const primaryPath:LinkableVariable = registerLinkableChild(this, new LinkableVariable(Array), setPrimaryPath);
		public const secondaryPath:LinkableVariable = registerLinkableChild(this, new LinkableVariable(Array), setSecondaryPath);
		
		public const primaryTransform:LinkableFunction = registerLinkableChild(this, new LinkableFunction(null, false, false, [VAR_STATE, VAR_PRIMARY, VAR_SECONDARY]), handlePrimaryTransform);
		public const secondaryTransform:LinkableFunction = registerLinkableChild(this, new LinkableFunction(null, false, false, [VAR_STATE, VAR_PRIMARY, VAR_SECONDARY]), handleSecondaryTransform);
		
		private const primaryWatcher:LinkableWatcher = registerDisposableChild(this, new LinkableWatcher(null, synchronize));
		private const secondaryWatcher:LinkableWatcher = registerDisposableChild(this, new LinkableWatcher(null, synchronize));
		
		private function setPrimaryPath():void
		{
			primaryWatcher.targetPath = primaryPath.getSessionState() as Array;
		}
		private function setSecondaryPath():void
		{
			secondaryWatcher.targetPath = secondaryPath.getSessionState() as Array;
		}
		
		private var _callbacks:ICallbackCollection;
		private var _delayedSynchronize:Boolean = false;
		private var _primary:ILinkableObject;
		private var _secondary:ILinkableObject;
		
		private function selfCallback():void
		{
			if (_delayedSynchronize)
				synchronize();
		}
		
		private function synchronize():void
		{
			if (_callbacks.callbacksAreDelayed)
			{
				_delayedSynchronize = true;
				return;
			}
			_delayedSynchronize = false;
			
			var primary:ILinkableObject = primaryWatcher.target;
			var secondary:ILinkableObject = secondaryWatcher.target;
			if (_primary != primary || _secondary != secondary)
			{
				// check objects individually since one may have been disposed
				if (_primary)
					WeaveAPI.SessionManager.getCallbackCollection(_primary).removeCallback(primaryCallback);
				if (_secondary)
					WeaveAPI.SessionManager.getCallbackCollection(_secondary).removeCallback(secondaryCallback);
				
				_primary = primary;
				_secondary = secondary;
				
				if (primary && secondary)
				{
					WeaveAPI.SessionManager.getCallbackCollection(_secondary).addImmediateCallback(this, secondaryCallback);
					WeaveAPI.SessionManager.getCallbackCollection(_primary).addImmediateCallback(this, primaryCallback);
					
					// if primaryTransform is not given but secondaryTransform is, call secondaryCallback.
					// otherwise, call primaryCallback.
					if (!primaryTransform.value && secondaryTransform.value)
						secondaryCallback();
					else
						primaryCallback();
				}
			}
		}
		
		private function handlePrimaryTransform():void
		{
			// if callbacks are delayed, it means we're loading a session state, so we don't want to apply the transform.
			if (!_callbacks.callbacksAreDelayed && _primary && _secondary)
				primaryCallback();
		}
		
		private function handleSecondaryTransform():void
		{
			// if callbacks are delayed, it means we're loading a session state, so we don't want to apply the transform.
			if (!_callbacks.callbacksAreDelayed && _primary && _secondary)
				secondaryCallback();
		}
		
		private function primaryCallback():void
		{
			if (_callbacks.callbacksAreDelayed)
			{
				_delayedSynchronize = true;
				_callbacks.triggerCallbacks();
				return;
			}
			
			if (primaryTransform.value)
			{
				try
				{
					var state:Object = WeaveAPI.SessionManager.getSessionState(_primary);
					var transformedState:Object = primaryTransform.apply(null, [state, _primary, _secondary]);
					WeaveAPI.SessionManager.setSessionState(_secondary, transformedState, true);
				}
				catch (e:Error)
				{
					WeaveAPI.ErrorManager.reportError(e, "primaryTransform: " + e.message);
				}
			}
			else if (!secondaryTransform.value)
			{
				WeaveAPI.SessionManager.copySessionState(_primary, _secondary);
			}
		}
		private function secondaryCallback():void
		{
			if (_callbacks.callbacksAreDelayed)
			{
				_delayedSynchronize = true;
				_callbacks.triggerCallbacks();
				return;
			}
			
			if (secondaryTransform.value)
			{
				try
				{
					var state:Object = WeaveAPI.SessionManager.getSessionState(_secondary);
					var transformedState:Object = secondaryTransform.apply(null, [state, _primary, _secondary]);
					WeaveAPI.SessionManager.setSessionState(_primary, transformedState, true);
				}
				catch (e:Error)
				{
					WeaveAPI.ErrorManager.reportError(e, "secondaryTransform: " + e.message);
				}
			}
			else if (!primaryTransform.value)
			{
				WeaveAPI.SessionManager.copySessionState(_secondary, _primary);
			}
		}
	}
}
