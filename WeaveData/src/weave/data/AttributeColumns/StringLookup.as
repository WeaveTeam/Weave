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
	import mx.utils.ObjectUtil;
	
	import weave.api.core.ILinkableObject;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.registerLinkableChild;
	
	/**
	 * This provides a reverse lookup of String values in an IAttributeColumn.
	 * 
	 * @author adufilie
	 */
	public class StringLookup implements ILinkableObject
	{
		public function StringLookup(column:IAttributeColumn)
		{
			internalColumn = column;
			column.addImmediateCallback(this, handleInternalColumnChange);
			if (column is ILinkableObject)
				registerLinkableChild(this, column as ILinkableObject)
		}
		
		private var internalColumn:IAttributeColumn;
		
		/**
		 * This function gets called when the referenced column changes.
		 */
		protected function handleInternalColumnChange():void
		{
			// invalidate lookup
			_stringToKeysMap = null;
			_stringToNumberMap = null;
			_uniqueStringValues.length = 0;
		}
		
		/**
		 * This object maps a String value from the internal column to an Array of keys that map to that value.
		 */
		private var _stringToKeysMap:Object = null;
		
		/**
		 * This object maps a String value from the internal column to the Number value corresponding to that String values in the internal column.
		 */
		private var _stringToNumberMap:Object = null;
		
		/**
		 * This keeps track of a list of unique string values contained in the internal column.
		 */
		private const _uniqueStringValues:Array = new Array();
		
		/**
		 * This is a list of the unique strings of the internal column.
		 */
		public function get uniqueStrings():Array
		{
			if (_stringToKeysMap == null)
				createLookupTable();
			return _uniqueStringValues;
		}

		/**
		 * This function will initialize the string lookup table and list of unique strings.
		 */
		private function createLookupTable():void
		{
			// reset
			_uniqueStringValues.length = 0;
			_stringToKeysMap = new Object();
			_stringToNumberMap = new Object();
			// loop through all the keys in the internal column
			var keys:Array = internalColumn ? internalColumn.keys : [];
			for (var i:int = 0; i < keys.length; i++)
			{
				var key:IQualifiedKey = keys[i];
				var stringValue:String = internalColumn.getValueFromKey(key, String) as String;
				if (stringValue == null)
					continue;
				// save the mapping from the String value to the key
				if (_stringToKeysMap[stringValue] is Array)
				{
					// string value was found previously
					(_stringToKeysMap[stringValue] as Array).push(key);
				}
				else
				{
					// found new string value
					_stringToKeysMap[stringValue] = [key];
					_uniqueStringValues.push(stringValue);
				}
				// save the mapping from the String value to the corresponding Number value
				var numberValue:Number = internalColumn.getValueFromKey(key, Number);
				if (_stringToNumberMap[stringValue] == undefined) // no number stored yet
				{
					_stringToNumberMap[stringValue] = numberValue;
				}
				else if (!isNaN(_stringToNumberMap[stringValue]) && _stringToNumberMap[stringValue] != numberValue)
				{
					_stringToNumberMap[stringValue] = NaN; // different numbers are mapped to the same String, so save NaN.
				}
			}
			// sort the unique values because we want them to be in a predictable order
			_uniqueStringValues.sort(compareNumberAndStringValues);
		}

		/**
		 * This function uses _stringToNumberMap to get a numeric value to compare for each string value.
		 * If the numeric compare returns zero, it does a string compare on the string values instead.
		 */
		private function compareNumberAndStringValues(stringValue1:String, stringValue2:String):int
		{
			return ObjectUtil.numericCompare(_stringToNumberMap[stringValue1], _stringToNumberMap[stringValue2])
				|| ObjectUtil.stringCompare(stringValue1, stringValue2);
		}

		/**
		 * @param stringValue A string value existing in the internal column.
		 * @return An Array of keys that map to the given string value in the internal column.
		 */
		public function getKeysFromString(stringValue:String):Array
		{
			// validate lookup table if necessary
			if (_stringToKeysMap == null)
				createLookupTable();
			
			// get the list of internal keys from the given stringValue
			return (_stringToKeysMap[stringValue] as Array) || (_stringToKeysMap[stringValue] = []);
		}
		
		/**
		 * @param stringValue A string value existing in the internal column.
		 * @return The Number value associated with the String value from the internal column.
		 */
		public function getNumberFromString(stringValue:String):Number
		{
			if (_stringToNumberMap == null)
				createLookupTable();
			return _stringToNumberMap[stringValue];
		}
	}
}
