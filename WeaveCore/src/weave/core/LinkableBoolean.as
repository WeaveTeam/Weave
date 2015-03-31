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
	import mx.utils.ObjectUtil;
	
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
			return _sessionStateExternal;
		}
		public function set value(value:Boolean):void
		{
			setSessionState(value);
		}

		override public function setSessionState(value:Object):void
		{
			if (value is String)
				value = ObjectUtil.stringCompare(value as String, "true", true) == 0;
			super.setSessionState(value ? true : false);
		}
	}
}
