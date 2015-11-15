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

package weavejs.compiler
{
	/**
	 * This serves as a structure for storing the information required to make a function call.
	 * This is used in the Compiler class to avoid parsing tokens multiple times.
	 * To avoid function call overhead, no public functions are not defined in this class.
	 * 
	 * @author adufilie
	 */
	public class CompiledFunctionCall implements ICompiledObject
	{
		/**
		 * @param compiledMethod
		 * @param compiledParams
		 * @see #compiledMethod
		 * @see #compiledParams
		 */
		public function CompiledFunctionCall(compiledMethod:ICompiledObject, compiledParams:Array)
		{
			this.compiledMethod = compiledMethod;
			this.compiledParams = compiledParams;
			
			if (!compiledMethod)
				throw new Error("compiledMethod cannot be null");
			
			for each (var param:Object in compiledParams)
				if (param == null)
					throw new Error("compiledParams cannot contain nulls");
			
			evaluateConstants();
		}
		
		/**
		 * This is called in the constructor.  It can also be called later after compiledParams is modified.
		 */		
		public function evaluateConstants():void
		{
			// if name is constant, evaluate it once now
			if (compiledMethod is CompiledConstant)
				evaluatedMethod = (compiledMethod as CompiledConstant).value;
			else
				evaluatedMethod = null;
			
			if (compiledParams)
			{
				if (!evaluatedParams)
					evaluatedParams = new Array(compiledParams.length);
				else
					evaluatedParams.length = compiledParams.length;
				
				// move constant values from the compiledParams array to the evaluatedParams array.
				for (var i:int = 0; i < compiledParams.length; i++)
					if (compiledParams[i] is CompiledConstant)
						evaluatedParams[i] = (compiledParams[i] as CompiledConstant).value;
			}
			else
			{
				evaluatedParams = null;
			}
		}
		
		/**
		 * Makes a deep copy of this and any nested CompiledFunctionCall objects suitable for recursive function execution.
		 */
		public function clone():CompiledFunctionCall
		{
			return _clone(this) as CompiledFunctionCall;
		}
		
		private static function _clone(obj:Object, i:int = -1, a:Array = null):*
		{
			var cfc:CompiledFunctionCall = obj as CompiledFunctionCall;
			if (cfc)
				return new CompiledFunctionCall(_clone(cfc.compiledMethod), cfc.compiledParams && cfc.compiledParams.map(_clone));
			return obj;
		}
		
		/**
		 * This is a compiled object that evaluates to a method.
		 */
		public var compiledMethod:ICompiledObject;
		/**
		 * This is an Array of CompiledObjects that must be evaluated before calling the method.
		 */
		public var compiledParams:Array;
		/**
		 * This is used to keep track of which compiled parameter is currently being evaluated.
		 */
		public var evalIndex:int;
		/**
		 * When the function is called as a property of an object, this will store a pointer to the object
		 * so that it can be used as the 'this' parameter in Function.apply().
		 */
		public var evaluatedHost:Object;
		/**
		 * When the function is called as a property of an object, this will store the property name in case the host is a Proxy object.
		 */
		public var evaluatedMethodName:Object;
		/**
		 * This is used to store the result of evaluating the compiledMethod before evaluating the parameters.
		 */
		public var evaluatedMethod:Object;
		/**
		 * This is an Array of constants to use as parameters to the method.
		 * This Array is used to store the results of evaluating the compiledParams Array before calling the method.
		 */
		public var evaluatedParams:Array;
		/**
		 * An optional set of original tokens to use in place of this CompiledFunctionCall when decompiling.
		 */		
		public var originalTokens:Array;
	}
}
