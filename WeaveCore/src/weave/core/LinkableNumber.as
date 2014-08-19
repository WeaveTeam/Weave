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
			super(Number, verifier, defaultValue, defaultValueTriggersCallbacks);
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
