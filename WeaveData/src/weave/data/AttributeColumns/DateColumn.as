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

package weave.data.AttributeColumns
{
	import flash.system.Capabilities;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import weave.api.reportError;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataType;
	import weave.api.data.DateFormat;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.data.IQualifiedKey;
	import weave.compiler.Compiler;
	import weave.compiler.StandardLib;
	import weave.flascc.date_format;
	import weave.flascc.date_parse;
	import weave.flascc.dates_detect;
	
	/**
	 * @author adufilie
	 */
	public class DateColumn extends AbstractAttributeColumn implements IPrimitiveColumn
	{
		public function DateColumn(metadata:Object = null)
		{
			super(metadata);
		}
		
		private const _uniqueKeys:Array = new Array();
		private var _keyToData:Dictionary = new Dictionary();
		
		// temp variables for async task
		private var _i:int;
		private var _keys:Vector.<IQualifiedKey>;
		private var _dates:Vector.<String>;
		private var _reportedError:Boolean;
		
		// variables that do not get reset after async task
		private static const compiler:Compiler = new Compiler();
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
			return _keyToData[key] != undefined;
		}
		
		public function setRecords(keys:Vector.<IQualifiedKey>, dates:Vector.<String>):void
		{
			if (keys.length > dates.length)
			{
				reportError("Array lengths differ");
				return;
			}
			
			_fakeData = !!getMetadata("fakeDataRows");
			
			// read dateFormat metadata
			_dateFormat = getMetadata(ColumnMetadata.DATE_FORMAT);
			if (!_dateFormat)
			{
				var possibleFormats:Array = detectDateFormats(dates);
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
					_stringToNumberFunction = compiler.compileToFunction(numberFormat, null, errorHandler, false, [ColumnMetadata.STRING]);
				}
				catch (e:Error)
				{
					reportError(e);
				}
			}
			
			// compile the string format function from the metadata
			_numberToStringFunction = null;
			var stringFormat:String = getMetadata(ColumnMetadata.STRING);
			if (stringFormat)
			{
				try
				{
					_numberToStringFunction = compiler.compileToFunction(stringFormat, null, errorHandler, false, [ColumnMetadata.NUMBER]);
				}
				catch (e:Error)
				{
					reportError(e);
				}
			}
			
			_i = 0;
			_keys = keys;
			_dates = dates;
			_keyToData = new Dictionary();
			_uniqueKeys.length = 0;
			_reportedError = false;
			
			/*if (!_dateFormat && _keys.length)
			{
				_reportedError = true;
				reportError(lang('No common date format could be determined from the column values. Attribute Column: {0}', Compiler.stringify(_metadata)));
			}*/
			
			// high priority because not much can be done without data
			WeaveAPI.StageUtils.startTask(this, _asyncIterate, WeaveAPI.TASK_PRIORITY_HIGH, _asyncComplete);
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
				return weave.flascc.date_parse(string, _dateFormat);
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
					return weave.flascc.date_format(obj, _dateDisplayFormat);
				}
				else
				{
					var date:Date = value as Date || new Date(value);
					return weave.flascc.date_format(date, _dateDisplayFormat);
				}
			}
			return StandardLib.formatDate(value, _dateDisplayFormat);
		}
		
		private function _asyncIterate(stopTime:int):Number
		{
			for (; _i < _keys.length; _i++)
			{
				if (getTimer() > stopTime)
					return _i / _keys.length;
				
				// get values for this iteration
				var key:IQualifiedKey = _keys[_i];
				var string:String = _dates[_i];
				var value:Object;
				if (_fakeData)
				{
					value = new Date();
					(value as Date).fullYear = 2000 + StandardLib.asNumber(string);
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
					}
					catch (e:Error)
					{
						if (!_reportedError)
						{
							_reportedError = true;
							var err:String = StandardLib.substitute(
								'Warning: Unable to parse this value as a date: "{0}"'
								+ ' (only the first error for this column is reported).'
								+ ' Attribute column: {1}',
								string,
								Compiler.stringify(_metadata)
							);
							reportError(err, null, e);
						}
						continue;
					}
				}
				
				// keep track of unique keys
				if (_keyToData[key] === undefined)
				{
					_durationMode = value is Number;
					_uniqueKeys.push(key);
					// save key-to-data mapping
					_keyToData[key] = value;
				}
				else if (!_reportedError)
				{
					_reportedError = true;
					var fmt:String = 'Warning: Key column values are not unique.  Record dropped due to duplicate key ({0}) (only reported for first duplicate).  Attribute column: {1}';
					var str:String = StandardLib.substitute(fmt, key.localName, Compiler.stringify(_metadata));
					if (Capabilities.isDebugger)
						reportError(str);
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
				number = _keyToData[key];
				return number;
			}
			
			if (dataType == String)
			{
				if (_numberToStringFunction != null)
				{
					number = _keyToData[key];
					return _numberToStringFunction(number);
				}
				
				value = _keyToData[key];
				
				if (value === undefined)
					return '';
				
				if (_dateFormat)
					string = formatDate(value);
				else
					string = value.toString();
				
				return string;
			}
			
			value = _keyToData[key];
			
			if (!dataType || dataType == Array)
				return value != null ? [value] : null;
			
			if (dataType)
				return value as dataType;
			
			return value;
		}

		override public function toString():String
		{
			return debugId(this) + '{recordCount: '+keys.length+', keyType: "'+getMetadata('keyType')+'", title: "'+getMetadata('title')+'"}';
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
			return weave.flascc.dates_detect(dates, DateFormat.FOR_AUTO_DETECT);
		}
	}
}
