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
	
	import weave.api.WeaveAPI;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableString;
	import weave.core.LinkableVariable;
	
	/**
	 * This column is defined by two columns of CSV data: keys and values.
	 * 
	 * @author adufilie
	 */
	public class CSVColumn extends AbstractAttributeColumn implements IAttributeColumn
	{
		public function CSVColumn()
		{
			numericMode.value = false;
		}
		
		override public function getMetadata(propertyName:String):String
		{
			switch (propertyName)
			{
				case ColumnMetadata.TITLE: return title.value;
				case ColumnMetadata.KEY_TYPE: return keyType.value;
				case ColumnMetadata.DATA_TYPE: return numericMode.value ? DataTypes.NUMBER : DataTypes.STRING;
			}
			return super.getMetadata(propertyName);
		}

		public const title:LinkableString = newLinkableChild(this, LinkableString);

		/**
		 * This should contain a two-column CSV with the first column containing the keys and the second column containing the values.
		 */
		public const data:LinkableVariable = newLinkableChild(this, LinkableVariable, invalidate);
		
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
		public const keyType:LinkableString = newLinkableChild(this, LinkableString, invalidate);
		
		/**
		 * If this is set to true, the data will be parsed as numbers to produce the numeric data.
		 * If this is set to false, the numeric data for the column will be the row index.
		 */
		public const numericMode:LinkableBoolean = newLinkableChild(this, LinkableBoolean, invalidate);

		private var _keyToIndexMap:Dictionary = null; // This maps a key to a row index.
		private var _keys:Array = new Array(); // list of keys from the first CSV column
		private var _stringValues:Vector.<String> = new Vector.<String>(); // list of Strings from the first CSV column
		private var _numberValues:Vector.<Number> = new Vector.<Number>(); // list of Numbers from the first CSV column

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
			_keyToIndexMap = new Dictionary();
			_keys.length = 0;
			_stringValues.length = 0;
			_numberValues.length = 0;
			
			var key:IQualifiedKey;
			var value:String;
			var table:Array = data.getSessionState() as Array || [];
			for (var i:int = 0; i < table.length; i++)
			{
				var row:Array = table[i] as Array;
				if (row.length == 0)
					continue; // skip blank lines

				// get the key from the first column and the value from the second.
				key = WeaveAPI.QKeyManager.getQKey(keyType.value, row[0] as String);
				value = (row.length > 1 ? row[1] : '') as String;
				
				// save the results of parsing the CSV row
				_keyToIndexMap[key] = _keys.length;
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
			
			return _keyToIndexMap[key] != undefined;
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
			var keyIndex:Number = _keyToIndexMap[key];
			
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
