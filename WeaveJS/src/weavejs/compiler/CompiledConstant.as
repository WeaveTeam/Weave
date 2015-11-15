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
