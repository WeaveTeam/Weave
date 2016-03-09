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
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import weave.api.core.ILinkableHashMap;
	import weave.api.detectLinkableObjectChange;
	import weave.api.getCallbackCollection;
	import weave.api.getLinkableOwner;
	import weave.api.registerLinkableChild;
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
		public static var enabled:Boolean = true;
		
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
			super(StandardLib.unIndent(defaultValue));
			macroLibraries.addImmediateCallback(this, triggerCallbacks, false, true);
			getCallbackCollection(macros).addImmediateCallback(this, handleMacros, false, true);
			_ignoreRuntimeErrors = ignoreRuntimeErrors;
			_useThisScope = useThisScope;
			_paramNames = paramNames && paramNames.concat();
		}
		
		private var _catchErrors:Boolean = false;
		private var _ignoreRuntimeErrors:Boolean = false;
		private var _useThisScope:Boolean = false;
		private var _compiledMethod:Function = null;
		private var _paramNames:Array = null;
		private var _isFunctionDefinition:Boolean = false;
		private var _triggerCount:uint = 0;
		
		private function handleMacros():void
		{
			if (getLinkableOwner(this) != macros)
				triggerCallbacks();
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
			if (_triggerCount != triggerCounter)
			{
				// if this LinkableFunction is in the macros list, errors should be caught and reported.
				if (macros.getName(this))
					_catchErrors = true;
				
				_triggerCount = triggerCounter;
				// in case compile fails, prevent re-compiling erroneous code
				_compiledMethod = RETURN_UNDEFINED;
				_isFunctionDefinition = false;
				
				if (!enabled)
					return;
				
				if (_macroProxy == null)
					_macroProxy = new ProxyObject(_hasMacro, evaluateMacro, null, callMacro); // allows evaluating macros but not setting them
				
				if (detectLinkableObjectChange(_getNewCompiler, macroLibraries))
					_compiler = _getNewCompiler(true);
				
				var object:ICompiledObject = _compiler.compileToObject(value);
				_isFunctionDefinition = _compiler.compiledObjectIsFunctionDefinition(object);
				_compiledMethod = _compiler.compileObjectToFunction(object, _macroProxy, errorHandler, _useThisScope, _paramNames);
			}
		}
		
		private function errorHandler(e:*):Boolean
		{
			if (debug)
				reportError(e);
			
			if (_ignoreRuntimeErrors || debug)
				return true;
			
			if (_catchErrors)
			{
				reportError(e);
				return false;
			}
			
			throw e;
		}
		
		/**
		 * This gets the length property of the generated Function.
		 */
		public function get length():int
		{
			if (_triggerCount != triggerCounter)
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
			if (_triggerCount != triggerCounter)
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
			if (_triggerCount != triggerCounter)
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
		
		/**
		 * This function evaluates a macro specified in the macros hash map,
		 * catching and reporting any errors that are thrown.
		 * @param macroName The name of the macro to evaluate.
		 * @return The result of evaluating the macro.
		 */
		public static function evaluateMacro(macroName:String):*
		{
			var lf:LinkableFunction = macros.getObject(macroName) as LinkableFunction;
			if (!lf)
				return undefined;
			if (lf._triggerCount != lf.triggerCounter)
				lf.validate();
			if (lf._isFunctionDefinition)
				return lf;
			return lf.apply();
		}
		public static function callMacro(macroName:String, ...params):*
		{
			// error catching/reporting is handled automatically for LinkableFunctions in the macros list.
			var lf:LinkableFunction = macros.getObject(macroName) as LinkableFunction;
			return lf ? lf.apply(null, params) : undefined;
		}
		public static function applyMacro(macroName:String, params:Array = null):*
		{
			// error catching/reporting is handled automatically for LinkableFunctions in the macros list.
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
		public static const macroLibraries:LinkableVariable = registerLinkableChild(WeaveAPI.globalHashMap, new LinkableVariable(null, verifyLibraries));

		private static function verifyLibraries(state:Object):Boolean
		{
			var array:Array = state as Array;
			
			// backwards compatibility for String
			if (state is String)
				array = WeaveAPI.CSVParser.parseCSVRow(state as String);
			
			// modify session state using deprecated class replacements
			if (array)
				array = array.map(function(name:String, i:*, a:*):String {
					if (ClassUtils.isClassDeprecated(name))
						return getQualifiedClassName(ClassUtils.getClassDefinition(name));
					return name;
				});
			
			// if we don't have any changes, use the original array
			if (StandardLib.compare(array, state) == 0)
				return true;
			
			// use the new array
			macroLibraries.setSessionState(array);
			return false;
		}
		
		/**
		 * This function will add a library to the static list of macro libraries if it is not already added.
		 * @param libraryQName A library to add to the list of static libraries.
		 */
		public static function includeMacroLibrary(libraryQName:String):void
		{
			var array:Array = macroLibraries.getSessionState() as Array || [];
			if (array.indexOf(libraryQName) < 0)
			{
				array.push(libraryQName);
				macroLibraries.setSessionState(array);
			}
		}
		
		/**
		 * This is the static compiler to be used by every LinkableFunction.
		 */
		private static var _compiler:Compiler = null;
		private static var _allLinkableFunctions:Dictionary = new Dictionary(true); // the keys in this are LinkableFunction instances
		
		/**
		 * This function returns a new compiler initialized with the libraries specified by the public static libraries variable.
		 * @param reportErrors If this is true, errors will be reported through WeaveAPI.ErrorManager.
		 * @return A new initialized compiler.
		 */		
		private static function _getNewCompiler(reportErrors:Boolean):Compiler
		{
			var compiler:Compiler = new Compiler();
			try
			{
				compiler.includeLibraries.apply(null, macroLibraries.getSessionState() as Array);
			}
			catch (e:Error)
			{
				if (reportErrors)
					reportError(e);
			}
			return compiler;
		}
		
		/**
		 * Tests if an expression is a single, valid symbol name.
		 */
		public static function isValidSymbolName(expression:String):Boolean
		{
			if (!_compiler)
				_compiler = _getNewCompiler(true);
			return _compiler.isValidSymbolName(expression);
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
