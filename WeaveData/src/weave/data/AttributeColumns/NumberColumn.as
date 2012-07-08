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
	import mx.utils.StringUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.reportError;
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
			return _keyToNumericDataMapping[key] !== undefined;
		}
		
		public function setRecords(keys:Vector.<IQualifiedKey>, numericData:Vector.<Number>):void
		{
			if (keys.length != numericData.length)
			{
				reportError("Array lengths differ");
				return;
			}
			
			// clear previous data mapping
			_keyToNumericDataMapping = new Dictionary();
			_keyToStringDataMapping = new Dictionary();
			_uniqueKeys.length = 0;

			numberToStringFunction = StandardLib.formatNumber;
			// compile the string format function from the metadata
			var stringFormat:String = getMetadata(AttributeColumnMetadata.STRING);
			if (stringFormat)
			{
				try
				{
					numberToStringFunction = compiler.compileToFunction(stringFormat, null, true, false, [AttributeColumnMetadata.NUMBER]);
				}
				catch (e:Error)
				{
					reportError(e);
				}
			}
			
			_i = 0;
			_keys = keys;
			_numericData = numericData;
			
			WeaveAPI.StageUtils.startTask(this, _iterate, WeaveAPI.TASK_PRIORITY_PARSING, _asyncComplete);
		}
		
		private var _i:int;
		private var _keys:Vector.<IQualifiedKey>;
		private var _numericData:Vector.<Number>;
		
		private function _iterate():Number
		{
			if (_i >= _keys.length)
				return 1;
			
			// save a mapping from keys to data
			var key:IQualifiedKey = _keys[_i] as IQualifiedKey;
			var number:Number = _numericData[_i] as Number; // fast and safe because numericData is Vector.<Number>
			if (!isNaN(number))
			{
				if (_keyToNumericDataMapping[key] === undefined)
				{
					_uniqueKeys.push(key);
					_keyToNumericDataMapping[key] = number;
					_keyToStringDataMapping[key] = StandardLib.asString(numberToStringFunction(number));
				}
				else
				{
					var fmt:String = 'Record dropped due to duplicate key ({0}).  Attribute column: {1}';
					var str:String = StringUtil.substitute(fmt, key.localName, _metadata.toXMLString());
					reportError(str);
				}
			}
			
			// prepare for next iteration
			_i++;
			
			return _i / _keys.length;
		}

		private function _asyncComplete():void
		{
			_keys = null;
			_numericData = null;
			
			triggerCallbacks();
		}
		
		private static const compiler:Compiler = new Compiler();
		private var numberToStringFunction:Function = StandardLib.formatNumber;
		
		/**
		 * Get a string value for a given number.
		 */
		public function deriveStringFromNumber(number:Number):String
		{
			return numberToStringFunction(number);
		}

		/**
		 * get data from key value
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (dataType == String)
				return _keyToStringDataMapping[key] || '';
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
