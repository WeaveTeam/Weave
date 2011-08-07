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
	import weave.api.core.ILinkableDynamicObject;
	import weave.api.core.ILinkableObject;
	import weave.api.core.ILinkableVariable;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IQualifiedKey;
	import weave.compiler.BooleanLib;
	import weave.compiler.MathLib;
	import weave.compiler.StringLib;
	import weave.core.ClassUtils;
	import weave.data.StatisticsCache;
	import weave.primitives.ColorRamp;
	
	/**
	 * EquationColumnLib
	 * This class contains static functions that access values from IAttributeColumn objects.
	 * Many of the functions in this library use the static variable 'currentRecordKey'.
	 * This value should be set before calling a function that uses it.
	 * 
	 * @author adufilie
	 */
	public class EquationColumnLib
	{
		/**
		 * This value should be set before calling any of the functions below that get values from IAttributeColumns.
		 */
		public static var currentRecordKey:IQualifiedKey = null;
		
		/**
		 * @return columnReference.getAttributeColumn()
		 */
		public static function getReferencedColumn(columnReference:IColumnReference):IAttributeColumn
		{
			return WeaveAPI.AttributeColumnCache.getColumn(columnReference);
		}
		
		/**
		 * This function uses currentRecordKey when retrieving a value from a column.
		 * @param object An IAttributeColumn or an ILinkableVariable to get a value from.
		 * @param dataType Either a Class object or a String containing the qualified class name of the desired value type.
		 * @return The value of the object, optionally cast to the requested dataType.
		 */
		public static function getValue(object:Object, dataType:* = null):*
		{
			// remember current key
			var key:IQualifiedKey = currentRecordKey;

			if (dataType is String)
				dataType = ClassUtils.getClassDefinition(dataType);
			
			var value:* = null; // the value that will be returned
			
			// get the value from the object
			var column:IAttributeColumn = object as IAttributeColumn;
			if (column != null)
			{
				value = column.getValueFromKey(key, dataType as Class);
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
			
			// revert to key that was set when entering the function (in case nested calls modified the static variables)
			currentRecordKey = key;
			return value;
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
			
			currentRecordKey = key;
			var value:* = getValue(column, dataType);
			
			// revert to key that was set when entering the function
			currentRecordKey = previousKey;

			return value;
		}
		
		/**
		 * This function uses currentRecordKey when retrieving a value from a column if no key is specified.
		 * @param object An IAttributeColumn or an ILinkableVariable to get a value from.
		 * @param key A key to get the Number for.
		 * @return The value of the object, cast to a Number.
		 */
		public static function getNumber(object:Object, key:IQualifiedKey = null):Number
		{
			// remember current key
			var previousKey:IQualifiedKey = currentRecordKey;
			
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
				result = MathLib.toNumber((object as ILinkableVariable).getSessionState());
			}
			else
				result = NaN;
			
			// revert to key that was set when entering the function (in case nested calls modified the static variables)
			currentRecordKey = previousKey;
			return result;
		}
		/**
		 * This function uses currentRecordKey when retrieving a value from a column if no key is specified.
		 * @param object An IAttributeColumn or an ILinkableVariable to get a value from.
		 * @param key A key to get the Number for.
		 * @return The value of the object, cast to a String.
		 */
		public static function getString(object:Object, key:IQualifiedKey = null):String
		{
			// remember current key
			var previousKey:IQualifiedKey = currentRecordKey;
			
			if (key == null)
				key = currentRecordKey;

			var result:String;
			var column:IAttributeColumn = object as IAttributeColumn;
			if (column != null)
			{
				result = (object as IAttributeColumn).getValueFromKey(key, String);
			}
			else if (object is ILinkableVariable)
			{
				result = StringLib.toString((object as ILinkableVariable).getSessionState());
			}
			else
				result = '';

			// revert to key that was set when entering the function (in case nested calls modified the static variables)
			currentRecordKey = previousKey;
			return result;
		}
		/**
		 * This function uses currentRecordKey when retrieving a value from a column if no key is specified.
		 * @param object An IAttributeColumn or an ILinkableVariable to get a value from.
		 * @param key A key to get the Number for.
		 * @return The value of the object, cast to a Boolean.
		 */
		public static function getBoolean(object:Object, key:IQualifiedKey = null):Boolean
		{
			// remember current key
			var previousKey:IQualifiedKey = currentRecordKey;
			
			if (key == null)
				key = currentRecordKey;

			var result:Boolean = false;
			var column:IAttributeColumn = object as IAttributeColumn;
			if (column != null)
			{
				result = column.getValueFromKey(key, Boolean);
			}
			else if (object is ILinkableVariable)
			{
				result = BooleanLib.toBoolean((object as ILinkableVariable).getSessionState());
			}

			// revert to key that was set when entering the function (in case nested calls modified the static variables)
			currentRecordKey = previousKey;
			return result;
		}
		/**
		 * This function uses currentRecordKey when retrieving a value from a column if no key is specified.
		 * @param column A column to get a value from.
		 * @param key A key to get the Number for.
		 * @return The Number corresponding to the given key, normalized to be between 0 and 1.
		 */
		public static function getNorm(column:IAttributeColumn, key:IQualifiedKey = null):Number
		{
			// remember current key
			var previousKey:IQualifiedKey = currentRecordKey;
			
			if (key == null)
				key = currentRecordKey;

			var result:Number = NaN;
			if (column != null)
			{
				var min:Number = WeaveAPI.StatisticsCache.getMin(column);
				var max:Number = WeaveAPI.StatisticsCache.getMax(column);
				var value:Number = column.getValueFromKey(key, Number);
				result = (value - min) / (max - min);
			}

			// revert to key that was set when entering the function (in case nested calls modified the static variables)
			currentRecordKey = previousKey;
			return result;
		}
		
		public static function getRunningTotal(column:IAttributeColumn, key:IQualifiedKey = null):Number
		{
			// remember current key
			var previousKey:IQualifiedKey = currentRecordKey;
			
			if (key == null)
				key = currentRecordKey;

			var result:Number = NaN;
			if (column != null)
			{
				var runningTotals:Dictionary = StatisticsCache.instance.getRunningTotals(column);
				result = runningTotals[key];
			}

			// revert to key that was set when entering the function (in case nested calls modified the static variables)
			currentRecordKey = previousKey;
			return result;
		}
		/**
		 * @param ramp A ColorRamp to apply to a normalized value.
		 * @param normValueOrColumn Either an IAttributeColumn to get a normalized value from, or a normalized value between 0 and 1.
		 * @return The result of ramp.getColorFromNorm() called on the normalized value.
		 */
		public static function applyColorRamp(ramp:ColorRamp, normValueOrColumn:*):Number
		{
			// remember current key
			var previousKey:IQualifiedKey = currentRecordKey;

			var result:Number;
			var column:IAttributeColumn = (normValueOrColumn as IAttributeColumn);
			if (column != null)
			{
				var min:Number = WeaveAPI.StatisticsCache.getMin(column);
				var max:Number = WeaveAPI.StatisticsCache.getMax(column);
				var value:Number = column.getValueFromKey(previousKey, Number);
				result = ramp.getColorFromNorm((value - min) / (max - min));
			}
			else
				result = ramp.getColorFromNorm(Number(normValueOrColumn));

			// revert to key that was set when entering the function (in case nested calls modified the static variables)
			currentRecordKey = previousKey;
			return result;
		}
		/**
		 * @param value A value to cast.
		 * @param newType Either a qualifiedClassName or a Class object referring to the type to cast the value as.
		 */
		public static function cast(value:*, newType:*):*
		{
			if (newType == null)
				return value;
			
			// if newType is a qualified class name, get the Class definition
			if (newType is String)
				newType = ClassUtils.getClassDefinition(newType);

			// cast the value as the desired type
			if (newType == Number)
			{
				value = MathLib.toNumber(value);
			}
			else if (newType == String)
			{
				value = StringLib.toString(value);
			}
			else if (newType == Boolean)
			{
				value = BooleanLib.toBoolean(value);
			}
			else if (newType == int)
			{
				value = MathLib.toNumber(value);
				if (isNaN(value))
					return NaN;
				return int(value);
			}

			return value as newType;
		}
		
		/**
		 * @param dynamicObject An object implementing ILinkableDynamicObject.
		 * @return The result of calling dynamicObject.internalObject.
		 */
		public static function getInternalObject(dynamicObject:ILinkableDynamicObject):ILinkableObject
		{
			if (dynamicObject != null)
				return dynamicObject.internalObject;
			return null;
		}
		
		/**
		 * This function returns the result of accessing object[propertyName].
		 * @param object An object to access a property of.
		 * @param propertyName The name of the property to access.
		 * @return The value of the property.
		 */
		public static function getProperty(object:Object, propertyName:String):*
		{
			return object is Object ? object[propertyName] : undefined;
		}
		/**
		 * This applies a method of an object and returns its result.
		 * @param object An object that contains a public method.
		 * @param methodName The name of the public method.
		 * @param params A list of parameters to pass to the method.
		 * @return The result of applying the function.
		 */
		public static function applyMethod(object:Object, methodName:String, ...params):*
		{
			if (object == null)
				return undefined;
			return (object[methodName] as Function).apply(null, params);
		}
		
		/**
		 * This is a macro for IQualifiedKey that can be used in equations.
		 */		
		public static const QKey:Class = IQualifiedKey;
	}
}
