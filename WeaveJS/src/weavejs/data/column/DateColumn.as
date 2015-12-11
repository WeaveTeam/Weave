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

package weavejs.data.column
{
	import weavejs.WeaveAPI;
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.DataType;
	import weavejs.api.data.DateFormat;
	import weavejs.api.data.IBaseColumn;
	import weavejs.api.data.IPrimitiveColumn;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.util.JS;
	import weavejs.util.StandardLib;
	
	/**
	 * @author adufilie
	 */
	public class DateColumn extends AbstractAttributeColumn implements IPrimitiveColumn, IBaseColumn
	{
		public static const flascc:Object = null;
		
		public function DateColumn(metadata:Object = null)
		{
			super(metadata);
		}
		
		private var _uniqueKeys:Array = new Array();
		private var map_key_data:Object = new JS.Map();
		
		// temp variables for async task
		private var _i:int;
		private var _keys:Array;
		private var _dates:Array;
		private var _reportedError:Boolean;
		
		// variables that do not get reset after async task
		private var _stringToNumberFunction:Function = null;
		private var _numberToStringFunction:Function = null;
		private var _dateFormat:String = null;
		private var _dateDisplayFormat:String = null;
		private var _durationMode:Boolean = false;
		private var _fakeData:Boolean = false;
		
		/**
		 * @inheritDoc
		 */
		override public function getMetadata(propertyName:String):String
		{
			if (propertyName == ColumnMetadata.DATA_TYPE)
				return DataType.DATE;
			if (propertyName == ColumnMetadata.DATE_FORMAT)
				return _dateFormat || super.getMetadata(propertyName);
			return super.getMetadata(propertyName);
		}

		/**
		 * @inheritDoc
		 */
		override public function get keys():Array
		{
			return _uniqueKeys;
		}

		/**
		 * @inheritDoc
		 */
		override public function containsKey(key:IQualifiedKey):Boolean
		{
			return map_key_data.has(key);
		}
		
		public function setRecords(qkeys:Array, dateStrings:Array):void
		{
			if (keys.length > dateStrings.length)
			{
				JS.error("Array lengths differ");
				return;
			}
			
			_fakeData = !!getMetadata("fakeData");
			
			// read dateFormat metadata
			_dateFormat = getMetadata(ColumnMetadata.DATE_FORMAT);
			if (!_dateFormat)
			{
				var possibleFormats:Array = detectDateFormats(dateStrings);
				StandardLib.sortOn(possibleFormats, 'length');
				_dateFormat = possibleFormats.pop();
			}
			
			_dateFormat = convertDateFormat_as_to_c(_dateFormat);

			// read dateDisplayFormat metadata, default to the input format if none is specified.
			_dateDisplayFormat = getMetadata(ColumnMetadata.DATE_DISPLAY_FORMAT);

			if (_dateDisplayFormat)
			{
				_dateDisplayFormat = convertDateFormat_as_to_c(_dateDisplayFormat);
			}
			else
			{
				_dateDisplayFormat = _dateFormat;
			}
			
			// compile the number format function from the metadata
			_stringToNumberFunction = null;
			var numberFormat:String = getMetadata(ColumnMetadata.NUMBER);
			if (numberFormat)
			{
				try
				{
					_stringToNumberFunction = JS.compile(numberFormat, [ColumnMetadata.STRING]);
				}
				catch (e:Error)
				{
					JS.error(e);
				}
			}
			
			// compile the string format function from the metadata
			_numberToStringFunction = null;
			var stringFormat:String = getMetadata(ColumnMetadata.STRING);
			if (stringFormat)
			{
				try
				{
					_numberToStringFunction = JS.compile(stringFormat, [ColumnMetadata.NUMBER]);
				}
				catch (e:Error)
				{
					JS.error(e);
				}
			}
			
			_i = 0;
			_keys = qkeys;
			_dates = dateStrings;
			map_key_data = new JS.Map();
			_uniqueKeys.length = 0;
			_reportedError = false;
			
			/*if (!_dateFormat && _keys.length)
			{
				_reportedError = true;
				JS.error(lang('No common date format could be determined from the column values. Attribute Column: {0}', Compiler.stringify(_metadata)));
			}*/
			
			// high priority because not much can be done without data
			WeaveAPI.Scheduler.startTask(this, _asyncIterate, WeaveAPI.TASK_PRIORITY_HIGH, _asyncComplete);
		}
		
		private function errorHandler(e:*):void
		{
			return; // do nothing
		}
		
		private function _asyncComplete():void
		{
			_keys = null;
			_dates = null;
			
			triggerCallbacks();
		}
		
		private function parseDate(string:String):Object
		{
			if (_dateFormat)
				return flascc.date_parse(string, _dateFormat);
			return new Date(string);
		}
		
		private static const SECOND:Number = 1000;
		private static const MINUTE:Number = 60 * 1000;
		private static const HOUR:Number = 60 * 60 * 1000;
		
		private function formatDate(value:Object):String
		{
			if (_dateDisplayFormat)
			{
				if (value is Number && !_durationMode)
					value = new Date(value);
				
				if (value is Number)
				{
					// TEMPORARY SOLUTION
					var n:Number = Math.floor(value as Number);
					var milliseconds:Number = n % 1000;
					n = Math.floor(n / 1000);
					var seconds:Number = n % 60;
					n = Math.floor(n / 60);
					var minutes:Number = n % 60;
					n = Math.floor(n / 60);
					var hours:Number = n;
					var obj:Object = {
						milliseconds: milliseconds,
						seconds: seconds,
						minutes: minutes,
						hours: hours
					};
					return flascc.date_format(obj, _dateDisplayFormat);
				}
				else
				{
					var date:Date = value as Date || new Date(value);
					return flascc.date_format(date, _dateDisplayFormat);
				}
			}
			return StandardLib.formatDate(value, _dateDisplayFormat);
		}
		
		private function _asyncIterate(stopTime:int):Number
		{
			for (; _i < _keys.length; _i++)
			{
				if (JS.now() > stopTime)
					return _i / _keys.length;
				
				// get values for this iteration
				var key:IQualifiedKey = _keys[_i];
				var string:String = _dates[_i];
				var value:Object;
				if (_fakeData)
				{
					var oneDay:Number = 24 * 60 * 60 * 1000;
					var fakeTime:Number = StandardLib.asNumber(string) * oneDay;
					var d:Date = new Date();
					d.setTime(d.getTime() - d.getTime() % oneDay + fakeTime);
					value = d;
				}
				else if (_stringToNumberFunction != null)
				{
					var number:Number = _stringToNumberFunction(string);
					if (_numberToStringFunction != null)
					{
						string = _numberToStringFunction(number);
						if (!string)
							continue;
						value = parseDate(string);
					}
					else
					{
						if (!isFinite(number))
							continue;
						value = number;
					}
				}
				else
				{
					try
					{
						if (!string)
							continue;
						value = parseDate(string);
						if (value is Date && isNaN((value as Date).getTime()))
							value = StandardLib.asNumber(string);
					}
					catch (e:Error)
					{
						if (!_reportedError)
						{
							_reportedError = true;
							var err:String = StandardLib.substitute(
								'Warning: Unable to parse this value as a date: "{0}"'
								+ ' (only the first error for this column is reported).'
								+ ' Attribute column:',
								string
							);
							JS.error(err, _metadata, e);
						}
						continue;
					}
				}
				
				// keep track of unique keys
				if (!map_key_data.has(key))
				{
					_durationMode = value is Number;
					_uniqueKeys.push(key);
					// save key-to-data mapping
					map_key_data.set(key, value);
				}
				else if (!_reportedError)
				{
					_reportedError = true;
					var fmt:String = 'Warning: Key column values are not unique.  Record dropped due to duplicate key ({0}) (only reported for first duplicate).  Attribute column:';
					JS.log(StandardLib.substitute(fmt, key.localName), _metadata);
				}
			}
			return 1;
		}

		/**
		 * @inheritDoc
		 */
		public function deriveStringFromNumber(number:Number):String
		{
			if (_numberToStringFunction != null)
				return _numberToStringFunction(number);
			
			if (_dateFormat)
				return formatDate(number);
			
			return new Date(number).toString();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			var number:Number;
			var string:String;
			var value:*;
			
			if (dataType == Number)
			{
				number = map_key_data.get(key);
				return number;
			}
			
			if (dataType == String)
			{
				if (_numberToStringFunction != null)
				{
					number = map_key_data.get(key);
					return _numberToStringFunction(number);
				}
				
				value = map_key_data.get(key);
				
				if (value === undefined)
					return '';
				
				if (_dateFormat)
					string = formatDate(value);
				else
					string = value.toString();
				
				return string;
			}
			
			value = map_key_data.get(key);
			
			if (!dataType || dataType == Array)
				return value != null ? [value] : null;
			
			if (dataType)
				return value as dataType;
			
			return value;
		}

		private static function convertDateFormat_as_to_c(format:String):String
		{
			if (!format || format.indexOf('%') >= 0)
				return format;
			return StandardLib.replace.apply(null, [format].concat(dateFormat_replacements_as_to_c));
		}
		
		private static const dateFormat_replacements_as_to_c:Array = [
			'YYYY','%Y',
			'YY','%y',
			'MMMM','%B',
			'MMM','%b',
			'MM','%m',
			'M','%-m',
			'DD','%d',
			'D','%-d',
			'E','%u',
			'A','%p',
			'JJ','%H',
			'J','%-H',
			'LL','%I',
			'L','%-I',
			'EEEE','%A', // note that %A appears after the A replaced above
			'EEE','%a',
			'NN','%M', // note that %M and %-M appear after the M's replaced above
			'N','%-M',
			'SS','%S',
			'QQQ','%Q'
			//,'S','%-S'
		];
		
		public static function detectDateFormats(dates:*):Array
		{
			//TODO
			return [];
			//return flascc.dates_detect(dates, DateFormat.FOR_AUTO_DETECT);
		}
	}
}
