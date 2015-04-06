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
	/**
	 * This is a LinkableVariable which limits its session state to Number values.
	 * @author adufilie
	 * @see weave.core.LinkableVariable
	 */
	public class LinkableNumber extends LinkableVariable
	{
		public function LinkableNumber(defaultValue:Number = NaN, verifier:Function = null, defaultValueTriggersCallbacks:Boolean = true)
		{
			// Note: Calling super() will set all the default values for member variables defined in the super class,
			// which means we can't set _sessionStateInternal = NaN here.
			super(Number, verifier, arguments.length ? defaultValue : undefined, defaultValueTriggersCallbacks);
		}

		public function get value():Number
		{
			return _sessionStateExternal;
		}
		public function set value(value:Number):void
		{
			setSessionState(value);
		}

		override public function setSessionState(value:Object):void
		{
			if (!(value is Number))
			{
				// special case for null and '' which would otherwise get converted to 0
				if (value == null || value === '')
					value = NaN;
				else
					value = Number(value);
			}
			super.setSessionState(value);
		}

		override protected function sessionStateEquals(otherSessionState:*):Boolean
		{
			// We must check for null here because we can't set _sessionStateInternal = NaN in the constructor.
			if (_sessionStateInternal === null)
				_sessionStateInternal = _sessionStateExternal = NaN;
			if (isNaN(_sessionStateInternal) && isNaN(otherSessionState))
				return true;
			return _sessionStateInternal == otherSessionState;
		}
	}
}
