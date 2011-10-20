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
	import flash.utils.Dictionary;
	import flash.utils.Proxy;
	import flash.utils.getQualifiedClassName;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableVariable;
	import weave.api.getCallbackCollection;
	import weave.compiler.Compiler;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableString;
	import weave.core.weave_internal;
	
	use namespace weave_internal;

	/**
	 * @author adufilie
	 */
	public class LinkableFunction extends LinkableString
	{
		public function LinkableFunction(ignoreRuntimeErrors:Boolean = false, useThisScope:Boolean = false)
		{
			super();
			_allLinkableFunctions[this] = true; // register this instance so the callbacks will trigger when the libraries change
			_ignoreRuntimeErrors = ignoreRuntimeErrors;
			_useThisScope = useThisScope;
			getCallbackCollection(this).addImmediateCallback(this, handleChange);
		}
		
		private var _ignoreRuntimeErrors:Boolean = false;
		private var _useThisScope:Boolean = false;
		private var _compiledMethod:Function = null;

		private function handleChange():void
		{
			_compiledMethod = null;
		}
		
		public function apply(thisArg:* = null, argArray:Array = null):*
		{
			if (_compiledMethod == null)
			{
				if (_macroProxy == null)
					_macroProxy = new ProxyObject(_hasMacro, evaluateMacro, null); // allows evaluating macros but not setting them
				_compiledMethod = _compiler.compileToFunction(value, _macroProxy, _ignoreRuntimeErrors, _useThisScope);
			}
			return _compiledMethod.apply(thisArg, argArray);
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////
		// static section
		
		/**
		 * This is a proxy object for use as a symbol table for the compiler.
		 */		
		private static var _macroProxy:ProxyObject = null;
		
		/**
		 * This function checks if a macro exists.
		 * @param macroName The name of a macro to check.
		 * @return A value of true if the specified macro exists, or false if it does not.
		 */
		private static function _hasMacro(macroName:String):Boolean
		{
			return macros.getObject(macroName) != null;
		}
		
		/**
		 * This function evaluates a macro specified in the macros hash map.
		 * @param macroName The name of the macro to evaluate.
		 * @return The result of evaluating the macro.
		 */
		public static function evaluateMacro(macroName:String):*
		{
			var lf:LinkableFunction = macros.getObject(macroName) as LinkableFunction;
			return lf ? lf.apply() : undefined;
		}
		
		/**
		 * This is a list of macros that can be used in any LinkableFunction expression.
		 */
		public static const macros:ILinkableHashMap = new LinkableHashMap(LinkableFunction);
		
		/**
		 * This is a list of libraries to include in the static compiler.
		 */
		public static const libraries:LinkableString = new LinkableString();
		
		{ /** begin static code block **/
			staticInit();
		} /** end static code block **/
		
		/**
		 * This function will initialize static variables.
		 */
		private static function staticInit():void
		{
			// when the libraries change, we need to update the compiler
			libraries.addImmediateCallback(null, handleLibrariesChange);
			libraries.value = getQualifiedClassName(WeaveAPI);
		}
		
		/**
		 * This is the static compiler to be used by every LinkableFunction.
		 */
		private static var _compiler:Compiler = null;
		private static var _allLinkableFunctions:Dictionary = new Dictionary(true); // the keys in this are LinkableFunction instances
		
		/**
		 * This function will update the static compiler when the static libraries change.
		 */		
		private static function handleLibrariesChange():void
		{
			_compiler = _getNewCompiler(true);
			for (var linkableFunction:Object in _allLinkableFunctions)
			{
				var lf:LinkableFunction = linkableFunction as LinkableFunction;
				if (!lf.wasDisposed)
					lf.triggerCallbacks();
			}
		}
		
		/**
		 * This function returns a new compiler initialized with the libraries specified by the public static libraries variable.
		 * @param reportErrors If this is true, errors will be reported through WeaveAPI.ErrorManager.
		 * @return A new initialized compiler.
		 */		
		private static function _getNewCompiler(reportErrors:Boolean):Compiler
		{
			var compiler:Compiler = new Compiler();
			for each (var row:Array in WeaveAPI.CSVParser.parseCSV(libraries.value))
			{
				try
				{
					compiler.includeLibraries.apply(null, row);
				}
				catch (e:Error)
				{
					if (reportErrors)
						WeaveAPI.ErrorManager.reportError(e);
				}
			}
			return compiler;
		}
		
//		/**
//		 * This function returns a new compiler initialized with the libraries specified by the public static libraries variable.
//		 * @return A new initialized compiler.
//		 */		
//		public static function getNewCompiler():Compiler
//		{
//			return _getNewCompiler(false);
//		}
	}
}
