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

package weavejs.data
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.ILinkableVariable;
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.DataType;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IKeySet;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.data.column.DynamicColumn;
	import weavejs.util.JS;
	import weavejs.util.StandardLib;
	
	/**
	 * This class contains static functions that access values from IAttributeColumn objects.
	 * Many of the functions in this library use the static variable 'currentRecordKey'.
	 * This value should be set before calling a function that uses it.
	 * 
	 * @author adufilie
	 */
	public class EquationColumnLib
	{
		public static var debug:Boolean = false;
		
		/**
		 * This value should be set before calling any of the functions below that get values from IAttributeColumns.
		 */
		public static var currentRecordKey:IQualifiedKey = null;
		
		/**
		 * This function calls column.getValueFromKey(currentRecordKey, IQualifiedKey)
		 * @param column A column, or null if you want the currentRecordKey to be returned.
		 * @return The value at the current record in the column cast as an IQualifiedKey.
		 */
		public static function getKey(column:IAttributeColumn = null):IQualifiedKey
		{
			if (column)
				return column.getValueFromKey(currentRecordKey, IQualifiedKey);
			return currentRecordKey;
		}
		
		/**
		 * This function uses currentRecordKey when retrieving a value from a column.
		 * @param object An IAttributeColumn or an ILinkableVariable to get a value from.
		 * @param dataType Either a Class object or a String containing the qualified class name of the desired value type.
		 * @return The value of the object, optionally cast to the requested dataType.
		 */
		public static function getValue(object:/*/IAttributeColumn|ILinkableVariable/*/Object, dataType:* = null):*
		{
			// remember current key
			var key:IQualifiedKey = currentRecordKey;
			try
			{
				if (dataType is String)
					dataType = Weave.getDefinition(dataType);
				
				var value:* = null; // the value that will be returned
				
				// get the value from the object
				var column:IAttributeColumn = object as IAttributeColumn;
				if (column != null)
				{
					if (dataType == null)
					{
						var dataTypeMetadata:String = column.getMetadata(ColumnMetadata.DATA_TYPE);
						dataType = DataType.getClass(dataTypeMetadata);
						if (dataType == String && dataTypeMetadata != DataType.STRING)
							dataType = IQualifiedKey;
					}
					value = column.getValueFromKey(key, JS.asClass(dataType));
				}
				else if (object is ILinkableVariable)
				{
					value = (object as ILinkableVariable).getSessionState();
					// cast the value to the requested type
					if (dataType != null)
						value = cast(value, dataType);
				}
				else if (dataType != null)
				{
					value = cast(value, dataType);
				}
				
				if (debug)
					JS.log('getValue',object,key.localName,String(value));
				return value;
			}
			finally
			{
				// revert to key that was set when entering the function (in case nested calls modified the static variables)
				currentRecordKey = key;
			}
		}
		/**
		 * This function calls IAttributeColumn.getValueFromKey(key, dataType).
		 * @param column An IAttributeColumn to get a value from.
		 * @param key A key to get the value for.
		 * @return The result of calling column.getValueFromKey(key, dataType).
		 */
		public static function getValueFromKey(column:IAttributeColumn, key:IQualifiedKey, dataType:* = null):*
		{
			// remember current key
			var previousKey:IQualifiedKey = currentRecordKey;
			try
			{
				currentRecordKey = key;
				var value:* = getValue(column, dataType);
				if (debug)
					JS.log('getValueFromKey',column,key.localName,String(value));
				return value;
			}
			finally
			{
				// revert to key that was set when entering the function (in case nested calls modified the static variables)
				currentRecordKey = previousKey;
			}
		}
		
		/**
		 * This function gets a value from a data column, using a filter column and a key column to filter the data
		 * @param keyColumn An IAttributeColumn to get keys from
		 * @param filter column to use to filter data (ex: year)
		 * @param data An IAttributeColumn to get a value from
		 * @param filterValue value in filtercolumn to use to filter data
		 * @param filterDataType Class object of the desired filter value type
		 * @param dataType Class object of the desired value type. If IQualifiedKey, this acts as a reverse lookup for the filter column, returning the key given a filterValue String.
		 * @return the correct filtered value from the data column
		 * @author kmanohar
		 */		
		public static function getValueFromFilterColumn(keyColumn:DynamicColumn, filter:IAttributeColumn, data:IAttributeColumn, filterValue:String, dataType:* = null):Object
		{
			var key:IQualifiedKey = getKey();
			var foreignKeyType:String = keyColumn.getMetadata(ColumnMetadata.DATA_TYPE);
			var ignoreKeyType:Boolean = !foreignKeyType || foreignKeyType == DataType.STRING;
			var cubekeys:Array = getAssociatedKeys(keyColumn, key, ignoreKeyType);
			
			if (cubekeys && cubekeys.length == 1)
			{
				for each (var cubekey:IQualifiedKey in cubekeys)
				{
					if (filter.getValueFromKey(cubekey, String) == filterValue)
					{
						if (dataType === IQualifiedKey)
							return cubekey;
						var val:Object = getValueFromKey(data, cubekey, dataType);
						return val;
					}
				}
			}
			return cast(undefined, dataType);
		}
		
		private static var map_reverseKeyLookupTriggerCounter:Object = new JS.WeakMap();
		private static var map_reverseKeyLookupCache:Object = new JS.WeakMap();
		
		/**
		 * This function returns a list of IQualifiedKey objects using a reverse lookup of value-key pairs 
		 * @param column An attribute column
		 * @param keyValue The value to look up
		 * @param ignoreKeyType If true, ignores the dataType of the column (the column's foreign keyType) and the keyType of the keyValue
		 * @return An array of record keys with the given value under the given column
		 */
		public static function getAssociatedKeys(column:IAttributeColumn, keyValue:IQualifiedKey, ignoreKeyType:Boolean = false):Array
		{
			var map_lookup:Object = map_reverseKeyLookupCache.get(column);
			if (map_lookup == null || column.triggerCounter != map_reverseKeyLookupTriggerCounter.get(column)) // if cache is invalid, validate it now
			{
				map_reverseKeyLookupTriggerCounter.set(column, column.triggerCounter);
				map_reverseKeyLookupCache.set(column, map_lookup = new JS.Map());
				for each (var recordKey:IQualifiedKey in column.keys)
				{
					var value:IQualifiedKey = column.getValueFromKey(recordKey, IQualifiedKey) as IQualifiedKey;
					if (value == null)
						continue;
					
					if (!map_lookup.has(value))
						map_lookup.set(value, []);
					(map_lookup.get(value) as Array).push(recordKey);
					
					if (!map_lookup.has(value.localName))
						map_lookup.set(value.localName, []);
					(map_lookup.get(value.localName) as Array).push(recordKey);
				}
			}
			return map_lookup.get(ignoreKeyType ? keyValue.localName : keyValue) as Array;
		}
		
		/**
		 * This function uses currentRecordKey when retrieving a value from a column if no key is specified.
		 * @param object An IAttributeColumn or an ILinkableVariable to get a value from.
		 * @param key A key to get the Number for.
		 * @return The value of the object, cast to a Number.
		 */
		public static function getNumber(object:/*/IAttributeColumn|ILinkableVariable/*/Object, key:IQualifiedKey = null):Number
		{
			// remember current key
			var previousKey:IQualifiedKey = currentRecordKey;
			try
			{
				if (key == null)
					key = currentRecordKey;
				
				var result:Number;
				var column:IAttributeColumn = object as IAttributeColumn;
				if (column != null)
				{
					result = (object as IAttributeColumn).getValueFromKey(key, Number);
				}
				else if (object is ILinkableVariable)
				{
					result = StandardLib.asNumber((object as ILinkableVariable).getSessionState());
				}
				else
					throw new Error('first parameter must be either an IAttributeColumn or an ILinkableVariable');
				
				if (debug)
					JS.log('getNumber',column,key.localName,String(result));
			}
			finally
			{
				// revert to key that was set when entering the function (in case nested calls modified the static variables)
				currentRecordKey = previousKey;
			}
			return result;
		}
		/**
		 * This function uses currentRecordKey when retrieving a value from a column if no key is specified.
		 * @param object An IAttributeColumn or an ILinkableVariable to get a value from.
		 * @param key A key to get the Number for.
		 * @return The value of the object, cast to a String.
		 */
		public static function getString(object:/*/IAttributeColumn|ILinkableVariable/*/Object, key:IQualifiedKey = null):String
		{
			// remember current key
			var previousKey:IQualifiedKey = currentRecordKey;
			try
			{
				if (key == null)
					key = currentRecordKey;
	
				var result:String = '';
				var column:IAttributeColumn = object as IAttributeColumn;
				if (column != null)
				{
					result = (object as IAttributeColumn).getValueFromKey(key, String);
				}
				else if (object is ILinkableVariable)
				{
					result = StandardLib.asString((object as ILinkableVariable).getSessionState());
				}
				else
					throw new Error('first parameter must be either an IAttributeColumn or an ILinkableVariable');
	
				if (debug)
					JS.log('getString',column,key.localName,String(result));
			}
			finally
			{
				// revert to key that was set when entering the function (in case nested calls modified the static variables)
				currentRecordKey = previousKey;
			}
			return result;
		}
		/**
		 * This function uses currentRecordKey when retrieving a value from a column if no key is specified.
		 * @param object An IAttributeColumn or an ILinkableVariable to get a value from.
		 * @param key A key to get the Number for.
		 * @return The value of the object, cast to a Boolean.
		 */
		public static function getBoolean(object:/*/IAttributeColumn|ILinkableVariable/*/Object, key:IQualifiedKey = null):Boolean
		{
			// remember current key
			var previousKey:IQualifiedKey = currentRecordKey;
			try
			{
				if (key == null)
					key = currentRecordKey;
	
				var result:Boolean = false;
				var column:IAttributeColumn = object as IAttributeColumn;
				if (column != null)
				{
					result = StandardLib.asBoolean(column.getValueFromKey(key, Number));
				}
				else if (object is ILinkableVariable)
				{
					result = StandardLib.asBoolean((object as ILinkableVariable).getSessionState());
				}
				else
					throw new Error('first parameter must be either an IAttributeColumn or an ILinkableVariable');
	
				if (debug)
					JS.log('getBoolean',column,key.localName,String(result));
			}
			finally
			{
				// revert to key that was set when entering the function (in case nested calls modified the static variables)
				currentRecordKey = previousKey;
			}
			return result;
		}
		/**
		 * This function uses currentRecordKey when retrieving a value from a column if no key is specified.
		 * @param column A column to get a value from.
		 * @param key A key to get the Number for.
		 * @return The Number corresponding to the given key, normalized to be between 0 and 1.
		 */
		[Deprecated(replacement="WeaveAPI.StatisticsCache.getColumnStatistics(column).getNorm(key)")]
		public static function getNorm(column:IAttributeColumn, key:IQualifiedKey = null):Number
		{
			// remember current key
			var previousKey:IQualifiedKey = currentRecordKey;
			try
			{
				if (key == null)
					key = currentRecordKey;
	
				var result:Number = NaN;
				if (column != null)
					result = WeaveAPI.StatisticsCache.getColumnStatistics(column).getNorm(key);
				else
					throw new Error('first parameter must be an IAttributeColumn');
	
				if (debug)
					JS.log('getNorm',column,key.localName,String(result));
			}
			finally
			{
				// revert to key that was set when entering the function (in case nested calls modified the static variables)
				currentRecordKey = previousKey;
			}
			return result;
		}
		
		/**
		 * This will check a list of IKeySets for an IQualifiedKey.
		 * @param keySets A list of IKeySets (can be IAttributeColumns).
		 * @param key A key to search for.
		 * @return The first IKeySet that contains the key.
		 */
		public static function findKeySet(keySets:Array/*/<IKeySet>/*/, key:IQualifiedKey = null):IKeySet
		{
			// remember current key
			var previousKey:IQualifiedKey = currentRecordKey;
			try
			{
				if (key == null)
					key = currentRecordKey;
				
				var keySet:IKeySet = null;
				for (var i:int = 0; i < keySets.length; i++)
				{
					keySet = keySets[i] as IKeySet;
					if (keySet && keySet.containsKey(key))
						break;
					else
						keySet = null;
				}
			}
			finally
			{
				// revert to key that was set when entering the function (in case nested calls modified the static variables)
				currentRecordKey = previousKey;
			}
			return keySet;
		}
		
		[Deprecated] public static function getSum(column:IAttributeColumn):Number
		{
			return WeaveAPI.StatisticsCache.getColumnStatistics(column).getSum();
		}
		
		[Deprecated] public static function getMean(column:IAttributeColumn):Number
		{
			return WeaveAPI.StatisticsCache.getColumnStatistics(column).getMean();
		}
		
		[Deprecated] public static function getVariance(column:IAttributeColumn):Number
		{
			return WeaveAPI.StatisticsCache.getColumnStatistics(column).getVariance();
		}
		
		[Deprecated] public static function getStandardDeviation(column:IAttributeColumn):Number
		{
			return WeaveAPI.StatisticsCache.getColumnStatistics(column).getStandardDeviation();
		}
		
		[Deprecated] public static function getMin(column:IAttributeColumn):Number
		{
			return WeaveAPI.StatisticsCache.getColumnStatistics(column).getMin();
		}
		
		[Deprecated] public static function getMax(column:IAttributeColumn):Number
		{
			return WeaveAPI.StatisticsCache.getColumnStatistics(column).getMax();
		}
		
		[Deprecated] public static function getCount(column:IAttributeColumn):Number
		{
			return WeaveAPI.StatisticsCache.getColumnStatistics(column).getCount();
		}
		
		[Deprecated] public static function getRunningTotal(column:IAttributeColumn, key:IQualifiedKey = null):Number
		{
			// remember current key
			var previousKey:IQualifiedKey = currentRecordKey;
			try
			{
				if (key == null)
					key = currentRecordKey;
	
				var result:Number = NaN;
				if (column != null)
				{
					var runningTotals:Object = (WeaveAPI.StatisticsCache as StatisticsCache).getRunningTotals(column);
					if (runningTotals != null)
						result = runningTotals.get(key);
				}
			}
			finally
			{
				// revert to key that was set when entering the function (in case nested calls modified the static variables)
				currentRecordKey = previousKey;
			}
			return result;
		}
		/**
		 * @param value A value to cast.
		 * @param newType Either a qualifiedClassName or a Class object referring to the type to cast the value as.
		 */
		public static function cast/*/<T>/*/(value:*, newType:/*/T|string/*/*):/*/T/*/*
		{
			if (newType == null)
				return value;
			
			// if newType is a qualified class name, get the Class definition
			if (newType is String)
				newType = Weave.getDefinition(newType);

			// cast the value as the desired type
			if (newType == Number)
			{
				value = StandardLib.asNumber(value);
			}
			else if (newType == String)
			{
				value = StandardLib.asString(value);
			}
			else if (newType == Boolean)
			{
				value = StandardLib.asBoolean(value);
			}
			else if (newType == Array)
			{
				if (value != null && !(value is Array))
					value = [value];
			}

			return value as newType;
		}
		
		/**
		 * This is a macro for IQualifiedKey that can be used in equations.
		 */		
		public static const QKey:/*/typeof IQualifiedKey/*/Class = IQualifiedKey;
	}
}
