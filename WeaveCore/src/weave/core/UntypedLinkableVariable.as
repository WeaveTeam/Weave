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
	 * UntypedLinkableVariable
	 * This is a LinkableVariable that adds "get value" and "set value" functions for untyped values.
	 * 
	 * @author adufilie
	 */
	public class UntypedLinkableVariable extends LinkableVariable
	{
		public function UntypedLinkableVariable(defaultValue:Object = null, verifier:Function = null)
		{
			super(null, verifier);
			if (defaultValue != null)
			{
				delayCallbacks();
				value = defaultValue;
				// Resume callbacks one frame later when we know it is possible for
				// other classes to have a pointer to this object and retrieve the value.
				StageUtils.callLater(this, resumeCallbacks, null, false);
			}
		}

		public function get value():Object
		{
			return _sessionState;
		}
		public function set value(value:Object):void
		{
			setSessionState(value);
		}
	}
}
