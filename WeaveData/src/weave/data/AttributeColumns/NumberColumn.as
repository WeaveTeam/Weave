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
	
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.data.IQualifiedKey;
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

		public function setRecords(keys:Vector.<IQualifiedKey>, numericData:Vector.<Number>):void
		{
			var index:int;
			var key:Object;

			if (keys.length > numericData.length)
			{
				trace("WARNING: keys vector length > data vector length. keys truncated.",keys,numericData);
				keys.length = numericData.length;
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
					_keyToNumericDataMapping[key] = n;
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
