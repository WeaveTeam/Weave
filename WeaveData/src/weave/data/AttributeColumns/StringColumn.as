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
	import flash.utils.getTimer;
	
	import weave.api.data.Aggregation;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataType;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.newDisposableChild;
	import weave.api.reportError;
	import weave.compiler.Compiler;
	import weave.compiler.StandardLib;
	import weave.utils.AsyncSort;
	import weave.utils.Dictionary2D;
	
	/**
	 * @author adufilie
	 */
	public class StringColumn extends AbstractAttributeColumn implements IPrimitiveColumn
	{
		public function StringColumn(metadata:Object = null)
		{
			super(metadata);
			
			dataTask = new ColumnDataTask(this, filterStringValue, handleDataTaskComplete);
			dataCache = new Dictionary2D();
			getCallbackCollection(_asyncSort).addImmediateCallback(this, handleSortComplete);
		}
		
		override public function getMetadata(propertyName:String):String
		{
			var value:String = super.getMetadata(propertyName);
			if (!value && propertyName == ColumnMetadata.DATA_TYPE)
				return DataType.STRING;
			return value;
		}

		/**
		 * Sorted list of unique string values.
		 */
		private const _uniqueStrings:Vector.<String> = new Vector.<String>();
		
		/**
		 * String -> index in sorted _uniqueStrings
		 */
		private var _uniqueStringLookup:Object;

		public function setRecords(keys:Vector.<IQualifiedKey>, stringData:Vector.<String>):void
		{
			dataTask.begin(keys, stringData);
			_asyncSort.abort();
			
			_uniqueStrings.length = 0;
			_uniqueStringLookup = {};
			_stringToNumberFunction = null;
			_numberToStringFunction = null;
			
			// compile the number format function from the metadata
			var numberFormat:String = getMetadata(ColumnMetadata.NUMBER);
			if (numberFormat)
			{
				try
				{
					_stringToNumberFunction = compiler.compileToFunction(numberFormat, null, errorHandler, false, [ColumnMetadata.STRING, 'array']);
				}
				catch (e:Error)
				{
					reportError(e);
				}
			}
			
			// compile the string format function from the metadata
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
		}
		
		private function errorHandler(e:*):void
		{
			var str:String = e is Error ? e.message : String(e);
			str = StandardLib.substitute("Error in script for AttributeColumn {0}:\n{1}", Compiler.stringify(_metadata), str);
			if (_lastError != str)
			{
				_lastError = str;
				reportError(e);
			}
		}
		
		private var _lastError:String;
		
		// variables that do not get reset after async task
		private static const compiler:Compiler = new Compiler();
		private var _stringToNumberFunction:Function = null;
		private var _numberToStringFunction:Function = null;
		
		private function filterStringValue(value:String):Boolean
		{
			if (!value)
				return false;
			
			// keep track of unique strings
			if (_uniqueStringLookup[value] === undefined)
			{
				_uniqueStrings.push(value);
				// initialize mapping
				_uniqueStringLookup[value] = -1;
			}
			
			return true;
		}
		
		private function handleDataTaskComplete():void
		{
			// begin sorting unique strings previously listed
			_asyncSort.beginSort(_uniqueStrings, AsyncSort.compareCaseInsensitive);
		}
		
		private const _asyncSort:AsyncSort = newDisposableChild(this, AsyncSort);
		
		private function handleSortComplete():void
		{
			if (!_asyncSort.result)
				return;
			
			_i = 0;
			_numberToString = {};
			WeaveAPI.StageUtils.startTask(this, _iterate, WeaveAPI.TASK_PRIORITY_3_PARSING, asyncComplete);
		}
		
		private var _i:int;
		private var _numberToString:Object = {};
		private var _stringToNumber:Object = {};
		
		private function _iterate(stopTime:int):Number
		{
			for (; _i < _uniqueStrings.length; _i++)
			{
				if (getTimer() > stopTime)
					return _i / _uniqueStrings.length;
				
				var string:String = _uniqueStrings[_i];
				_uniqueStringLookup[string] = _i;
				
				if (_stringToNumberFunction != null)
				{
					var number:Number = StandardLib.asNumber(_stringToNumberFunction(string));
					_stringToNumber[string] = number;
					_numberToString[number] = string;
				}
			}
			return 1;
		}
		
		private function asyncComplete():void
		{
			// cache needs to be cleared after async task completes because some values may have been cached while the task was busy
			dataCache = new Dictionary2D();
			triggerCallbacks();
		}

		// find the closest string value at a given normalized value
		public function deriveStringFromNumber(number:Number):String
		{
			if (_metadata && _metadata[ColumnMetadata.NUMBER])
			{
				if (_numberToString.hasOwnProperty(number))
					return _numberToString[number];
				
				if (_numberToStringFunction != null)
					return _numberToString[number] = StandardLib.asString(_numberToStringFunction(number));
			}
			else if (number == int(number) && 0 <= number && number < _uniqueStrings.length)
			{
				return _uniqueStrings[int(number)];
			}
			return '';
		}
		
		override protected function generateValue(key:IQualifiedKey, dataType:Class):Object
		{
			var array:Array = dataTask.arrayData[key];
			
			if (dataType === String)
			{
				if (!array)
					return '';
				
				switch (_metadata ? _metadata[ColumnMetadata.AGGREGATION] : null)
				{
					default:
					case Aggregation.FIRST:
						return array[0];
					case Aggregation.LAST:
						return array[array.length - 1];
				}
			}
			
			var string:String = getValueFromKey(key, String);
			
			if (dataType === Number)
			{
				if (_stringToNumberFunction != null)
					return Number(_stringToNumber[string]);
				
				return Number(_uniqueStringLookup[string]);
			}
			
			if (dataType === IQualifiedKey)
			{
				var type:String = _metadata ? _metadata[ColumnMetadata.DATA_TYPE] : null;
				if (!type)
					type = DataType.STRING;
				return WeaveAPI.QKeyManager.getQKey(type, string);
			}
			
			return null;
		}
		
		override public function toString():String
		{
			return debugId(this) + '{recordCount: '+keys.length+', keyType: "'+getMetadata('keyType')+'", title: "'+getMetadata('title')+'"}';
		}
	}
}
