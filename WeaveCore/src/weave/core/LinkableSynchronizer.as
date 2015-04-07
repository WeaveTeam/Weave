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
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObject;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;
	
	public class LinkableSynchronizer implements ILinkableObject
	{
		public const primaryPath:LinkableVariable = registerLinkableChild(this, new LinkableVariable(Array), setPrimaryPath);
		public const secondaryPath:LinkableVariable = registerLinkableChild(this, new LinkableVariable(Array), setSecondaryPath);
		
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
		
		private var _primary:ILinkableObject;
		private var _secondary:ILinkableObject;
		
		private function synchronize():void
		{
			var primary:ILinkableObject = primaryWatcher.target;
			var secondary:ILinkableObject = secondaryWatcher.target;
			if (_primary != primary || _secondary != secondary)
			{
				if (_primary && _secondary)
				{
					WeaveAPI.SessionManager.getCallbackCollection(_primary).removeCallback(primaryCallback);
					WeaveAPI.SessionManager.getCallbackCollection(_secondary).removeCallback(secondaryCallback);
				}
				_primary = primary;
				_secondary = secondary;
				if (primary && secondary)
				{
					WeaveAPI.SessionManager.getCallbackCollection(_secondary).addImmediateCallback(this, secondaryCallback);
					WeaveAPI.SessionManager.getCallbackCollection(_primary).addImmediateCallback(this, primaryCallback, true);
				}
			}
		}
		
		private function primaryCallback():void
		{
			WeaveAPI.SessionManager.copySessionState(_primary, _secondary);
		}
		private function secondaryCallback():void
		{
			WeaveAPI.SessionManager.copySessionState(_secondary, _primary);
		}
	}
}
