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

package weavejs.data.key
{
	import weavejs.core.CallbackCollection;
	
	/**
	 * Provides an interface for getting KeySet event-related information.
	 */
	public class KeySetCallbackInterface extends CallbackCollection
	{
		public function KeySetCallbackInterface()
		{
			// specify the preCallback function in super() so list callback
			// variables will be set before each change callback.
			super(setCallbackVariables);
		}
		private function setCallbackVariables(keysAdded:Array, keysRemoved:Array):void
		{
			this.keysAdded = keysAdded;
			this.keysRemoved = keysRemoved;
		}
		
		/**
		 * This function should be called when keysAdded and keysRemoved are ready to be shared with the callbacks.
		 * The keysAdded and keysRemoved Arrays will be reset to empty Arrays after the callbacks finish running.
		 */	
		public function flushKeys():void
		{
			if (keysAdded.length || keysRemoved.length)
				_runCallbacksImmediately(keysAdded, keysRemoved);
			setCallbackVariables([], []); // reset the variables to new arrays
		}
		
		/**
		 * The keys that were most recently added, causing callbacks to trigger.
		 * This can be used as a buffer prior to calling flushKeys().
		 * @see #flushKeys()
		 */
		public var keysAdded:Array = [];
		
		/**
		 * The keys that were most recently removed, causing callbacks to trigger.
		 * This can be used as a buffer prior to calling flushKeys().
		 * @see #flushKeys()
		 */
		public var keysRemoved:Array = [];
	}
}
