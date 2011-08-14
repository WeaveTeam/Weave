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

package weave.utils
{
	import flash.utils.Dictionary;
	
	import weave.api.WeaveAPI;
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.compiler.BooleanLib;
	
	/**
	 * This class contains static functions that access values from IAttributeColumn objects.
	 * 
	 * @author adufilie
	 */
	public class ColumnUtils
	{
		/**
		 * This is a shortcut for column.getMetadata(AttributeColumnMetadata.TITLE).
		 * @param column A column to get the title of.
		 * @return The title of the column.
		 */		
		public static function getTitle(column:IAttributeColumn):String
		{
			var title:String = column.getMetadata(AttributeColumnMetadata.TITLE) || '';
			
			// TEMPORARY SOLUTION -- INSTEAD, DATA SOURCE SHOULD DO THIS
			if (title == '')
				title = column.getMetadata('name') || '';
			
			if (title == '')
				title = 'Undefined';
			
			// hack -- this should be replaced by a "default title formatting function" like "title (year)"
			var year:String = column.getMetadata('year') || '';
			if (year != '')
				title += '(' + year + ')';
			
			// debug code
			if (false)
			{
				var keyType:String = column.getMetadata(AttributeColumnMetadata.KEY_TYPE) || '';
				if (keyType == '')
					title += " (No key type)";
				else
					title += " (Key type: " + keyType + ")";
			}

			return title;
		}

		/**
		 * This function gets the keyType of a column, either from the metadata or from the actual keys.
		 * @param column A column to get the keyType of.
		 * @return The keyType of the column.
		 */
		public static function getKeyType(column:IAttributeColumn):String
		{
			// first try getting the keyType from the metadata.
			var keyType:String = column.getMetadata(AttributeColumnMetadata.KEY_TYPE);
			if (keyType == null)
			{
				// if metadata does not specify keyType, get it from the first key in the list of keys.
				var keys:Array = column.keys;
				if (keys.length > 0)
					keyType = (keys[0] as IQualifiedKey).keyType;
			}
			return keyType;
		}
		
		/**
		 * This function gets the dataType of a column from its metadata.
		 * @param column A column to get the dataType of.
		 * @return The dataType of the column.
		 */
		public static function getDataType(column:IAttributeColumn):String
		{
			return column.getMetadata(AttributeColumnMetadata.DATA_TYPE);
		}
		
		/**
		 * @param column A column to get a value from.
		 * @param key A key in the given column to get the value for.
		 * @return The Number corresponding to the given key.
		 */
		public static function getNumber(column:IAttributeColumn, key:IQualifiedKey):Number
		{
			if (column != null)
				return column.getValueFromKey(key, Number);
			return NaN;
		}
		/**
		 * @param column A column to get a value from.
		 * @param key A key in the given column to get the value for.
		 * @return The String corresponding to the given key.
		 */
		public static function getString(column:IAttributeColumn, key:IQualifiedKey):String
		{
			if (column != null)
				return column.getValueFromKey(key, String) as String;
			return '';
		}
		/**
		 * @param column A column to get a value from.
		 * @param key A key in the given column to get the value for.
		 * @return The Boolean corresponding to the given key.
		 */
		public static function getBoolean(column:IAttributeColumn, key:IQualifiedKey):Boolean
		{
			if (column != null)
				return BooleanLib.toBoolean( column.getValueFromKey(key) );
			return false;
		}
		/**
		 * @param column A column to get a value from.
		 * @param key A key in the given column to get the value for.
		 * @return The Number corresponding to the given key, normalized to be between 0 and 1.
		 */
		public static function getNorm(column:IAttributeColumn, key:IQualifiedKey):Number
		{
			if (column != null)
			{
				var min:Number = WeaveAPI.StatisticsCache.getMin(column);
				var max:Number = WeaveAPI.StatisticsCache.getMax(column);
				var value:Number = column.getValueFromKey(key, Number);
				return (value - min) / (max - min);
			}
			return NaN;
		}

		/**
		 * This function takes the common keys from a list of columns and generates a table of data values for each key from each specified column.
		 * @param columns A list of IAttributeColumns to compute a join table from.
		 * @param dataType The dataType parameter to pass to IAttributeColumn.getValueFromKey().
		 * @param allowMissingData If this is set to true, then all keys will be included in the join result.  Otherwise, only the keys that have associated values will be included.
		 * @param keys A list of IQualifiedKey objects to use to filter the results.
		 * @return An Array of Arrays, the first being IQualifiedKeys and the rest being Arrays data values from the given columns that correspond to the IQualifiedKeys. 
		 */
		public static function joinColumns(columns:Array, dataType:Class = null, allowMissingData:Boolean = false, keys:Array = null):Array
		{
			var key:IQualifiedKey;
			var column:IAttributeColumn;
			// if no keys are specified, get the keys from the columns
			if (keys == null)
			{
				// count the number of appearances of each key in each column
				var keyCounts:Dictionary = new Dictionary();
				for each (column in columns)
					for each (key in column.keys)
						keyCounts[key] = int(keyCounts[key]) + 1;
				// get a list of keys that appeared in every column
				keys = [];
				for (var qkey:* in keyCounts)
					if (allowMissingData || keyCounts[qkey] == columns.length)
						keys.push(qkey);
			}
			else
			{
				keys = keys.concat(); // make a copy so we don't modify the original
			}
			// put the keys in the result
			var result:Array = [keys];
			// get all the data values in the same order as the common keys
			for (var cIndex:int = 0; cIndex < columns.length; cIndex++)
			{
				column = columns[cIndex];
				var values:Array = [];
				for (var kIndex:int = 0; kIndex < keys.length; kIndex++)
				{
					var value:* = column.getValueFromKey(keys[kIndex] as IQualifiedKey, dataType);
					if (!allowMissingData && BooleanLib.isUndefined(value))
					{
						// value is undefined, so remove this key and all associated data from the list
						for each (var array:Array in result)
							array.splice(kIndex, 1);
						kIndex--; // avoid skipping the next key
					}
					else
					{
						values.push(value);
					}
				}
				result.push(values);
			}
			return result;
		}	
	}
}
