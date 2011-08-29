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

package weave.primitives
{
	import weave.api.core.ILinkableVariable;
	import weave.api.getCallbackCollection;
	import weave.compiler.Compiler;
	import weave.core.LinkableString;

	/**
	 * @author adufilie
	 */
	public class LinkableFunction extends LinkableString
	{
		public function LinkableFunction()
		{
			super();
			getCallbackCollection(this).addImmediateCallback(this, handleChange);
		}
		
		/**
		 * The result of compiling <code>this.value</code>. 
		 */		
		private var _compiledMethod:Function;
		
		/**
		 * The Compiler object which compiles <code>this.value</code>. 
		 */		
		public const compiler:Compiler = new Compiler();
		
		/**
		 * Gets the compiled method for <code>this.value</code>.
		 * @return The compiled method or null if compiling failed. 
		 */		
		public function get compiledMethod():Function 
		{
			return _compiledMethod;
		}

		/**
		 * When <code>this.value</code> changes, this method is called and will compile the function.
		 */		
		private function handleChange():void
		{
			_compiledMethod = null;
			compile();
		}
		
		/**
		 * Calls the compiled method if it was successfully compiled. 
		 * @param thisArg The reference to the parent of the function. This is usually the 
		 * <code>this</code> pointer.
		 * @param argArray The array of arguments to pass to the function.
		 * @return The value returned by the compiled method.
		 */		
		public function apply(thisArg:*, argArray:Array = null):*
		{
			if (_compiledMethod == null)
				compile();
			
			return _compiledMethod.apply(thisArg, argArray);
		}
		
		/**
		 * Compile the value of <code>this.value</code> to a function call. 
		 */		
		public function compile():void
		{
			_compiledMethod = compiler.compileToFunction(value, null, false);
		}
	}
}
