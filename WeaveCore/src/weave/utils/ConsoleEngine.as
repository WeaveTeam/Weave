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

package weave.utils
{
	import avmplus.DescribeType;
	
	import flash.external.ExternalInterface;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	
	import mx.core.UIComponent;
	import mx.utils.ObjectUtil;
	
	import weave.api.core.ILinkableObject;
	import weave.api.getCallbackCollection;
	import weave.api.reportError;
	import weave.compiler.Compiler;
	import weave.compiler.GlobalLib;
	import weave.compiler.ICompiledObject;
	import weave.compiler.ProxyObject;
	import weave.compiler.StandardLib;
	import weave.core.WeaveXMLDecoder;
	import weave.primitives.MethodChainProxy;
	
	public class ConsoleEngine
	{
		public function ConsoleEngine()
		{
			compiler.includeLibraries(GlobalLib, WeaveAPI, ObjectUtil, WeaveAPI.SessionManager, DescribeType, DebugUtils);
			compiler.setHashOperator(debugHelper);
		}
		
		/**
		 * The compiler used by the console.
		 */
		public const compiler:Compiler = new Compiler();
		
		/**
		 * This is the context in which expressions will be evaluated (The "this" argument passed to Function.apply).
		 * This value can be set as necessary.
		 */
		public var context:Object;
		
		/**
		 * A set of additional functions available in the console.
		 * These can be customized as necessary.
		 */
		public const consoleMethods:Object = {
			'exec': JavaScript.exec,
			'call': function(...args):* {
				ExternalInterface.marshallExceptions = true;
				return ExternalInterface.call.apply(ExternalInterface, args);
			},
			'application': WeaveAPI.topLevelApplication,
			'toString': ObjectUtil.toString as Function,
			'trace': weaveTrace,
			'style': styleProxy,
			'chain': methodChainer,
			'display': DebugUtils.debugDisplayList,
			'debugCompiler': function(script:String):String { return ObjectUtil.toString(new Compiler().compileToObject(script), null, 'evaluatedMethod,evaluatedHost,evaluatedMethodName,evaluatedParams,evalIndex,originalTokens'.split(',')); },
			'_': {}
		};
		
		
		private const symbolTable:Object = consoleMethods;
		
		private function styleProxy(component:UIComponent):ProxyObject
		{
			return new ProxyObject(
				function hasProp(name:*):Boolean { return component.getStyle(name) !== undefined; },
				function getProp(name:*):* { return component.getStyle(name); },
				function setProp(name:*, value:*):void { component.setStyle(name, value); }
			);
		}
		
		private function methodChainer(...args):*
		{
			return new MethodChainProxy(null, args);
		}
		
		private function debugHelper(arg:* = null):*
		{
			var type:String = typeof(arg);
			if (arg == null || type != 'object' && type != 'function')
				return debugLookup(arg);
			return debugId(arg);
		}
		
		/**
		 * @throws Error if the script could not be compiled.
		 */
		public function runCommand(script:String):*
		{
			var shouldReportError:*;
			function errorHandler(e:*):void
			{
				// print the stack trace only if the error occurs after the initial function call
				if (shouldReportError)
				{
					reportError(e);
					return;
				}
				else
				{
					// this is the first error that occurred
					shouldReportError = e;
					var err:Error = e as Error; // need to set variable to avoid asdoc error
					if (err)
						trace(err.getStackTrace());
				}
			}
			
			var result:*;
			var decompiled:String;
			var obj:ICompiledObject = compiler.compileToObject(script);
			var func:Function = compiler.compileObjectToFunction(obj, symbolTable, errorHandler, true);
			result = func.apply(context);
			if (shouldReportError)
				result = String(shouldReportError);
			
			shouldReportError = true; // future errors should be reported
			
			return result;
		}
	}
}
