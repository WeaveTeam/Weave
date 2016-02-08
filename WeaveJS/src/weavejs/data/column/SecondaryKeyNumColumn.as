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
	import weavejs.api.data.IPrimitiveColumn;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.core.LinkableBoolean;
	import weavejs.core.LinkableString;
	import weavejs.data.EquationColumnLib;
	import weavejs.util.AsyncSort;
	import weavejs.util.Dictionary2D;
	import weavejs.util.JS;
	import weavejs.util.StandardLib;
	
	public class SecondaryKeyNumColumn extends AbstractAttributeColumn implements IPrimitiveColumn
	{
		public function SecondaryKeyNumColumn(metadata:Object = null)
		{
			super(metadata);
			secondaryKeyFilter.addImmediateCallback(this, triggerCallbacks);
			useGlobalMinMaxValues.addImmediateCallback(this, triggerCallbacks);
		}

		/**
		 * This overrides the base title value
		 */
		public var baseTitle:String;

		/**
		 * This function overrides the min,max values.
		 */
		override public function getMetadata(propertyName:String):String
		{
			if (useGlobalMinMaxValues.value)
			{
				if (propertyName == ColumnMetadata.MIN)
					return String(_minNumber);
				if (propertyName == ColumnMetadata.MAX)
					return String(_maxNumber);
			}
			
			var value:String = super.getMetadata(propertyName);
			
			switch (propertyName)
			{
				case ColumnMetadata.TITLE:
					value = baseTitle || value;
					if (value != null && secondaryKeyFilter.value && !allKeysHack)
						return value + ' (' + secondaryKeyFilter.value + ')';
					break;
				case ColumnMetadata.KEY_TYPE:
					if (secondaryKeyFilter.value == null)
						return value + TYPE_SUFFIX
					break;
				case ColumnMetadata.DATA_TYPE:
					return value || (_dataType == Number ? DataType.NUMBER : DataType.STRING);
			}
			
			return value;
		}
		
		private var TYPE_SUFFIX:String = ',Year';
		
		private var _minNumber:Number = NaN; // returned by getMetadata
		private var _maxNumber:Number = NaN; // returned by getMetadata
		
		/**
		 * This object maps keys to data values.
		 */
		protected var d2d_qkeyA_keyB_number:Dictionary2D = new Dictionary2D();
		protected var map_qkeyAB_number:Object = new JS.Map();

		/**
		 * Derived from the record data, this is a list of all existing values in the dimension, each appearing once, sorted alphabetically.
		 */
		private var _uniqueStrings:Array = [];

		/**
		 * This is the value used to filter the data.
		 */
		public static function get secondaryKeyFilter():LinkableString
		{
			if (!_secondaryKeyFilter)
				_secondaryKeyFilter = new LinkableString();
			return _secondaryKeyFilter;
		}
		public static function get useGlobalMinMaxValues():LinkableBoolean
		{
			if (!_useGlobalMinMaxValues)
				_useGlobalMinMaxValues = new LinkableBoolean(true);
			return _useGlobalMinMaxValues;
		}
		
		private static var _secondaryKeyFilter:LinkableString;
		private static var _useGlobalMinMaxValues:LinkableBoolean;
		
		protected var _uniqueSecondaryKeys:Array = new Array();
		public function get secondaryKeys():Array
		{
			return _uniqueSecondaryKeys;
		}

		/**
		 * This is a list of unique keys this column defines values for.
		 */
		protected var _uniqueKeysA:Array = [];
		protected var _uniqueKeysAB:Array = [];
		override public function get keys():Array
		{
			if (secondaryKeyFilter.value == null || allKeysHack) // when no secondary key specified, use the real unique keys
				return _uniqueKeysAB;
			return _uniqueKeysA;
		}
		
		public static var allKeysHack:Boolean = false; // used by DataTableTool
		
		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		override public function containsKey(key:IQualifiedKey):Boolean
		{
			var skfv:String = secondaryKeyFilter.value;
			if (skfv == null || allKeysHack)
				return map_qkeyAB_number[key] !== undefined;
			
			return d2d_qkeyA_keyB_number.get(key, skfv) !== undefined;
		}

		/**
		 * @param qkeysA Array of IQualifiedKey
		 * @param keysB Array of String
		 * @param data
		 */
		public function updateRecords(qkeysA:Array, keysB:Array, data:Array):void
		{
			if (_uniqueStrings.length > 0)
			{
				JS.error("Replacing existing records is not supported");
			}
			
			var index:int, qkeyA:IQualifiedKey, keyB:String, qkeyAB:IQualifiedKey;
			var _key:*;
			var dataObject:* = null;

			if (qkeysA.length != data.length || keysB.length != data.length)
			{
				JS.error("Array lengths differ");
				return;
			}
			
			// clear previous data mapping
			d2d_qkeyA_keyB_number = new Dictionary2D();
			
			//if it's string data - create list of unique strings
			var dataType:String = super.getMetadata(ColumnMetadata.DATA_TYPE);
			if (data[0] is String || (dataType && dataType != DataType.NUMBER))
			{
				if (!dataType)
					dataType = DataType.STRING;
				for (var i:int = 0; i < data.length; i++)
				{
					if (_uniqueStrings.indexOf(data[i]) < 0)
						_uniqueStrings.push(data[i]);
				}
				AsyncSort.sortImmediately(_uniqueStrings);
				
				// min,max numbers are the min,max indices in the unique strings array
				_minNumber = 0;
				_maxNumber = _uniqueStrings.length - 1; 
			}
			else
			{
				dataType = DataType.NUMBER;
				// reset min,max before looping over records
				_minNumber = NaN;
				_maxNumber = NaN;
			}
			_metadata[ColumnMetadata.DATA_TYPE] = dataType;
			_dataType = dataType == DataType.NUMBER ? Number : String;
			
			// save a mapping from keys to data
			for (index = 0; index < qkeysA.length; index++)
			{
				qkeyA = qkeysA[index] as IQualifiedKey;
				keyB = String(keysB[index]);
				dataObject = data[index];
				
				qkeyAB = WeaveAPI.QKeyManager.getQKey(qkeyA.keyType + TYPE_SUFFIX, qkeyA.localName + ',' + keyB);
				//if we don't already have keyB - add it to _uniqueKeysB
				//  @todo - optimize this - searching every time is not the optimal method
				if (_uniqueSecondaryKeys.indexOf(keyB) < 0)
					_uniqueSecondaryKeys.push(keyB);
				if (dataObject is String)
				{
					var iString:int = _uniqueStrings.indexOf(dataObject);
					if (iString < 0)
					{
						//iString = _uniqueStrings.push(dataObject) - 1;
						iString = _uniqueStrings.length;
						_uniqueStrings[iString] = dataObject;
					}
					d2d_qkeyA_keyB_number.set(qkeyA, keyB, iString);
					map_qkeyAB_number.set(qkeyAB, iString);
				}
				else
				{
					d2d_qkeyA_keyB_number.set(qkeyA, keyB, dataObject);//Number(dataObject));
					map_qkeyAB_number.set(qkeyAB, dataObject);//Number(dataObject));
					
					_minNumber = isNaN(_minNumber) ? dataObject : Math.min(_minNumber, dataObject);
					_maxNumber = isNaN(_maxNumber) ? dataObject : Math.max(_maxNumber, dataObject);
				}
			}
			
			AsyncSort.sortImmediately(_uniqueSecondaryKeys);
			
			// save lists of unique keys
			_uniqueKeysA = d2d_qkeyA_keyB_number.primaryKeys();
			_uniqueKeysAB = JS.mapKeys(map_qkeyAB_number);
			
			triggerCallbacks();
		}

		/**
		 * maximum number of significant digits to return when calling deriveStringFromNorm()
		 */		
		private var maxDerivedSignificantDigits:uint = 10;
		
		// get a string value for a given numeric value
		public function deriveStringFromNumber(number:Number):String
		{
			if (int(number) == number && (_uniqueStrings.length > 0) && (number < _uniqueStrings.length))
				return _uniqueStrings[number];
			
			return StandardLib.formatNumber(
				StandardLib.roundSignificant(
						number,
						maxDerivedSignificantDigits
					)
				);
		}
		
		private var map_qkeyAB_qkeyData:Object = new JS.WeakMap();
		private var _dataType:Class;

		/**
		 * get data from key value
		 */
		override public function getValueFromKey(qkey:IQualifiedKey, dataType:Class = null):*
		{
			if (!dataType)
				dataType = _dataType;
			
			var value:Number = NaN;
			if (map_qkeyAB_number.has(qkey))
				value = map_qkeyAB_number.get(qkey);
			else
				value = d2d_qkeyA_keyB_number.get(qkey, secondaryKeyFilter.value);
			
			if (isNaN(value))
				return EquationColumnLib.cast(undefined, dataType);
			
			if (dataType == IQualifiedKey)
			{
				if (!map_qkeyAB_qkeyData.has(qkey))
				{
					var type:String = getMetadata(ColumnMetadata.DATA_TYPE);
					if (type == DataType.NUMBER)
						return null;
					if (type == '')
						type = DataType.STRING;
					map_qkeyAB_qkeyData.set(qkey, WeaveAPI.QKeyManager.getQKey(type, deriveStringFromNumber(value)));
				}
				return map_qkeyAB_qkeyData.get(qkey);
			}
			
			if (dataType == String)
				return deriveStringFromNumber(value);
			
			return value;
		}
	}
}
