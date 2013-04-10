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

package weave.compiler
{
	import mx.utils.ObjectUtil;
	import mx.utils.StringUtil;

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
		 * @param decompile
		 * @see #decompile
		 * @see #compiledParams
		 * @see #compiledMethod
		 */
		public function CompiledFunctionCall(compiledMethod:ICompiledObject, compiledParams:Array, decompile:Function)
		{
			this.compiledMethod = compiledMethod;
			this.compiledParams = compiledParams;
			this.decompile = decompile;
			
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
				evaluatedParams = new Array(compiledParams.length);
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
		 * This is used to store the result of evaluating the compiledMethod before evaluating the parameters.
		 */
		public var evaluatedMethod:Object;
		/**
		 * This is an Array of constants to use as parameters to the method.
		 * This Array is used to store the results of evaluating the compiledParams Array before calling the method.
		 */
		public var evaluatedParams:Array;
		
		/**
		 * A function that generates source code from this CompiledFunctionCall.
		 * The function signature must be:  function(call:CompiledFunctionCall):String
		 */		
		public var decompile:Function;
		
		/**
		 * This will call <code>decompile(this)</code> or throw an error if it is null.
		 */		
		public function toString():String
		{
			if (decompile is Function)
				return decompile(this);
			
			throw new Error("Missing decompile function");
		}
	}
}
