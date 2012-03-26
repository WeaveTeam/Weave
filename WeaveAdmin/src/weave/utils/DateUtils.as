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

package weave.utils
{
	import mx.formatters.DateFormatter;

	public class DateUtils
	{
		private var _time:Number;
		private var _format:String;
		private var d:Date = new Date();
		
		public function DateUtils()
		{
			
		}
		
		public function set time(t:Number):void
		{
			_time = t;
		}
		public function get time():Number
		{
			return _time;
		}
		public function set format(s:String):void
		{
			_format = s;
		}
		public function get format():String
		{
			return _format;
		}
		public function parse(time:Object = null, format:Object = null):String
		{
			var df:DateFormatter = new DateFormatter();
			if( format != null )_format = format as String;
			if( time != null )	_time = time as Number;
			
			d.time = _time;
			df.formatString = _format;
			return df.format(d);
		}
		public static function now():Number
		{
			return new Date().getTime();
		}
	}
}