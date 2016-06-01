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
	public class EventCallbackCollection/*/<T>/*/ extends CallbackCollection
	{
		public function EventCallbackCollection(stopPropagation:/*/(event:T)=>void/*/Function = null)
		{
			// specify the preCallback function in super() so data will be set before each callback.
			super(_setEvent);
			this._stopPropagation = stopPropagation;
		}
	
		// This variable is set before each callback runs
		private var _event:Object = null;
		private var _stopPropagation:Function = null;
		
		private function _setEvent(event:Object = null):void
		{
			_event = event;
		}
		
		/**
		 * This is the event object.
		 */
		public function get event():/*/T/*/Object
		{
			return _event;
		}
		
		/**
		 * This function will run callbacks immediately, setting the event variable before each one.
		 * @param event
		 */	
		public function dispatch(event:/*/T/*/Object):void
		{
			// remember previous value so it can be restored in case external code caused us to interrupt something else
			var prevEvent:Object = _event;
			_runCallbacksImmediately(event);
			_setEvent(prevEvent);
		}
		
		/**
		 * calls the stopPropagation function which was passed to the constructor.
		 */
		public function stopPropagation():void
		{
			if (_stopPropagation != null)
				_stopPropagation(event);
		}
	}
}
