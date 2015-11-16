/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package weavejs.core
{
	import weavejs.utils.Utils;

	/**
	 * This is a LinkableVariable which limits its session state to String values.
	 * @author adufilie
	 * @see weave.core.LinkableVariable
	 */
	public class LinkableString extends LinkableVariable
	{
		public function LinkableString(defaultValue:String = null, verifier:Function = null, defaultValueTriggersCallbacks:Boolean = true)
		{
			super(String, verifier, arguments.length ? defaultValue : undefined, defaultValueTriggersCallbacks);
		}

		public function get value():String
		{
			return _sessionStateExternal;
		}
		public function set value(value:String):void
		{
			setSessionState(value);
		}
		
		override public function setSessionState(value:Object):void
		{
			if (value != null)
				value = String(value);
			super.setSessionState(value);
		}
		
		private static var _init:* = Utils.preserveGetterSetters(LinkableString, 'value');
	}
}
