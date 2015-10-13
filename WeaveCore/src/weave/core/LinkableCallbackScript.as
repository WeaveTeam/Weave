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
	import weave.api.detectLinkableObjectChange;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableDynamicObject;
	import weave.api.core.ILinkableObject;
	import weave.api.core.ILinkableVariable;
	import weave.compiler.Compiler;
	import weave.compiler.ProxyObject;
	
	public class LinkableCallbackScript implements ILinkableObject
	{
		public function LinkableCallbackScript()
		{
			_callbacks = WeaveAPI.SessionManager.getCallbackCollection(this);
			_callbacks.addImmediateCallback(null, selfCallback);
		}
		
		public const variables:LinkableHashMap = registerLinkableChild(this, new LinkableHashMap());
		public const script:LinkableString = registerLinkableChild(this, new LinkableString());
		public const delayWhileBusy:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		
		private var _callbacks:ICallbackCollection;
		private const _symbolTableProxy:ProxyObject = new ProxyObject(hasValue, getValue, null);
		private var _compiledScript:Function = null;
		private static const _compiler:Compiler = new Compiler(true);
		
		public function getValue(name:String):*
		{
			var variable:ILinkableObject = variables.getObject(name);
			
			// if it's not a variable, it's a macro
			if (!variable)
				return LinkableFunction.evaluateMacro(name);
			
			if (variable is ILinkableDynamicObject)
				variable = (variable as ILinkableDynamicObject).internalObject;
			
			if (variable is ILinkableVariable)
				return (variable as ILinkableVariable).getSessionState();
			
			return variable
		}
		
		public function hasValue(name:String):Boolean
		{
			return variables.getObject(name) != null
				|| LinkableFunction.macros.getObject(name) != null;
		}
		
		private function selfCallback():void
		{
			if (delayWhileBusy.value && WeaveAPI.SessionManager.linkableObjectIsBusy(this))
				return;
			
			if (!script.value)
				return;
			
			try
			{
				if (detectLinkableObjectChange(selfCallback, script))
					_compiledScript = _compiler.compileToFunction(script.value, _symbolTableProxy, reportError, false);
				
				_compiledScript.apply(this);
			}
			catch (e:Error)
			{
				reportError(e);
			}
		}
	}
}
