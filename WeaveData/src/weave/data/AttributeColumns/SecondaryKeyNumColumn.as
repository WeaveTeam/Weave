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
	
	import mx.formatters.NumberFormatter;
	
	import weave.api.data.IPrimitiveColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.compiler.MathLib;
	import weave.core.LinkableString;
	import weave.api.data.AttributeColumnMetadata;
	
	/**
	 * SecondaryKeyColumn
	 * 	
	 */
	public class SecondaryKeyNumColumn extends AbstractAttributeColumn implements IPrimitiveColumn
	{
		public function SecondaryKeyNumColumn(metadata:XML = null)
		{
			super();
			//super(metadata);
		}

		/**
		 * This function overrides the min,max values.
		 */
		override public function getMetadata(propertyName:String):String
		{
			switch (propertyName)
			{
				case AttributeColumnMetadata.MIN: return String(_minNumber);
				case AttributeColumnMetadata.MAX: return String(_maxNumber);
			}
			return super.getMetadata(propertyName);
		}
		
		private var _minNumber:Number = NaN; // returned by getMetadata
		private var _maxNumber:Number = NaN; // returned by getMetadata
		
		/**
		 * _keyToNumericDataMapping
		 * This object maps keys to data values.
		 */
		protected var _keyToNumericDataMapping:Dictionary = new Dictionary();

		/**
		 * uniqueStrings
		 * Derived from the record data, this is a list of all existing values in the dimension, each appearing once, sorted alphabetically.
		 */
		private var _uniqueStrings:Vector.<String> = new Vector.<String>();

		/**
		 * */
		public const _currentSecondaryKeyValue:LinkableString = newLinkableChild(this, LinkableString);
		public function set currentSecondaryKey(key:String):void
		{
			if (_currentSecondaryKeyValue.value != key)
			{
				_currentSecondaryKeyValue.value = key;
				triggerCallbacks();
			}
		}
		public function get currentSecondaryKey():String
		{
			return _currentSecondaryKeyValue.value;
		}
		
		protected const _uniqueSecondaryKeys:Array = new Array();
		public function get secondaryKeys():Array
		{
			return _uniqueSecondaryKeys;
		}
		public function allSecondaryKeys():Array
		{
			var allSecKeys:Array = new Array();
			for each (var key:IQualifiedKey in _uniqueKeysA)
			{
				var foo:Object = _keyToNumericDataMapping[key];
				var bar:Array = foo as Array;
				//for each (var keyB:String in foo)
				for (var keyB:String in foo)
				{
					allSecKeys.push(keyB);
				}
			}
			return allSecKeys;
		}

		/**
		 * _uniqueKeys
		 * This is a list of unique keys this column defines values for.
		 */
		protected const _uniqueKeysA:Array = new Array();
		override public function get keys():Array
		{
			return _uniqueKeysA;
		}

		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		override public function containsKey(key:IQualifiedKey):Boolean
		{
			if (_keyToNumericDataMapping[key] == null)
				return false;
			return _keyToNumericDataMapping[key][currentSecondaryKey] != undefined;
		}

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
			var key:Object; // IQualifiedKey

			// remove records and keep track of which keys were removed
			var index:int = 0;
			for each (key in keysToRemove)
			{
				if (_keyToNumericDataMapping[key][currentSecondaryKey] != undefined)
				{
					delete _keyToNumericDataMapping[key][currentSecondaryKey];
					_keysLastUpdated[index++] = key;
				}
			}
			_keysLastUpdated.length = index; // trim to new size
			
			// update list of unique keys
			index = 0;
			for (key in _keyToNumericDataMapping)
			{
				_uniqueKeysA[index++] = key;
			}
			_uniqueKeysA.length = index; // trim to new size
			index = 0;
			for (key in _keyToNumericDataMapping[0])
			{
				_uniqueSecondaryKeys[index++] = key;
			}
			_uniqueSecondaryKeys.length = index; // trim to new size

			// run callbacks while keysLastUpdated is set
			triggerCallbacks();

			// clear keys last updated
			_keysLastUpdated.length = 0;
		}
		
		public function updateRecords(keysA:Vector.<IQualifiedKey>, keysB:Vector.<String>, data:Array, clearExistingRecords:Boolean = false):void
		{
			var index:int, qkeyA:IQualifiedKey, keyB:String;
			var _keyA:*;
			var dataObject:Object = null;

			if (keysA.length > data.length)
			{
				trace("WARNING: keys vector length > data vector length. keys truncated.",keysA.length,data.length);
				keysA.length = data.length; // numericData.length;
			}
			
			// save a map of keys that changed			
			var keysThatChanged:Dictionary = clearExistingRecords ? _keyToNumericDataMapping : new Dictionary();

			// clear previous data mapping if requested
			if (clearExistingRecords)
				_keyToNumericDataMapping = new Dictionary();
			
			//if it's string data - create list of unique strings
			if (data[0] is String)
			{
				for (var i:int = 0; i < data.length; i++)
				{
					if (_uniqueStrings.indexOf(data[i]) < 0)
						_uniqueStrings.push(data[i]);
				}
				_uniqueStrings.sort(Array.CASEINSENSITIVE);
				
				// min,max numbers are the min,max indices in the unique strings array
				_minNumber = 0;
				_maxNumber = _uniqueStrings.length - 1; 
			}
			else
			{
				// reset min,max before looping over records
				_minNumber = NaN;
				_maxNumber = NaN;
			}
			
			// save a mapping from keys to data
			//for (index = keysA.length - 1; index >= 0; index--)
			for (index = 0; index < keysA.length; index++)
			{
				qkeyA = keysA[index] as IQualifiedKey;
				keyB = keysB[index] as String;
				//if we don't already have keyB - add it to _uniqueKeysB
				//  @todo - optimize this - searching every time is not the optimal method
				if (_uniqueSecondaryKeys.indexOf(keyB) < 0)
					_uniqueSecondaryKeys.push(keyB);
				if (! _keyToNumericDataMapping[qkeyA])
					_keyToNumericDataMapping[qkeyA] = new Dictionary();
				dataObject = data[index];
				if (dataObject is String)
				{
					var iString:int = _uniqueStrings.indexOf(dataObject as String);
					if (iString < 0)
					{
						//iString = _uniqueStrings.push(dataObject as String) - 1;
						iString = _uniqueStrings.length;
						_uniqueStrings[iString] = dataObject as String;
					}
					_keyToNumericDataMapping[qkeyA][keyB] = iString;
				}
				else
				{
					_keyToNumericDataMapping[qkeyA][keyB] = data[index];//Number(data[index]);
					
					_minNumber = isNaN(_minNumber) ? data[index] : Math.min(_minNumber, data[index]);
					_maxNumber = isNaN(_maxNumber) ? data[index] : Math.max(_maxNumber, data[index]);
				}
				if (!keysThatChanged[qkeyA])
					keysThatChanged[qkeyA] = new Dictionary();
				keysThatChanged[qkeyA][keyB] = true; // remember that this key changed
			}
			_currentSecondaryKeyValue.value = keysB[0];
			// save list of unique keys
			index = 0;
			for (_keyA in _keyToNumericDataMapping)
				_uniqueKeysA[index++] = _keyA;
			_uniqueKeysA.length = index; // trim to new size
			
			// update _keysLastUpdated
			index = 0;
			for (_keyA in keysThatChanged)
				_keysLastUpdated[index++] = _keyA;
			_keysLastUpdated.length = index; // trim to new size
			
			// run callbacks while keysLastUpdated is set
			triggerCallbacks();
			
			// clear keys last updated
			_keysLastUpdated.length = 0;
		}

		/**
		 * numberFormatter:
		 * the NumberFormatter to use when generating a string from a number
		 */
		private var _numberFormatter:NumberFormatter = new NumberFormatter();
		public function get numberFormatter():NumberFormatter
		{
			return _numberFormatter;
		}
		public function set numberFormatter(value:NumberFormatter):void
		{
			_numberFormatter = value;
		}

		/**
		 * maxDerivedSignificantDigits:
		 * maximum number of significant digits to return when calling deriveStringFromNorm()
		 */		
		public var maxDerivedSignificantDigits:uint = 10;
		
		// get a string value for a given numeric value
		public function deriveStringFromNumber(number:Number):String
		{
			if (int(number) == number && (_uniqueStrings.length > 0) && (number < _uniqueStrings.length))
			{
				return _uniqueStrings[number];
				//return the first value for this key
				/*
				var primKeyMapping:Object = _keyToNumericDataMapping[number];
				if (primKeyMapping)
				{
					//not sure how to get first object - temporary simple way to do it
					var firstOne:Object = null;
					for each (firstOne in primKeyMapping) 
					{
						break;
					}
					var secKeyMapping:Object = _keyToNumericDataMapping[number][0];
					return secKeyMapping as String;
				}
				*/
			}
			if (numberFormatter == null)
					return number.toString();
			else
				return numberFormatter.format(
						MathLib.roundSignificant(
							number,
							maxDerivedSignificantDigits
						)
					);
		}

		public function getValueFromKeys(primaryQKey:IQualifiedKey, secondaryKeyString:String):*
		{
			if (_keyToNumericDataMapping[primaryQKey] && (_keyToNumericDataMapping[primaryQKey][secondaryKeyString] != null))
				return (_keyToNumericDataMapping[primaryQKey][secondaryKeyString]);
			else
				return Number.NEGATIVE_INFINITY;			
		}
		/**
		 * get data from key value
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (dataType == String)
			{
				if (_keyToNumericDataMapping[key])
				{
					var obj:Object = _keyToNumericDataMapping[key][currentSecondaryKey];
					if (obj != null)
					{
						if (obj is String)
							return obj as String;
						else
							return deriveStringFromNumber(_keyToNumericDataMapping[key][currentSecondaryKey]);
					}
				}
				else
					return null;
			}
			var ret:Object = getValueFromKeys(key, currentSecondaryKey);
			return ret;
		}

		override public function toString():String
		{
			return getQualifiedClassName(this).split("::")[1] + '{recordCount: '+keys.length+', keyType: "'+getMetadata('keyType')+'", title: "'+getMetadata('title')+'"}';
		}

	}
}
