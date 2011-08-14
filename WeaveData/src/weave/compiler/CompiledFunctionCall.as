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
	/**
	 * This serves as a structure for storing the information required to make a function call.
	 * This is used in the EquationParser class to avoid parsing tokens multiple times.
	 * To avoid function call overhead, no public functions are not defined in this class.
	 * 
	 * @author adufilie
	 */
	public class CompiledFunctionCall implements ICompiledObject
	{
		public function CompiledFunctionCall(compiledName:ICompiledObject, compiledParams:Array)
		{
			constructor(compiledName, compiledParams);
		}
		/**
		 * This is the constructor code. The code is in a separate function because constructors do not get compiled.
		 */
		private function constructor(compiledName:ICompiledObject, compiledParams:Array):void
		{
			this.compiledMethod = compiledName;
			this.compiledParams = compiledParams;
			
			// if name is constant, evaluate it once now
			if (compiledName is CompiledConstant)
				evaluatedMethod = (compiledName as CompiledConstant).value;
			
			if (compiledParams)
			{
				this.evaluatedParams = new Array(compiledParams.length);
				// move constant values from the compiledParams array to the evaluatedParams array.
				for (var i:int = 0; i < compiledParams.length; i++)
					if (compiledParams[i] is CompiledConstant)
						evaluatedParams[i] = (compiledParams[i] as CompiledConstant).value;
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
	}
}
