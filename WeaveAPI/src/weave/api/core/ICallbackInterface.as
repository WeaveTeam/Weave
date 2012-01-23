/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of the Weave API.
 *
 * The Initial Developer of the Weave API is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2012
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.api.core
{
	/**
	 * This is an interface for adding and removing callback functions.
	 * 
	 * @author adufilie
	 */
	public interface ICallbackInterface
	{
		/**
		 * This function will add a callback using the given function and parameters.
		 * Any callback previously added for the same function will be overwritten.
		 * The callback function will not be called recursively as a result of it triggering callbacks recursively.
		 * @param relevantContext If this is not null, then the callback will be removed when the relevantContext object is disposed via SessionManager.dispose().  This parameter is typically a 'this' pointer.
		 * @param callback The function to call when callbacks are triggered.
		 * @param parameters An array of parameters that will be used as parameters to the callback function.
		 * @param runCallbackNow If this is set to true, the callback will be run immediately after it is added.
		 * @param alwaysCallLast If this is set to true, the callback will be always be called after any callbacks that were added with alwaysCallLast=false.  Use this to establish the desired child-to-parent triggering order.
		 */
		function addImmediateCallback(relevantContext:Object, callback:Function, parameters:Array = null, runCallbackNow:Boolean = false, alwaysCallLast:Boolean = false):void;
		
		/**
		 * This function will add a callback that will be delayed except during a scheduled time each frame.  Grouped callbacks use a
		 * central trigger list, meaning that if multiple CallbackCollections trigger the same grouped callback before the scheduled
		 * time, it will behave as if it were only triggered once.  Adding a grouped callback to a CallbackCollection will replace
		 * any previous effects of addImmediateCallback() or addGroupedCallback() made to the same CallbackCollection.  The callback function
		 * will not be called recursively as a result of it triggering callbacks recursively.
		 * @param relevantContext If this is not null, then the callback will be removed when the relevantContext object is disposed via SessionManager.dispose().  This parameter is typically a 'this' pointer.
		 * @param groupedCallback The callback function that will only be allowed to run during a scheduled time each frame.  It must not require any parameters.
		 * @param triggerCallbackNow If this is set to true, the callback will be triggered to run during the scheduled time after it is added.
		 */
		function addGroupedCallback(relevantContext:Object, groupedCallback:Function, triggerCallbackNow:Boolean = false):void;

		/**
		 * This function will remove a callback that was previously added.
		 * @param callback The function to remove from the list of callbacks.
		 */
		function removeCallback(callback:Function):void;
		
		/**
		 * This counter gets incremented at the time that callbacks are triggered and before they are actually called.
		 * It is necessary in some situations to check this counter to determine if cached data should be used.
		 */
		function get triggerCounter():uint;
	}
}
