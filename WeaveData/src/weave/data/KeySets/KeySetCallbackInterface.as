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

package weave.data.KeySets
{
	import weave.core.CallbackCollection;
	
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
