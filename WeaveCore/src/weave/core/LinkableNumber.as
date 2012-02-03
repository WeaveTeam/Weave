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
	import mx.utils.ObjectUtil;
	
	import weave.api.WeaveAPI;
	
	/**
	 * LinkableNumber
	 * 
	 * 
	 * @author adufilie
	 */
	public class LinkableNumber extends LinkableVariable
	{
		public function LinkableNumber(defaultValue:Number = NaN, verifier:Function = null)
		{
			_sessionState = NaN; // set to NaN instead of null because null==0
			super(Number, verifier, defaultValue);
		}

		public function get value():Number
		{
			return _sessionState;
		}
		public function set value(value:Number):void
		{
			setSessionState(value);
		}

		override public function isUndefined():Boolean
		{
			return !_sessionStateWasSet || isNaN(_sessionState);
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
			// We must check for null here because "_sessionState = NaN" in the constructor
			// does not take affect until after the super() constructor finishes.
			if (_sessionState == null)
				_sessionState = NaN;
			if (isNaN(_sessionState) && isNaN(otherSessionState))
				return true;
			return _sessionState == otherSessionState;
		}
	}
}
