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
	
	import mx.utils.ObjectUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.IQualifiedKey;
	import weave.api.detectLinkableObjectChange;
	import weave.data.QKeyManager;
	import weave.utils.AsyncSort;
	import weave.utils.ColumnUtils;
	
	/**
	 * This column maps a String to an Array of keys that
	 * have matching String values in the referenced column. 
	 * 
	 * @author adufilie
	 */
	public class StringLookupColumn extends DynamicColumn
	{
		public function StringLookupColumn()
		{
			super();
			addImmediateCallback(this, handleInternalColumnChange);
		}
		
		override public function getMetadata(propertyName:String):String
		{
			switch (propertyName)
			{
				case AttributeColumnMetadata.KEY_TYPE:
					return _keyType;
				case AttributeColumnMetadata.DATA_TYPE:
					return getInternalColumn() ? ColumnUtils.getKeyType(getInternalColumn()) : null;
			}
			return super.getMetadata(propertyName);
		}
		
		/**
		 * This function gets called when the referenced column changes.
		 */
		protected function handleInternalColumnChange():void
		{
			// update unit
			if (getInternalColumn() != null)
			{
				_keyType = getInternalColumn().getMetadata(AttributeColumnMetadata.DATA_TYPE);
				if (!_keyType)
					_keyType = DataTypes.STRING;
			}
		}
		
		private var _keyType:String = DataTypes.STRING;
		
		/**
		 * This object maps a String value from the internal column to an Array of keys that map to that value.
		 */
		private var _keyLookup:Dictionary = null;
		
		/**
		 * This object maps a String value from the internal column to the Number value corresponding to that String values in the internal column.
		 */
		private var _numberLookup:Dictionary = null;
		
		/**
		 * This keeps track of a list of unique string values contained in the internal column.
		 */
		private const _uniqueStringKeys:Array = new Array();
		
		/**
		 * This function returns the unique strings of the internal column.
		 * @return The keys this column defines values for.
		 */
		override public function get keys():Array
		{
			createLookupTable();
			return _uniqueStringKeys;
		}

		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		override public function containsKey(key:IQualifiedKey):Boolean
		{
			createLookupTable();
			return _keyLookup[key] != undefined;
		}
		
		/**
		 * This function will initialize the string lookup table and list of unique strings.
		 */
		private function createLookupTable():void
		{
			if (!detectLinkableObjectChange(createLookupTable, getInternalColumn()))
				return;
			
			// reset
			_uniqueStringKeys.length = 0;
			_keyLookup = new Dictionary();
			_numberLookup = new Dictionary();
			// loop through all the keys in the internal column
			var keys:Array = getInternalColumn() ? getInternalColumn().keys : [];
			for (var i:int = 0; i < keys.length; i++)
			{
				var key:IQualifiedKey = keys[i];
				var stringValue:String = getInternalColumn().getValueFromKey(key, String) as String;
				if (stringValue == null)
					continue;
				var stringKey:IQualifiedKey = WeaveAPI.QKeyManager.getQKey(_keyType, stringValue);
				// save the mapping from the String value to the key
				if (_keyLookup[stringKey] is Array)
				{
					// string value was found previously
					(_keyLookup[stringKey] as Array).push(key);
				}
				else
				{
					// found new string value
					_keyLookup[stringKey] = [key];
					_uniqueStringKeys.push(stringKey);
				}
				// save the mapping from the String value to the corresponding Number value
				var numberValue:Number = getInternalColumn().getValueFromKey(key, Number);
				if (_numberLookup[stringKey] == undefined) // no number stored yet
				{
					_numberLookup[stringKey] = numberValue;
				}
				else if (!isNaN(_numberLookup[stringKey]) && _numberLookup[stringKey] != numberValue)
				{
					_numberLookup[stringKey] = NaN; // different numbers are mapped to the same String, so save NaN.
				}
			}
			// sort the unique values because these will be the keys and we want them to be in a predictable order
			AsyncSort.sortImmediately(_uniqueStringKeys, compareStringKeys);
			
			detectLinkableObjectChange(createLookupTable, getInternalColumn());
		}

		/**
		 * This function uses _stringToNumberMap to get a numeric value to compare for each string value.
		 * If the numeric compare returns zero, it does a string compare on the string values instead.
		 */
		private function compareStringKeys(stringKey1:IQualifiedKey, stringKey2:IQualifiedKey):int
		{
			return ObjectUtil.numericCompare(_numberLookup[stringKey1], _numberLookup[stringKey2])
				|| QKeyManager.keyCompare(stringKey1, stringKey2);
		}

		/**
		 * @param stringValue A string value existing in the internal column.
		 * @param dataType A requested return type.
		 * @return If dataType is not specified, returns an Array of IQualifiedKeys that map to the given string value in the internal column.
		 */
		override public function getValueFromKey(stringKey:IQualifiedKey, dataType:Class = null):*
		{
			// The String value associated with stringValue is itself -- no lookup table required.
			if (dataType == String)
				return stringKey.localName;
			
			// The default dataType to return is an Array of keys that map to this stringValue in the internal column.
			if (getInternalColumn() != null)
			{
				// validate lookup table if necessary
				createLookupTable();
				
				if (dataType == Number)
					return Number(_numberLookup[stringKey]); // the Number associated with the stringValue
				
				// get the list of internal keys from the given stringValue
				var result:* = (_keyLookup[stringKey] as Array) || (_keyLookup[stringKey] = []);
				
				if (dataType == Boolean)
					return result.length > 0; // true if there are keys associated with the stringValue
				
				return result; // return the Array of keys associated with the stringValue
			}
			else
			{
				if (dataType == Number)
					return NaN; // no Number value associated with the stringValue
				if (dataType == Boolean)
					return false; // no keys associated with the stringValue
				return []; // no keys associated with the stringValue
			}
		}
		
		/**
		 * This function gets a key that can be passed to getValueFromKey to look up other internal column keys having the same internalColumn String value.
		 * @param internalColumnKey A record identifier used in the internal column.
		 * @return The IQualifiedKey that can be used to pass to getValueFromKey to look up other internal column keys having the same internalColumn String value.
		 */
		public function getStringLookupKeyFromInternalColumnKey(internalColumnKey:IQualifiedKey):IQualifiedKey
		{
			if (internalColumnKey == null)
				return null;
			
			// validate lookup table if necessary
			createLookupTable();
			
			var stringValue:String = getInternalColumn().getValueFromKey(internalColumnKey, String) as String;
			return WeaveAPI.QKeyManager.getQKey(_keyType, stringValue);
		}
	}
}
