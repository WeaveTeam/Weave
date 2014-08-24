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

package weave.flascc
{
	import flash.utils.ByteArray;

	/**
	 * @see #call()
	 */
	public class FlasCC
	{
		/**
		 * Stores the current RAM position, calls the specified FlasCC function, then restores the old RAM position.
		 * All FlasCC functions should be called this way to avoid crashing due to ExternalInterface call-ins
		 * interrupting current operations and mangling the RAM.
		 * @param flascc_function The FlasCC function to call.
		 * @param parameters Parameters to pass to the FlasCC function.
		 * @return The result from the FlasCC function.
		 */
		public static function call(flascc_function:Function, ...parameters):*
		{
			var ram:ByteArray = ram_init;
			var pos:int = ram.position;
			try
			{
				return flascc_function.apply(null, parameters);
			}
			finally
			{
				ram.position = pos;
			}
		}
	}
}
