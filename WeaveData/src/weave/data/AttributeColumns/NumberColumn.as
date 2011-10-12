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
	
	import weave.api.WeaveAPI;
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.data.IQualifiedKey;
	import weave.compiler.Compiler;
	import weave.compiler.StandardLib;
	import weave.utils.EquationColumnLib;
	
	/**
	 * NumericColumn
	 * 
	 * @author adufilie
	 */
	public class NumberColumn extends AbstractAttributeColumn implements IPrimitiveColumn
	{
		public function NumberColumn(metadata:XML = null)
		{
			super(metadata);
		}
		
		override public function getMetadata(propertyName:String):String
		{
			if (propertyName == AttributeColumnMetadata.DATA_TYPE)
				return DataTypes.NUMBER;
			return super.getMetadata(propertyName);
		}
		
		/**
		 * _keyToNumericDataMapping
		 * This object maps keys to data values.
		 */
		protected var _keyToNumericDataMapping:Dictionary = new Dictionary();

		/**
		 * This object maps keys to the string values of numeric data after 
		 * applying the compiler expressions in NUMBER and STRING metadata fields.
		 */
		protected var _keyToStringDataMapping:Dictionary = new Dictionary();
		
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
		
		private static const compiler:Compiler = new Compiler();
		public function setRecords(keys:Vector.<IQualifiedKey>, numericData:Vector.<Number>):void
		{
			var index:int;
			var key:Object;

			if (keys.length > numericData.length)
			{
				WeaveAPI.ErrorManager.reportError(new Error("Array lengths differ"));
				return;
			}
			
			// clear previous data mapping
			_keyToNumericDataMapping = new Dictionary();
			
			// save a mapping from keys to data
			for (index = keys.length - 1; index >= 0; index--)
			{
				key = keys[index] as IQualifiedKey;
				var n:Number = Number(numericData[index]);
				
				if (isFinite(n))
				{
					var compiledMethod:Function;
					var numberFormatter:String = getMetadata(AttributeColumnMetadata.NUMBER);
					
					if (numberFormatter)
					{
						compiledMethod = compiler.compileToFunction(numberFormatter, {"number" : n}, true, false);
						_keyToNumericDataMapping[key] = compiledMethod.apply();
					}
					else
						_keyToNumericDataMapping[key] = n;
					
					var stringFormatter:String = getMetadata(AttributeColumnMetadata.STRING);
					if (stringFormatter)
					{
						compiledMethod = compiler.compileToFunction(numberFormatter, {"number" : n}, true, false);
						_keyToStringDataMapping[key] = compiledMethod.apply();
					}
				}
			}

			// save list of unique keys
			index = 0;
			for (key in _keyToNumericDataMapping)
				_uniqueKeys[index++] = key;
			_uniqueKeys.length = index; // trim to new size
			
			triggerCallbacks();
		}

		/**
		 * maxDerivedSignificantDigits:
		 * maximum number of significant digits to return when calling deriveStringFromNorm()
		 */		
		public var maxDerivedSignificantDigits:uint = 10;
		
		/**
		 * Get a string value for a given number.
		 */
		public function deriveStringFromNumber(number:Number):String
		{
			var string:String = _keyToStringDataMapping[number] as String;
			if (string)
			{
				var stringFormat:String = getMetadata(AttributeColumnMetadata.STRING);
				if (stringFormat)
				{
					var compiledMethod:Function = compiler.compileToFunction(stringFormat, {"number" : number}, true);
					return compiledMethod.apply();
				}
				else
					return string;						
			}
				

			string = StandardLib.formatNumber(number);
			if (isFinite(number))
				_keyToStringDataMapping[number] = string;
			return string;
		}

		/**
		 * get data from key value
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (dataType == String)
				return deriveStringFromNumber(_keyToNumericDataMapping[key]);
			// make sure to cast as a Number so missing values return as NaN instead of undefined
			var value:Number = Number(_keyToNumericDataMapping[key]);
			if (dataType == null)
				return value;
			return EquationColumnLib.cast(value, dataType);
		}

		override public function toString():String
		{
			return getQualifiedClassName(this).split("::")[1] + '{recordCount: '+keys.length+', keyType: "'+getMetadata('keyType')+'", title: "'+getMetadata('title')+'"}';
		}
	}
}
