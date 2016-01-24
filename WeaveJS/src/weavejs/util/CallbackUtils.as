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

package weavejs.util
{
	import weavejs.util.JS;

	public class CallbackUtils
	{
		/**
		 * This function generates a delayed version of a callback.
		 * @param relevantContext If this is not null, then the callback will be removed when the relevantContext object is disposed via SessionManager.dispose().  This parameter is typically a 'this' pointer.
		 * @param callback The callback function.
		 * @param delay The number of milliseconds to delay before running the callback.
		 * @param passDelayedParameters If this is set to true, the most recent parameters passed to the delayed callback will be passed to the original callback when it is called.  If this is set to false, no parameters will be passed to the original callback.
		 * @return A wrapper around the callback that remembers the parameters and delays calling the original callback.
		 */
		public static function generateDelayedCallback(relevantContext:Object, callback:Function, delay:int = 500, passDelayedParameters:Boolean = false):Function
		{
			var _timeout:int = 0;
			var _delayedThisArg:Object;
			var _delayedParams:Array;
			// this function gets called immediately and delays calling the original callback
			var delayedCallback:Function = function(...params):void
			{
				if (_timeout)
					JS.clearTimeout(_timeout);
				_timeout = JS.setTimeout(callback_apply, delay);
				// remember the params passed to this delayedCallback
				_delayedThisArg = this;
				_delayedParams = params;
			};
			// this function gets called when the timer completes
			var callback_apply:Function = function(..._):void
			{
				if (Weave.wasDisposed(relevantContext))
				{
					if (_timeout)
						JS.clearTimeout(_timeout);
					_timeout = 0;
					_delayedThisArg = null;
					_delayedParams = null;
					relevantContext = null;
					callback = null;
					callback_apply = null;
					delayedCallback = null;
				}
				else
				{
					// call the original callback with the params passed to delayedCallback
					callback.apply(_delayedThisArg, passDelayedParameters ? _delayedParams : null);
				}
			};
			
			return delayedCallback;
		}
	}
}
