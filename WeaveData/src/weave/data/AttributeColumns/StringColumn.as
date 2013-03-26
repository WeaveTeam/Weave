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
	import flash.utils.getQualifiedClassName;
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
	import weave.utils.VectorUtils;
	
	/**
	 * StringColumn
	 * 
	 * @author adufilie
	 */
	public class StringColumn extends AbstractAttributeColumn implements IPrimitiveColumn
	{
		public function StringColumn(metadata:XML = null)
		{
			super(metadata);
		}
		
		public function get metadata():XML
		{
			return _metadata;
		}
		
		override public function getMetadata(propertyName:String):String
		{
			if (propertyName == ColumnMetadata.DATA_TYPE)
				return DataTypes.STRING;
			return super.getMetadata(propertyName);
		}

		/**
		 * This is a list of unique keys this column defines values for.
		 */
		override public function get keys():Array
		{
			return _uniqueKeys;
		}

		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		override public function containsKey(key:IQualifiedKey):Boolean
		{
			return _keyToUniqueStringIndexMapping[key] != undefined;
		}
		
		private const _uniqueKeys:Array = new Array();
		/**
		 * uniqueStrings
		 * Derived from the record data, this is a list of all existing values in the dimension, each appearing once, sorted alphabetically.
		 */
		private const _uniqueStrings:Vector.<String> = new Vector.<String>();

		/**
		 * This maps keys to index values in the _uniqueStrings vector.
		 * This effectively stores the column data.
		 */
		private var _keyToUniqueStringIndexMapping:Dictionary = new Dictionary();

		/**
		 * This maps keys to index values in the _uniqueStrings vector.
		 * This effectively stores the column data after applying the function 
		 * from the NUMBER metadata.
		 */
		private var _keyToNumberMapping:Dictionary = new Dictionary();
		/**
		 * This serves as the inverse of _keyToNumberMapping.
		 */		
		private var _numberToKeyMapping:Dictionary = new Dictionary();
		
		public function setRecords(keys:Vector.<IQualifiedKey>, stringData:Vector.<String>):void
		{
			if (keys.length > stringData.length)
			{
				reportError("Array lengths differ");
				return;
			}
			
			_i1 = 0;
			_i3 = 0;
			_i4 = 0;
			_keys = keys;
			_stringData = stringData;
			_keyToStringMap = new Dictionary();
			_stringToIndexMap = {};
			_uniqueKeys.length = 0;
			_uniqueStrings.length = 0;
			_keyToUniqueStringIndexMapping = new Dictionary();
			_numberToKeyMapping = new Dictionary();
			_stringToNumberFunction = null;
			_numberToStringFunction = null;
			_reportedDuplicate = false;
			
			// compile the number format function from the metadata
			var numberFormat:String = getMetadata(ColumnMetadata.NUMBER);
			if (numberFormat)
			{
				try
				{
					_stringToNumberFunction = compiler.compileToFunction(numberFormat, null, true, false, [ColumnMetadata.STRING]);
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
					_numberToStringFunction = compiler.compileToFunction(stringFormat, null, true, false, [ColumnMetadata.NUMBER]);
				}
				catch (e:Error)
				{
					reportError(e);
				}
			}
			
			_iterateAll(-1); // restart from first task
			WeaveAPI.StageUtils.startTask(this, _iterateAll, WeaveAPI.TASK_PRIORITY_PARSING, _asyncComplete);
		}
		
		private const _iterateAll:Function = StageUtils.generateCompoundIterativeTask(_iterate1, _iterate2, _iterate3, _iterate4);
		
		// temp variables for async task
		private var _i1:int;
		private var _i3:int;
		private var _i4:int;
		private var _keys:Vector.<IQualifiedKey>;
		private var _stringData:Vector.<String>;
		private var _stringToIndexMap:Object;
		private var _reportedDuplicate:Boolean = false;
		
		// variables that do not get reset after async task
		private static const compiler:Compiler = new Compiler();
		private var _stringToNumberFunction:Function = null;
		private var _numberToStringFunction:Function = null;
		private var _keyToStringMap:Dictionary;
		
		private function _asyncComplete():void
		{
			_keys = null;
			_stringData = null;
			_stringToIndexMap = null;
			
			triggerCallbacks();
		}
		
		private function _iterate1(stopTime:int):Number
		{
			// copy new records to dataMap, overwriting any existing records
			
			for (; _i1 < _keys.length; _i1++)
			{
				if (getTimer() > stopTime)
					return _i1 / _keys.length;
				
				// get values for this iteration
				var key:IQualifiedKey = _keys[_i1];
				var value:String = _stringData[_i1];
				
				// keep track of unique keys
				if (_keyToStringMap[key] === undefined)
				{
					_uniqueKeys.push(key);
					// save key-to-data mapping
					_keyToStringMap[key] = value;
				}
				else if (!_reportedDuplicate)
				{
					_reportedDuplicate = true;
					var fmt:String = 'Warning: Key column values are not unique.  Record dropped due to duplicate key ({0}) (only reported for first duplicate).  Attribute column: {1}';
					var str:String = StringUtil.substitute(fmt, key.localName, _metadata.toXMLString());
					if (Capabilities.isDebugger)
						reportError(str);
				}
				// keep track of unique strings
				if (_stringToIndexMap[value] === undefined)
				{
					_uniqueStrings.push(value);
					// initialize mapping
					_stringToIndexMap[value] = -1;
				}
			}
			
			// begin sorting unique strings previously listed
			_asyncSort.beginSort(_uniqueStrings, AsyncSort.compareCaseInsensitive);
			
			return 1;
		}
		private const _asyncSort:AsyncSort = newDisposableChild(this, AsyncSort);
		private function _iterate2(stopTime:int):Number
		{
			// wait for async sort to finish
			return _asyncSort.result ? 1 : 0;
		}
		private function _iterate3(stopTime:int):Number
		{
			for (; _i3 < _uniqueStrings.length; _i3++)
			{
				if (getTimer() > stopTime)
					return _i3 / _uniqueStrings.length;
				
				// save string-to-index mapping
				_stringToIndexMap[_uniqueStrings[_i3] as String] = _i3;
			}
			return 1;
		}
		private function _iterate4(stopTime:int):Number
		{
			for (; _i4 < _uniqueKeys.length; _i4++)
			{
				if (getTimer() > stopTime)
					return _i4 / _uniqueKeys.length;
				
				var key:IQualifiedKey = _uniqueKeys[_i4] as IQualifiedKey;
				var string:String = _keyToStringMap[key] as String;
				var index:int = int(_stringToIndexMap[string]);
				_keyToUniqueStringIndexMapping[key] = index;
				
				if (_stringToNumberFunction != null)
				{
					var number:Number = _stringToNumberFunction(string);
					_keyToNumberMapping[key] = number;
					// save reverse lookup
					_numberToKeyMapping[number] = key;
				}
				else
				{
					_keyToNumberMapping[key] = index;
				}
			}
			return 1;
		}

		// find the closest string value at a given normalized value
		public function deriveStringFromNumber(number:Number):String
		{
			if (getMetadata(ColumnMetadata.NUMBER))
			{
				if (_numberToStringFunction != null)
					return _numberToStringFunction(number);

				var key:IQualifiedKey = _numberToKeyMapping[number] as IQualifiedKey;
				if (key)
					return getValueFromKey(key, String);
			}
			else if (number == int(number) && 0 <= number && number < _uniqueStrings.length)
			{
				return _uniqueStrings[int(number)];
			}
			return '';
		}
		
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (dataType == Number)
			{
				var numericValue:Number = _keyToNumberMapping[key];
				return numericValue;
			}
			
			if (dataType == null)
				dataType = String;
			
			var index:Number = _keyToUniqueStringIndexMapping[key];
			
			if (isNaN(index))
				return '' as dataType;
			
			var string:String = _keyToStringMap[key] as String;
			
			if (dataType == IQualifiedKey)
			{
				var type:String = _metadata.attribute(ColumnMetadata.DATA_TYPE);
				if (!type)
					type = DataTypes.STRING;
				return WeaveAPI.QKeyManager.getQKey(type, string);
			}
			
			return string as dataType;
		}

		override public function toString():String
		{
			return debugId(this) + '{recordCount: '+keys.length+', keyType: "'+getMetadata('keyType')+'", title: "'+getMetadata('title')+'"}';
		}
	}
}
