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
	 * This is an interface for adding and removing callback functions, and triggering them.
	 * 
	 * @author adufilie
	 */
	public interface ICallbackCollection extends ICallbackInterface, ILinkableObject
	{
		/**
		 * This will trigger every callback function to be called with their saved arguments.
		 * If the delay count is greater than zero, the callbacks will not be called immediately.
		 */
		function triggerCallbacks():void;

		/**
		 * While this is true, it means the delay count is greater than zero and the effects of
		 * triggerCallbacks() are delayed until resumeCallbacks() is called to reduce the delay count.
		 */
		function get callbacksAreDelayed():Boolean;
		
		/**
		 * This will increase the delay count by 1.  To decrease the delay count, use resumeCallbacks().
		 * As long as the delay count is greater than zero, effects of triggerCallbacks() will be delayed.
		 */
		function delayCallbacks():void;

		/**
		 * This will decrease the delay count if it is greater than zero.
		 * If triggerCallbacks() was called while the delay count was greater than zero, immediate callbacks will be called now.
		 * @param undoAllDelays If this is set to true, the delay count will be set to zero.  Otherwise, the delay count will be decreased by one.
		 */
		function resumeCallbacks(undoAllDelays:Boolean = false):void;
	}
}
