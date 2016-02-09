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

package weavejs.util
{
	public class DateUtils
	{
		public static function date_parse(date:String, fmt:String, force_utc:Boolean = false, force_local:Boolean = false):*
		{
			return null;
		}
		public static function date_format(date:Object, fmt:String):String
		{
			return String(date);
		}
		public static function dates_detect(dates:*, formats:Array):Array
		{
			return [];
		}
	}
}
