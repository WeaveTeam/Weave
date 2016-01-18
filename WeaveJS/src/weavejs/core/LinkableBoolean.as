/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package weavejs.core
{
	/**
	 * This is a LinkableVariable which limits its session state to Boolean values.
	 * @author adufilie
	 * @see weave.core.LinkableVariable
	 */
	public class LinkableBoolean extends LinkableVariable
	{
		public function LinkableBoolean(defaultValue:* = undefined, verifier:Function = null, defaultValueTriggersCallbacks:Boolean = true)
		{
			super(Boolean, verifier, defaultValue, defaultValueTriggersCallbacks);
		}

		public function get value():Boolean
		{
			return Boolean(_sessionStateExternal);
		}
		public function set value(value:Boolean):void
		{
			setSessionState(value);
		}

		override public function getSessionState():Object
		{
			return Boolean(_sessionStateExternal);
		}
		
		override public function setSessionState(value:Object):void
		{
			if (value is String)
				value = (value === 'true');
			super.setSessionState(value ? true : false);
		}
	}
}
