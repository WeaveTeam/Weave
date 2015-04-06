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

package weave.utils
{
	import mx.collections.ArrayList;
	import mx.controls.List;
	import mx.formatters.NumberFormatter;

	public class FileUtils
	{
		private static var formater:NumberFormatter = new NumberFormatter();
		
		public function FileUtils()
		{
			
		}
		public static function parse(size:Number, precision:Number):String
		{
			var i:int = 0;
			var sizes:Array = ["B", "KB", "MB", "GB", "TB"];
			
			while( (size/1024) > 1 ) {
				size /= 1024;
				i++;
			}
			
			formater.precision = precision;
			return formater.format(size) + " " + sizes[i];
		}
	}
}