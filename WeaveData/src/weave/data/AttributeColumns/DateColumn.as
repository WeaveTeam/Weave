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
	
	import mx.utils.StringUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.newDisposableChild;
	import weave.api.reportError;
	import weave.compiler.Compiler;
	import weave.compiler.StandardLib;
	import weave.core.StageUtils;
	import weave.utils.AsyncSort;
	
	/**
	 * @author adufilie
	 */
	public class DateColumn extends AbstractAttributeColumn implements IPrimitiveColumn
	{
		public function DateColumn(metadata:XML = null)
		{
			super(metadata);
		}
		
		private const _uniqueKeys:Array = new Array();
		private var _keyToDate:Dictionary = new Dictionary();
		
		// temp variables for async task
		private var _i:int;
		private var _keys:Vector.<IQualifiedKey>;
		private var _dates:Vector.<String>;
		private var _reportedDuplicate:Boolean;
		
		// variables that do not get reset after async task
		private static const compiler:Compiler = new Compiler();
		private var _stringToNumberFunction:Function = null;
		private var _numberToStringFunction:Function = null;
		private var _dateFormat:String = null;
		
		public function get metadata():XML
		{
			return _metadata;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getMetadata(propertyName:String):String
		{
			if (propertyName == ColumnMetadata.DATA_TYPE)
				return DataTypes.DATE;
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
			_reportedDuplicate = false;
			
			WeaveAPI.StageUtils.startTask(this, _asyncIterate, WeaveAPI.TASK_PRIORITY_PARSING, _asyncComplete);
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
						date = StandardLib.parseDate(string, _dateFormat);
					}
					else
						date = new Date(number);
				}
				else
					date = StandardLib.parseDate(string, _dateFormat);
				
				// keep track of unique keys
				if (_keyToDate[key] === undefined)
				{
					_uniqueKeys.push(key);
					// save key-to-data mapping
					_keyToDate[key] = date;
				}
				else if (!_reportedDuplicate)
				{
					_reportedDuplicate = true;
					var fmt:String = 'Warning: Key column values are not unique.  Record dropped due to duplicate key ({0}) (only reported for first duplicate).  Attribute column: {1}';
					var str:String = StringUtil.substitute(fmt, key.localName, _metadata.toXMLString());
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
				return StandardLib.formatDate(number, _dateFormat);
			
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
					string = StandardLib.formatDate(date, _dateFormat);
				else
					string = date.toString();
				
				return string;
			}
			
			date = _keyToDate[key];
			
			if (dataType)
				return date as DataTypes;
			
			return date;
		}

		override public function toString():String
		{
			return debugId(this) + '{recordCount: '+keys.length+', keyType: "'+getMetadata('keyType')+'", title: "'+getMetadata('title')+'"}';
		}
	}
}
