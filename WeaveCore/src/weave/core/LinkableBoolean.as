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
	 * LinkableBoolean
	 * 
	 * @author adufilie
	 */
	public class LinkableBoolean extends LinkableVariable
	{
		public function LinkableBoolean(defaultValue:* = undefined, verifier:Function = null)
		{
			super(Boolean, verifier, defaultValue);
		}

		public function get value():Boolean
		{
			return _sessionState;
		}
		public function set value(value:Boolean):void
		{
			setSessionState(value);
		}

		override public function isUndefined():Boolean
		{
			return !_sessionStateWasSet;
		}

		override public function setSessionState(value:Object):void
		{
			if (value is String)
				value = ObjectUtil.stringCompare(value as String, "true", true) == 0;
			else if (value is Number)
				value = value != 0;
			super.setSessionState(value ? true : false);
		}
	}
}
