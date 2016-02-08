/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weavejs.data.column
{
	import weavejs.WeaveAPI;
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.DataType;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.core.LinkableBoolean;
	import weavejs.core.LinkableString;
	import weavejs.core.LinkableVariable;
	import weavejs.data.column.AbstractAttributeColumn;
	import weavejs.util.JS;
	
	/**
	 * This column is defined by two columns of CSV data: keys and values.
	 * 
	 * @author adufilie
	 */
	public class CSVColumn extends AbstractAttributeColumn implements IAttributeColumn
	{
		public function CSVColumn()
		{
			super();
			numericMode.value = false;
		}
		
		override public function getMetadata(propertyName:String):String
		{
			switch (propertyName)
			{
				case ColumnMetadata.TITLE: return title.value;
				case ColumnMetadata.KEY_TYPE: return keyType.value;
				case ColumnMetadata.DATA_TYPE: return numericMode.value ? DataType.NUMBER : DataType.STRING;
			}
			return super.getMetadata(propertyName);
		}

		public const title:LinkableString = Weave.linkableChild(this, LinkableString);

		/**
		 * This should contain a two-column CSV with the first column containing the keys and the second column containing the values.
		 */
		public const data:LinkableVariable = Weave.linkableChild(this, LinkableVariable, invalidate);
		
		/**
		 * Use this function to set the keys and data of the column.
		 * @param table An Array of rows where each row is an Array containing a key and a data value.
		 */		
		public function setDataTable(table:Array):void
		{
			var stringTable:Array = [];
			for (var r:int = 0; r < table.length; r++)
			{
				var row:Array = (table[r] as Array).concat(); // make a copy of the row
				// convert each value to a string
				for (var c:int = 0; c < row.length; c++)
					row[c] = String(row[c]);
				stringTable[r] = row; // save the copied row
			}
			data.setSessionState(stringTable);
		}

		
		[Deprecated] public function set csvData(value:String):void
		{
			data.setSessionState(WeaveAPI.CSVParser.parseCSV(value));
		}
		
		/**
		 * This is the key type of the first column in the csvData.
		 */
		public const keyType:LinkableString = Weave.linkableChild(this, LinkableString, invalidate);
		
		/**
		 * If this is set to true, the data will be parsed as numbers to produce the numeric data.
		 */
		public const numericMode:LinkableBoolean = Weave.linkableChild(this, LinkableBoolean, invalidate);

		private var map_key_index:Object = null; // This maps a key to a row index.
		private var _keys:Array = []; // list of keys from the first CSV column
		private var _stringValues:Array = []; // list of Strings from the first CSV column
		private var _numberValues:Array = []; // list of Numbers from the first CSV column

		/**
		 * This value is true when the data changed and the lookup tables need to be recreated.
		 */
		private var dirty:Boolean = true;
		
		/**
		 * This function gets called when csvData changes.
		 */
		private function invalidate():void
		{
			dirty = true;
		}

		/**
		 * This function generates three Vectors from the CSV data: _keys, _stringValues, _numberValues
		 */
		private function validate():void
		{
			// replace the previous _keyToIndexMap with a new empty one
			map_key_index = new JS.Map();
			_keys.length = 0;
			_stringValues.length = 0;
			_numberValues.length = 0;
			
			var key:IQualifiedKey;
			var value:String;
			var table:Array = data.getSessionState() as Array || [];
			for (var i:int = 0; i < table.length; i++)
			{
				var row:Array = table[i] as Array;
				if (row == null || row.length == 0)
					continue; // skip blank lines

				// get the key from the first column and the value from the second.
				key = WeaveAPI.QKeyManager.getQKey(keyType.value, String(row[0]));
				value = String(row.length > 1 ? row[1] : '');
				
				// save the results of parsing the CSV row
				map_key_index.set(key, _keys.length);
				_keys.push(key);
				_stringValues.push(value);
				try
				{
					_numberValues.push(Number(value));
				}
				catch (e:Error)
				{
					_numberValues.push(NaN);
				}
			}
			dirty = false;
		}
		
		/**
		 * This function returns the list of String values from the first column in the CSV data.
		 */
		override public function get keys():Array
		{
			// refresh the data if necessary
			if (dirty)
				validate();
			
			return _keys;
		}

		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		override public function containsKey(key:IQualifiedKey):Boolean
		{
			// refresh the data if necessary
			if (dirty)
				validate();
			
			return map_key_index.has(key);
		}
		
		/**
		 * This function returns the corresponding numeric or string value depending on the dataType parameter and the numericMode setting.
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class=null):*
		{
			// refresh the data if necessary
			if (dirty)
				validate();
			
			// get the index from the key
			var keyIndex:Number = map_key_index.get(key);
			
			// cast to different data types
			if (dataType == Boolean)
			{
				return !isNaN(keyIndex);
			}
			if (dataType == Number)
			{
				if (isNaN(keyIndex))
					return NaN;
				return _numberValues[keyIndex];
			}
			if (dataType == String)
			{
				if (isNaN(keyIndex))
					return '';
				return _stringValues[keyIndex];
			}

			// return default data type
			if (isNaN(keyIndex))
				return numericMode.value ? NaN : '';
			
			if (numericMode.value)
				return _numberValues[keyIndex];
			
			return _stringValues[keyIndex];
		}
	}
}
