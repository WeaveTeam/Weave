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
	import __AS3__.vec.Vector;
	
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import weave.api.WeaveAPI;
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.IStreamedColumn;
	import weave.core.weave_internal;
	import weave.utils.VectorUtils;
	
	/**
	 * StringColumn
	 * 
	 * @author adufilie
	 */
	public class StringColumn extends AbstractAttributeColumn implements IStreamedColumn, IPrimitiveColumn
	{
		public function StringColumn(metadata:XML = null)
		{
			super(metadata);
		}
		
		weave_internal function get metadata():XML
		{
			return _metadata;
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
//		public function get uniqueStrings():Vector.<String>
//		{
//			return _uniqueStrings;
//		}

		/**
		 * This maps keys to index values in the _uniqueStrings vector.
		 * This effectively stores the column data.
		 */
		private var _keyToUniqueStringIndexMapping:Dictionary = new Dictionary();
		
		private var _keysLastUpdated:Array = new Array();
		public function get keysLastUpdated():Array
		{
			return _keysLastUpdated;
		}

		/**
		 * removeRecords
		 * This function may be removed later.
		 * Keep this function private until it is needed.
		 */
		private function removeRecords(keysToRemove:Array):void
		{
			var key:Object;
			
			// create temporary Dictionary mapping key to its boolean include status
			var remainingKeys:Dictionary = new Dictionary();
			for each (key in _uniqueKeys)
				remainingKeys[key] = true;
			for each (key in keysToRemove)
				remainingKeys[key] = false;
			
			// save record keys and data in new vector
			var recordKeys:Vector.<IQualifiedKey> = new Vector.<IQualifiedKey>();
			var recordData:Vector.<String> = new Vector.<String>();
			for (key in remainingKeys)
			{
				if (remainingKeys[key] == undefined || !(remainingKeys[key] as Boolean))
					continue;
				recordKeys.push(key as IQualifiedKey);
				recordData.push(_uniqueStrings[_keyToUniqueStringIndexMapping[key] as int] as String);
			}
			
			// replace existing column data with the new subset
			// everything needs to be updated because uniqueString indices are now invalid
			updateRecords(recordKeys, recordData, true);
		}

		public function updateRecords(keys:Vector.<IQualifiedKey>, stringData:Vector.<String>, clearExistingRecords:Boolean):void
		{
			if (keys.length > stringData.length)
			{
				trace("WARNING: keys vector length > data vector length. keys truncated.",keys,stringData);
				keys.length = stringData.length;
			}

			// create Dictionary mapping keys to data
			var dataMap:Dictionary = new Dictionary();
			// if existing records should be kept, copy them to dataMap
			if (!clearExistingRecords)
			{
				for (var key:Object in _keyToUniqueStringIndexMapping)
				{
					dataMap[key] = _uniqueStrings[_keyToUniqueStringIndexMapping[key]] as String;
				}
			}
			// copy new records to dataMap, overwriting any existing records
			for (var i:int = 0; i < keys.length; i++)
			{
				dataMap[keys[i]] = String(stringData[i]);
			}
			replaceRecordDataWithDataMap(dataMap);
		}
		
		/**
		 * replaceRecordDataWithDataMap
		 * This function replaces all the data in the column using the given dataMap (key -> data).
		 * @param dataMap A Dictionary mapping keys to record data.
		 */
		private function replaceRecordDataWithDataMap(dataMap:Dictionary):void
		{
			var key:Object;
			var index:int;

			// save current key-to-data mapping as a list of keys that changed			
			var keysThatChanged:Dictionary = _keyToUniqueStringIndexMapping;
			_keyToUniqueStringIndexMapping = new Dictionary();
			
			// save a list of data values
			index = 0;
			for (key in dataMap)
			{
				// remember that this key changed
				keysThatChanged[key] = true;
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
			for (key in dataMap)
				_keyToUniqueStringIndexMapping[key] = stringToIndexMap[dataMap[key] as String];

			// update _keysLastUpdated
			index = 0;
			for (key in keysThatChanged)
				_keysLastUpdated[index++] = key;
			_keysLastUpdated.length = index; // trim to new size
			
			// run callbacks while keysLastUpdated is set
			triggerCallbacks();
			
			// clear keys last updated
			_keysLastUpdated.length = 0;
		}
		
		// find the closest string value at a given normalized value
		public function deriveStringFromNumber(number:Number):String
		{
			number = Math.round(number);
			if (0 <= number && number < _uniqueStrings.length)
				return _uniqueStrings[number];
			else
			{
				//return "Undefined at "+number;
				return "";
			}
		}
		
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			var index:Number = _keyToUniqueStringIndexMapping[key];
			
			if (dataType == Number)
				return index;
			
			if (dataType == null)
				dataType = String;
			
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
