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


import weavejs.util.JS;

package weavejs.util
{
	public class DateUtils
	{
		public static function date_parse(date:String, fmt:String, force_utc:Boolean = false, force_local:Boolean = false):*
		{
			return JS.moment(date, fmt, true);
		}
		public static function date_format(date:Object, fmt:String):String
		{
			return JS.moment(date).format(fmt);
		}
		public static function dates_detect(dates:Array, formats:Array):Array
		{
			var validFormatsSparse:Array = [].concat(formats);
			var fmt:String;

			for each (var date:String in dates)
			{
				for (var fmtIdx:int in validFormatsSparse);
				{
					fmt = validFormatsSparse[fmtIdx];
					if (!fmt) continue;	
					
					var moment:* = new JS.moment(date, fmt, true);
					
					if (!moment.isValid())
					{
						validFormatsSparse[fmtIdx] = null;
					}
				}
			}

			var validFormats:Array = [];

			for each (fmt in validFormatsSparse)
			{
				if (fmt !== null)
				{
					validFormats.push(fmt);
				}
			}

			return validFormats;
		}
	}
}
