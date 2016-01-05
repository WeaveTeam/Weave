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
	import weavejs.api.data.IKeySetCallbackInterface;
	import weavejs.core.CallbackCollection;
	
	/**
	 * Provides an interface for getting KeySet event-related information.
	 */
	public class KeySetCallbackInterface extends CallbackCollection implements IKeySetCallbackInterface
	{
		public function KeySetCallbackInterface()
		{
			// specify the preCallback function in super() so list callback
			// variables will be set before each change callback.
			super(setCallbackVariables);
		}
		
		private var _keysAdded:Array = [];
		private var _keysRemoved:Array = [];
		
		private function setCallbackVariables(keysAdded:Array, keysRemoved:Array):void
		{
			_keysAdded = keysAdded;
			_keysRemoved = keysRemoved;
		}
		
		public function flushKeys():void
		{
			if (_keysAdded.length || _keysRemoved.length)
				_runCallbacksImmediately(_keysAdded, _keysRemoved);
			setCallbackVariables([], []); // reset the variables to new arrays
		}
		
		public function get keysAdded():Array
		{
			return _keysAdded;
		}
		public function set keysAdded(qkeys:Array):void
		{
			_keysAdded = qkeys;
		}
		
		public function get keysRemoved():Array
		{
			return _keysRemoved;
		}
		public function set keysRemoved(qkeys:Array):void
		{
			_keysRemoved = qkeys;
		}
	}
}
