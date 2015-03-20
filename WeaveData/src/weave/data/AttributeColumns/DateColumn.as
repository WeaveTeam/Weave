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

package weave.data.AttributeColumns
{
	import flash.system.Capabilities;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataType;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.reportError;
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
		private var _keyToDate:Dictionary = new Dictionary();
		
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
		private var _useFlascc:Boolean = true;
		
		/**
		 * @inheritDoc
		 */
		override public function getMetadata(propertyName:String):String
		{
			if (propertyName == ColumnMetadata.DATA_TYPE)
				return DataType.DATE;
			if (propertyName == ColumnMetadata.DATE_FORMAT)
				return _dateFormat;
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
			return _keyToDate[key] != undefined;
		}
		
		public function setRecords(keys:Vector.<IQualifiedKey>, dates:Vector.<String>):void
		{
			if (keys.length > dates.length)
			{
				reportError("Array lengths differ");
				return;
			}
			
			// read dateFormat metadata
			_dateFormat = getMetadata(ColumnMetadata.DATE_FORMAT);
			if (!_dateFormat)
			{
				var possibleFormats:Array = detectDateFormats(dates);
				StandardLib.sortOn(possibleFormats, 'length');
				_dateFormat = possibleFormats.pop();
			}
			
			_dateFormat = convertDateFormat_as_to_c(_dateFormat);
			//_useFlascc = _dateFormat && _dateFormat.indexOf('%') >= 0;
			
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
			_keyToDate = new Dictionary();
			_uniqueKeys.length = 0;
			_reportedError = false;
			
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
		
		private function parseDate(string:String):Date
		{
			if (_useFlascc)
				return weave.flascc.date_parse(string, _dateFormat);
			return StandardLib.parseDate(string, _dateFormat);
		}
		
		private function formatDate(value:Object):String
		{
			if (_useFlascc)
				return weave.flascc.date_format(value as Date || new Date(value), _dateFormat);
			return StandardLib.formatDate(value, _dateFormat);
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
				var date:Date;
				if (_stringToNumberFunction != null)
				{
					var number:Number = _stringToNumberFunction(string);
					if (_numberToStringFunction != null)
					{
						string = _numberToStringFunction(number);
						date = parseDate(string);
					}
					else
						date = new Date(number);
				}
				else
				{
					try
					{
						date = parseDate(string);
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
							reportError(err);
						}
						continue;
					}
				}
				
				// keep track of unique keys
				if (_keyToDate[key] === undefined)
				{
					_uniqueKeys.push(key);
					// save key-to-data mapping
					_keyToDate[key] = date;
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
			var date:Date;
			
			if (dataType == Number)
			{
				number = _keyToDate[key];
				return number;
			}
			
			if (dataType == String)
			{
				if (_numberToStringFunction != null)
				{
					number = _keyToDate[key];
					return _numberToStringFunction(number);
				}
				
				date = _keyToDate[key];
				
				if (!date)
					return '';
				
				if (_dateFormat)
					string = formatDate(date);
				else
					string = date.toString();
				
				return string;
			}
			
			date = _keyToDate[key];
			
			if (dataType)
				return date as DataType;
			
			return date;
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
			'EEEE','%A', // note this %A is after the A was replaced above
			'EEE','%a',
			'NN','%M', // note these %M appears after the M's were replaced above
			'N','%-M',
			'SS','%S'
			//,'S','%-S'
		];
		
		public static function detectDateFormats(dates:*):Array
		{
			return weave.flascc.dates_detect(dates, DATE_FORMAT_AUTO_DETECT);
		}
		
		public static const DATE_FORMAT_ADDITIONAL_SUGGESTIONS:Array = [
			"%Y"
		];
		public static const DATE_FORMAT_AUTO_DETECT:Array = [
			'%d-%b-%y',
			'%b-%d-%y',
			'%d-%b-%Y',
			'%b-%d-%Y',
			'%Y-%b-%d',
			
			'%d/%b/%y',
			'%b/%d/%y',
			'%d/%b/%Y',
			'%b/%d/%Y',
			'%Y/%b/%d',
			
			'%d.%b.%y',
			'%b.%d.%y',
			'%d.%b.%Y',
			'%b.%d.%Y',
			'%Y.%b.%d',
			
			'%d-%m-%y',
			'%m-%d-%y',
			'%d-%m-%Y',
			'%m-%d-%Y',
			'%Y-%m-%d',
			
			'%d/%m/%y',
			'%m/%d/%y',
			'%d/%m/%Y',
			'%m/%d/%Y',
			'%Y/%m/%d',
			
			'%d.%m.%y',
			'%m.%d.%y',
			'%d.%m.%Y',
			'%m.%d.%Y',
			'%Y.%m.%d',
			
			'%H:%M',
			'%H:%M:%S',
			'%a, %d %b %Y %H:%M:%S %z', // RFC_822
			
			// ISO_8601   http://www.thelinuxdaily.com/2014/03/c-function-to-validate-iso-8601-date-formats-using-strptime/
			"%Y-%m-%d",
			"%y-%m-%d",
			"%Y-%m-%d %T",
			"%y-%m-%d %T",
			"%Y-%m-%dT%T",
			"%y-%m-%dT%T",
			"%Y-%m-%dT%TZ",
			"%y-%m-%dT%TZ",
			"%Y-%m-%d %TZ",
			"%y-%m-%d %TZ",
			"%Y%m%dT%TZ",
			"%y%m%dT%TZ",
			"%Y%m%d %TZ",
			"%y%m%d %TZ",
			
			"%Y-%b-%d %T",
			"%Y-%b-%d %H:%M:%S",
			"%d-%b-%Y %T",
			"%d-%b-%Y %H:%M:%S"
			
			/*
			//https://code.google.com/p/datejs/source/browse/trunk/src/globalization/en-US.js
			'M/d/yyyy',
			'dddd, MMMM dd, yyyy',
			"M/d/yyyy",
			"dddd, MMMM dd, yyyy",
			"h:mm tt",
			"h:mm:ss tt",
			"dddd, MMMM dd, yyyy h:mm:ss tt",
			"yyyy-MM-ddTHH:mm:ss",
			"yyyy-MM-dd HH:mm:ssZ",
			"ddd, dd MMM yyyy HH:mm:ss GMT",
			"MMMM dd",
			"MMMM, yyyy",
			
			//http://www.java2s.com/Code/Android/Date-Type/parseDateforlistofpossibleformats.htm
			"EEE, dd MMM yyyy HH:mm:ss z", // RFC_822
			"EEE, dd MMM yyyy HH:mm zzzz",
			"yyyy-MM-dd'T'HH:mm:ssZ",
			"yyyy-MM-dd'T'HH:mm:ss.SSSzzzz", // Blogger Atom feed has millisecs also
			"yyyy-MM-dd'T'HH:mm:sszzzz",
			"yyyy-MM-dd'T'HH:mm:ss z",
			"yyyy-MM-dd'T'HH:mm:ssz", // ISO_8601
			"yyyy-MM-dd'T'HH:mm:ss",
			"yyyy-MM-dd'T'HHmmss.SSSz",
			
			//http://stackoverflow.com/a/21737848
			"M/d/yyyy", "MM/dd/yyyy",                                    
			"d/M/yyyy", "dd/MM/yyyy", 
			"yyyy/M/d", "yyyy/MM/dd",
			"M-d-yyyy", "MM-dd-yyyy",                                    
			"d-M-yyyy", "dd-MM-yyyy", 
			"yyyy-M-d", "yyyy-MM-dd",
			"M.d.yyyy", "MM.dd.yyyy",                                    
			"d.M.yyyy", "dd.MM.yyyy", 
			"yyyy.M.d", "yyyy.MM.dd",
			"M,d,yyyy", "MM,dd,yyyy",                                    
			"d,M,yyyy", "dd,MM,yyyy", 
			"yyyy,M,d", "yyyy,MM,dd",
			"M d yyyy", "MM dd yyyy",                                    
			"d M yyyy", "dd MM yyyy", 
			"yyyy M d", "yyyy MM dd" */
		];
	}
}
