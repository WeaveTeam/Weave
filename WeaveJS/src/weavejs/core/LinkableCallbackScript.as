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

package weavejs.core
{
	import weavejs.api.core.ICallbackCollection;
	import weavejs.api.core.ILinkableObject;
	import weavejs.util.JS;
	
	public class LinkableCallbackScript implements ILinkableObject
	{
		public function LinkableCallbackScript()
		{
			var callbacks:ICallbackCollection = Weave.getCallbacks(this);
			callbacks.addImmediateCallback(null, _immediateCallback);
			callbacks.addGroupedCallback(null, _groupedCallback);
		}
		
		public var variables:LinkableHashMap = Weave.linkableChild(this, new LinkableHashMap());
		public var script:LinkableString = Weave.linkableChild(this, new LinkableString());
		public var delayWhileBusy:LinkableBoolean = Weave.linkableChild(this, new LinkableBoolean(true));
		public var groupedCallback:LinkableBoolean = Weave.linkableChild(this, new LinkableBoolean(true));
		
		private var _compiledFunction:Function;
		
		public function get(variableName:String):ILinkableObject
		{
			return variables.getObject(variableName);
		}
		
		private function _immediateCallback():void
		{
			if (!groupedCallback.value)
				_runScript();
		}
		
		private function _groupedCallback():void
		{
			if (groupedCallback.value)
				_runScript();
		}
		
		private function _runScript():void
		{
			if (delayWhileBusy.value && Weave.isBusy(this))
				return;
			
			if (!script.value)
				return;
			
			try
			{
				if (Weave.detectChange(this, script))
					_compiledFunction = JS.compile(script.value);
				_compiledFunction.call(this);
			}
			catch (e:Error)
			{
				JS.error(e);
			}
		}
	}
}
