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
	
	import mx.formatters.NumberFormatter;
	
	import weave.api.data.IPrimitiveColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.IStreamedColumn;
	import weave.compiler.StandardLib;
	
	/**
	 * NumericColumn
	 * 
	 * @author adufilie
	 */
	public class NumberColumn extends AbstractAttributeColumn implements IStreamedColumn, IPrimitiveColumn
	{
		public function NumberColumn(metadata:XML = null)
		{
			super(metadata);
		}
		
		/**
		 * _keyToNumericDataMapping
		 * This object maps keys to data values.
		 */
		protected var _keyToNumericDataMapping:Dictionary = new Dictionary();

		/**
		 * _uniqueKeys
		 * This is a list of unique keys this column defines values for.
		 */
		protected const _uniqueKeys:Array = new Array();
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
			return _keyToNumericDataMapping[key] != undefined;
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
			var key:Object;

			// remove records and keep track of which keys were removed
			var index:int = 0;
			for each (key in keysToRemove)
			{
				if (_keyToNumericDataMapping[key] != undefined)
				{
					delete _keyToNumericDataMapping[key];
					_keysLastUpdated[index++] = key;
				}
			}
			_keysLastUpdated.length = index; // trim to new size
			
			// update list of unique keys
			index = 0;
			for (key in _keyToNumericDataMapping)
				_uniqueKeys[index++] = key;
			_uniqueKeys.length = index; // trim to new size

			// run callbacks while keysLastUpdated is set
			triggerCallbacks();

			// clear keys last updated
			_keysLastUpdated.length = 0;
		}
		
		public function updateRecords(keys:Vector.<IQualifiedKey>, numericData:Vector.<Number>, clearExistingRecords:Boolean = false):void
		{
			var index:int;
			var key:Object;

			if (keys.length > numericData.length)
			{
				trace("WARNING: keys vector length > data vector length. keys truncated.",keys,numericData);
				keys.length = numericData.length;
			}
			
			// save a map of keys that changed			
			var keysThatChanged:Dictionary = clearExistingRecords ? _keyToNumericDataMapping : new Dictionary();

			// clear previous data mapping if requested
			if (clearExistingRecords)
				_keyToNumericDataMapping = new Dictionary();
			
			// save a mapping from keys to data
			for (index = keys.length - 1; index >= 0; index--)
			{
				key = keys[index] as IQualifiedKey;
				var n:Number = Number(numericData[index]);
				if(isFinite(n))
				{
					_keyToNumericDataMapping[key] = n;
					keysThatChanged[key] = true; // remember that this key changed
				}
			}

			// save list of unique keys
			index = 0;
			for (key in _keyToNumericDataMapping)
				_uniqueKeys[index++] = key;
			_uniqueKeys.length = index; // trim to new size
			
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
			if (numberFormatter == null)
				return number.toString();
			else
			{
				return numberFormatter.format(
					StandardLib.roundSignificant(
							number,
							maxDerivedSignificantDigits
						)
					);
			}
		}

		/**
		 * get data from key value
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (dataType == String)
				return deriveStringFromNumber(_keyToNumericDataMapping[key]);
			// make sure to cast as a Number so missing values return as NaN instead of undefined
			return Number(_keyToNumericDataMapping[key]);
		}

		override public function toString():String
		{
			return getQualifiedClassName(this).split("::")[1] + '{recordCount: '+keys.length+', keyType: "'+getMetadata('keyType')+'", title: "'+getMetadata('title')+'"}';
		}
	}
}
