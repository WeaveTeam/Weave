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
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import weave.api.WeaveAPI;
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.data.IQualifiedKey;
	import weave.compiler.Compiler;
	import weave.compiler.StandardLib;
	import weave.core.weave_internal;
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
		
		weave_internal function get metadata():XML
		{
			return _metadata;
		}
		
		override public function getMetadata(propertyName:String):String
		{
			if (propertyName == AttributeColumnMetadata.DATA_TYPE)
				return DataTypes.STRING;
			return super.getMetadata(propertyName);
		}

		/**
		 * This is a list of unique keys this column defines values for.
		 */
		private const _uniqueKeys:Array = new Array();
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
		
		/**
		 * uniqueStrings
		 * Derived from the record data, this is a list of all existing values in the dimension, each appearing once, sorted alphabetically.
		 */
		private var _uniqueStrings:Vector.<String> = new Vector.<String>();

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
				WeaveAPI.ErrorManager.reportError(new Error("Array lengths differ"));
				return;
			}

			// create Dictionary mapping keys to data
			var dataMap:Dictionary = new Dictionary();
			// copy new records to dataMap, overwriting any existing records
			for (var i:int = 0; i < keys.length; i++)
			{
				dataMap[keys[i]] = String(stringData[i]);
			}
			setRecordMap(dataMap);
		}
		
		/**
		 * This function replaces all the data in the column using the given dataMap (key -> data).
		 * @param dataMap A Dictionary mapping keys to record data.
		 */
		private function setRecordMap(dataMap:Dictionary):void
		{
			var key:Object;
			var index:int;

			_keyToUniqueStringIndexMapping = new Dictionary();
			_numberToKeyMapping = new Dictionary();
			
			// save a list of data values
			index = 0;
			for (key in dataMap)
			{
				// save key
				_uniqueKeys[index] = key;
				// save data value
				_uniqueStrings[index] = dataMap[key] as String;
				// advance index for next key
				index++;
			}
			// trim arrays to new size
			_uniqueKeys.length = index;
			_uniqueStrings.length = index;
			// sort data values and remove duplicates
			_uniqueStrings.sort(Array.CASEINSENSITIVE);
			VectorUtils.removeDuplicatesFromSortedArray(_uniqueStrings);
			
			// save new internal keyToUniqueStringIndexMapping
			var stringToIndexMap:Object = new Object();
			for (index = 0; index < _uniqueStrings.length; index++)
				stringToIndexMap[_uniqueStrings[index] as String] = index;
			
			// compile the number format function from the metadata
			var stringToNumberFunction:Function = null;
			var numberFormat:String = getMetadata(AttributeColumnMetadata.NUMBER);
			if (numberFormat)
			{
				try
				{
					stringToNumberFunction = compiler.compileToFunction(numberFormat, null, true, false, [AttributeColumnMetadata.STRING]);
				}
				catch (e:Error)
				{
					WeaveAPI.ErrorManager.reportError(e);
				}
			}
			
			// compile the string format function from the metadata
			var stringFormat:String = getMetadata(AttributeColumnMetadata.STRING);
			if (stringFormat)
			{
				try
				{
					numberToStringFunction = compiler.compileToFunction(stringFormat, null, true, false, [AttributeColumnMetadata.NUMBER]);
				}
				catch (e:Error)
				{
					WeaveAPI.ErrorManager.reportError(e);
				}
			}
			
			for (key in dataMap)
			{
				var str:String = dataMap[key] as String;
				index = stringToIndexMap[str];
				_keyToUniqueStringIndexMapping[key] = index;
				
				if (stringToNumberFunction != null)
				{
					var number:Number = stringToNumberFunction(str);
					_keyToNumberMapping[key] = number;
					// save reverse lookup
					_numberToKeyMapping[number] = key;
				}
				else
					_keyToNumberMapping[key] = index;
			}
			
			triggerCallbacks();
		}

		private static const compiler:Compiler = new Compiler();
		private var numberToStringFunction:Function = null;
		
		// find the closest string value at a given normalized value
		public function deriveStringFromNumber(number:Number):String
		{
			if (getMetadata(AttributeColumnMetadata.NUMBER))
			{
				if (numberToStringFunction != null)
					return numberToStringFunction(number);

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
			
			var str:String = _uniqueStrings[index] as String;
			
			if (dataType == IQualifiedKey)
			{
				var type:String = _metadata.attribute(AttributeColumnMetadata.DATA_TYPE);
				if (type == '')
					type = DataTypes.STRING;
				return WeaveAPI.QKeyManager.getQKey(type, str);
			}
			
			return str;
		}

		override public function toString():String
		{
			return getQualifiedClassName(this).split("::")[1] + '{recordCount: '+keys.length+', keyType: "'+getMetadata('keyType')+'", title: "'+getMetadata('title')+'"}';
		}
	}
}
