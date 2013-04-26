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
	import flash.utils.getQualifiedClassName;
	
	import mx.utils.StringUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableHashMap;
	import weave.api.getCallbackCollection;
	import weave.api.reportError;
	import weave.compiler.Compiler;
	import weave.compiler.ICompiledObject;
	import weave.compiler.ProxyObject;
	import weave.compiler.StandardLib;
	
	/**
	 * LinkableFunction allows a function to be defined by a String that can use macros defined in the static macros hash map.
	 * Libraries listed in macroLibraries variable will be included when compiling the function.
	 * 
	 * @author adufilie
	 */
	public class LinkableFunction extends LinkableString
	{
		/**
		 * Debug mode. 
		 */		
		public static var debug:Boolean = false;
		
		/**
		 * @param defaultValue The default function definition.
		 * @param ignoreRuntimeErrors If this is true, errors thrown during evaluation of the function will be caught and values of undefined will be returned.
		 * @param useThisScope When true, variable lookups will be evaluated as if the function were in the scope of the thisArg passed to the apply() function.
		 * @param paramNames An Array of parameter names that can be used in the function definition.
		 */
		public function LinkableFunction(defaultValue:String = null, ignoreRuntimeErrors:Boolean = false, useThisScope:Boolean = false, paramNames:Array = null)
		{
			super(unIndent(defaultValue));
			_allLinkableFunctions[this] = true; // register this instance so the callbacks will trigger when the libraries change
			_ignoreRuntimeErrors = ignoreRuntimeErrors;
			_useThisScope = useThisScope;
			_paramNames = paramNames && paramNames.concat();
			getCallbackCollection(this).addImmediateCallback(this, handleChange);
		}
		
		private var _ignoreRuntimeErrors:Boolean = false;
		private var _useThisScope:Boolean = false;
		private var _compiledMethod:Function = null;
		private var _paramNames:Array = null;
		private var _isFunctionDefinition:Boolean = false;

		/**
		 * This is called whenever the session state changes.
		 */
		private function handleChange():void
		{
			// do not compile immediately because we don't want to throw an error at this time.
			_compiledMethod = null;
		}
		
		/**
		 * This is used as a placeholder to prevent re-compiling erroneous code.
		 */
		private static function RETURN_UNDEFINED(..._):* { return undefined; }
		
		/**
		 * This will attempt to compile the function.  An Error will be thrown if this fails.
		 */
		public function validate():void
		{
			if (_compiledMethod == null)
			{
				// in case compile fails, prevent re-compiling erroneous code
				_compiledMethod = RETURN_UNDEFINED;
				_isFunctionDefinition = false;
				
				if (_macroProxy == null)
					_macroProxy = new ProxyObject(_hasMacro, _getMacro, null, evaluateMacro); // allows evaluating macros but not setting them
				var object:ICompiledObject = _compiler.compileToObject(value);
				_isFunctionDefinition = _compiler.compiledObjectIsFunction(object);
				_compiledMethod = _compiler.compileObjectToFunction(object, _macroProxy, _ignoreRuntimeErrors || debug, _useThisScope, _paramNames);
			}
		}
		
		/**
		 * This gets the length property of the generated Function.
		 */
		public function get length():int
		{
			if (_compiledMethod == null)
				validate();
			return _compiledMethod.length;
		}
		
		/**
		 * This will evaluate the function with the specified parameters.
		 * @param thisArg The value of 'this' to be used when evaluating the function.
		 * @param argArray An Array of arguments to be passed to the compiled function.
		 * @return The result of evaluating the function.
		 */
		public function apply(thisArg:* = null, argArray:Array = null):*
		{
			if (_compiledMethod == null)
				validate();
			return _compiledMethod.apply(thisArg, argArray);
		}
		
		/**
		 * This will evaluate the function with the specified parameters.
		 * @param thisArg The value of 'this' to be used when evaluating the function.
		 * @param args Arguments to be passed to the compiled function.
		 * @return The result of evaluating the function.
		 */
		public function call(thisArg:* = null, ...args):*
		{
			if (_compiledMethod == null)
				validate();
			return _compiledMethod.apply(thisArg, args);
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
		
		private static function _getMacro(macroName:String):*
		{
			var lf:LinkableFunction = macros.getObject(macroName) as LinkableFunction;
			if (!lf)
				return undefined;
			if (lf._isFunctionDefinition)
				return lf;
			return lf.apply();
		}
		
		/**
		 * This function evaluates a macro specified in the macros hash map.
		 * @param macroName The name of the macro to evaluate.
		 * @param params The parameters to pass to the macro.
		 * @return The result of evaluating the macro.
		 */
		public static function evaluateMacro(macroName:String, ...params):*
		{
			var lf:LinkableFunction = macros.getObject(macroName) as LinkableFunction;
			return lf ? lf.apply(null, params) : undefined;
		}
		
		/**
		 * This is a list of macros that can be used in any LinkableFunction expression.
		 */
		public static const macros:ILinkableHashMap = new LinkableHashMap(LinkableFunction);
		
		/**
		 * This is a list of libraries to include in the static compiler for macros.
		 */
		public static const macroLibraries:LinkableString = new LinkableString();
		
		/**
		 * This function will add a library to the static list of macro libraries if it is not already added.
		 * @param libraryQName A library to add to the list of static libraries.
		 */
		public static function includeMacroLibrary(libraryQName:String):void
		{
			var rows:Array = WeaveAPI.CSVParser.parseCSV(macroLibraries.value);
			for each (var row:Array in rows)
				if (row.indexOf(libraryQName) >= 0)
					return;
			rows.push([libraryQName]);
			macroLibraries.value = WeaveAPI.CSVParser.createCSV(rows);
		}
		
		staticInit();
		
		/**
		 * This function will initialize static variables.
		 */
		private static function staticInit():void
		{
			// when the libraries change, we need to update the compiler
			macroLibraries.addImmediateCallback(null, handleLibrariesChange);
			macroLibraries.value = getQualifiedClassName(WeaveAPI);
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
			for each (var row:Array in WeaveAPI.CSVParser.parseCSV(macroLibraries.value))
			{
				try
				{
					compiler.includeLibraries.apply(null, row);
				}
				catch (e:Error)
				{
					if (reportErrors)
						reportError(e);
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
		
		/**
		 * Takes a script where all lines have been indented, removes the common indentation from all lines and replaces each tab with four spaces.
		 * The common indentation is naively assumed to be the same as the first non-blank line in the script.
		 * @param script A script.
		 * @return The modified script.
		 */		
		public static function unIndent(script:String):String
		{
			if (script == null)
				return null;
			script = StandardLib.replace(script, '\r\n','\n','\r','\n');
			while (StringUtil.isWhitespace(script.substr(-1)))
				script = script.substr(0, -1);
			var lines:Array = script.split('\n');
			while (!lines[0])
				lines.shift();
			var indent:int = 0;
			var line:String = lines[0];
			while (line.charAt(indent) == '\t')
				indent++;
			lines.forEach(
				function(line:String, index:int, lines:Array):void
				{
					var i:int = 0;
					var spaces:String = '';
					while (line.charAt(i) == '\t')
						if (i++ >= indent)
							spaces += '    ';
					
					lines[index] = spaces + line.substr(i);
				}
			);
			return lines.join('\n') + '\n';
		}
	}
}
