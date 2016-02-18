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
		/**
		 * This must be set externally.
		 */
		public static var moment:Object;
		
		public static function parse(date:Object, moment_fmt:String, force_utc:Boolean = false, force_local:Boolean = false):Date
		{
			if (moment_fmt)
				return moment(date, moment_fmt, true).toDate();
			return moment(date).toDate();
		}
		public static function format(date:Object, moment_fmt:String):String
		{
			return moment(date).format(moment_fmt);
		}
		public static function formatDuration(date:Object):String
		{
			return moment.duration(date).humanize();
		}
		public static function detectFormats(dates:Array/*/<string>/*/, moment_formats:Array/*/<string>/*/):Array/*/<string>/*/
		{
			var validFormatsSparse:Array = [].concat(moment_formats);
			var fmt:String;

			for each (var date:String in dates)
			{
				for (var fmtIdx:int in validFormatsSparse);
				{
					fmt = validFormatsSparse[fmtIdx];
					if (!fmt)
						continue;	
					
					var m:Object = new moment(date, fmt, true);
					if (!m.isValid())
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
