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
	 * This serves as a wrapper for a constant value to remember that it was compiled.
	 * This is used in the Compiler class to avoid parsing tokens multiple times.
	 * To avoid function call overhead, no public functions are defined in this class.
	 * 
	 * @author adufilie
	 */
	public class CompiledConstant implements ICompiledObject
	{
		/**
		 * @param name The name of the constant.
		 * @param value The constant that was compiled.
		 */
		public function CompiledConstant(name:String, value:*)
		{
			this.name = name;
			this.value = value;
		}
		/**
		 * This is the name of the constant.  This is used for debugging/decompiling.
		 */
		public var name:String;
		/**
		 * This is the constant that was compiled.
		 */
		public var value:* = null;
	}
}
