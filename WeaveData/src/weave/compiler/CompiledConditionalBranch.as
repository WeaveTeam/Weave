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
	import weave.api.compiler.ICompiledObject;

	/**
	 * This serves as a structure for storing the information required to evaluate a conditional branch.
	 * This is used in the EquationParser class to avoid parsing tokens multiple times.
	 * To avoid function call overhead, no public functions are not defined in this class.
	 * 
	 * @author adufilie
	 */
	public class CompiledConditionalBranch implements ICompiledObject
	{
		public function CompiledConditionalBranch(condition:ICompiledObject, trueBranch:ICompiledObject, falseBranch:ICompiledObject)
		{
			this.condition = condition;
			this.trueBranch = trueBranch;
			this.falseBranch = falseBranch;
		}
		/**
		 * This is the condition before the ?:
		 */
		public var condition:ICompiledObject;
		/**
		 * This is the true branch between the ? and :
		 */
		public var trueBranch:ICompiledObject;
		/**
		 * This is the false branch after the ?:
		 */
		public var falseBranch:ICompiledObject;
	}
}
