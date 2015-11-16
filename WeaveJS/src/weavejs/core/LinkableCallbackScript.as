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
	import weavejs.Weave;
	import weavejs.WeaveAPI;
	import weavejs.api.core.ICallbackCollection;
	import weavejs.api.core.ILinkableObject;
	import weavejs.compiler.Compiler;
	import weavejs.compiler.ProxyObject;
	
	public class LinkableCallbackScript implements ILinkableObject
	{
		public function LinkableCallbackScript()
		{
			var callbacks:ICallbackCollection = WeaveAPI.SessionManager.getCallbackCollection(this);
			callbacks.addImmediateCallback(null, _immediateCallback);
			callbacks.addGroupedCallback(null, _groupedCallback);
		}
		
		public const variables:LinkableHashMap = registerLinkableChild(this, new LinkableHashMap());
		public const script:LinkableString = registerLinkableChild(this, new LinkableString());
		public const delayWhileBusy:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		public const groupedCallback:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		
		private const _symbolTableProxy:ProxyObject = new ProxyObject(hasVariable, getVariable, null);
		private var _compiledScript:Function = null;
		private static const _compiler:Compiler = new Compiler(true);
		
		public function getVariable(name:String):*
		{
			return variables.getObject(name)
				|| LinkableFunction.evaluateMacro(name);
		}
		
		public function hasVariable(name:String):Boolean
		{
			return variables.getObject(name) != null
				|| LinkableFunction.macros.getObject(name) != null;
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
			if (delayWhileBusy.value && WeaveAPI.SessionManager.linkableObjectIsBusy(this))
				return;
			
			if (!script.value)
				return;
			
			try
			{
				if (detectLinkableObjectChange(_runScript, script))
					_compiledScript = _compiler.compileToFunction(script.value, _symbolTableProxy, Weave.error, false);
				
				_compiledScript.apply(this);
			}
			catch (e:Error)
			{
				Weave.error(e);
			}
		}
	}
}
