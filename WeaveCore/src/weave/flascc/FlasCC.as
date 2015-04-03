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
