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
	import weave.api.registerLinkableChild;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IBinClassifier;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.data.IQualifiedKey;
	import weave.data.BinningDefinitions.CategoryBinningDefinition;
	import weave.data.BinningDefinitions.DynamicBinningDefinition;
	import weave.data.BinningDefinitions.SimpleBinningDefinition;
	
	/**
	 * A binned column maps a record key to a bin key.
	 * 
	 * @author adufilie
	 */
	public class BinnedColumn extends ExtendedDynamicColumn implements IPrimitiveColumn
	{
		public function BinnedColumn()
		{
			binningDefinition.requestLocalObject(SimpleBinningDefinition, false);
			binningDefinition.generateBinClassifiersForColumn(internalDynamicColumn);
			registerLinkableChild(this, binningDefinition.asyncResultCallbacks);
		}
		
		/**
		 * This number overrides the min,max metadata values.
		 * @param propertyName The name of a metadata property.
		 * @return The value of the specified metadata property.
		 */
		override public function getMetadata(propertyName:String):String
		{
			switch (propertyName)
			{
				case ColumnMetadata.MIN:
					return numberOfBins > 0 ? "0" : null;
				case ColumnMetadata.MAX:
					var binCount:int = numberOfBins;
					return binCount > 0 ? String(binCount - 1) : null;
			}
			return super.getMetadata(propertyName);
		}
		
		/**
		 * This defines how to generate the bins for this BinnedColumn.
		 * This is used to generate the derivedBins.
		 */
		public const binningDefinition:DynamicBinningDefinition = registerLinkableChild(this, new DynamicBinningDefinition(true));
		
		private var _binNames:Array = []; // maps a bin index to a bin name
		private var _binClassifiers:Array = []; // maps a bin index to an IBinClassifier
		private var _keyToBinIndexMap:Dictionary = new Dictionary(); // maps a record key to a bin index
		private var _binnedKeysArray:Array = []; // maps a bin index to a list of keys in that bin
		private var _binnedKeysMap:Object = {}; // maps a bin name to a list of keys in that bin
		private var _largestBinSize:uint = 0;
		private var _resultTriggerCount:uint = 0;
		
		/**
		 * This function generates bins using the binning definition and the internal column,
		 * and also saves lookups for mapping between bins and keys.
		 */
		private function validateBins():void
		{
			if (WeaveAPI.SessionManager.linkableObjectIsBusy(this))
				return;
			
			if (_resultTriggerCount != binningDefinition.asyncResultCallbacks.triggerCounter)
			{
				_resultTriggerCount = binningDefinition.asyncResultCallbacks.triggerCounter;
				// reset cached values
				_column = internalDynamicColumn.getInternalColumn();
				_keyToBinIndexMap = new Dictionary();
				_binnedKeysArray = [];
				_binnedKeysMap = {};
				_largestBinSize = 0;
				// save bin names for faster lookup
				_binNames = binningDefinition.getBinNames();
				_binClassifiers = binningDefinition.getBinClassifiers();
				// create empty key arrays
				if (_binNames)
					for (var i:int = 0; i < _binNames.length; i++)
						_binnedKeysMap[_binNames[i]] = _binnedKeysArray[i] = []; // same Array pointer
				_keys = internalDynamicColumn.keys;
				_i = 0;
				// hack: assuming bin classifiers are NumberClassifiers except for CategoryBinningDefinition
				_dataType = binningDefinition.internalObject is CategoryBinningDefinition ? String : Number;
				// fill all mappings
				if (_column && _binClassifiers)
					WeaveAPI.StageUtils.startTask(this, _asyncIterate, WeaveAPI.TASK_PRIORITY_BUILDING, triggerCallbacks);
			}
		}
		
		private var _dataType:Class;
		private var _column:IAttributeColumn;
		private var _i:int;
		private var _keys:Array;
		private function _asyncIterate():Number
		{
			// stop immediately if there are no more keys or result callbacks were triggered
			if (_i >= _keys.length || _resultTriggerCount != binningDefinition.asyncResultCallbacks.triggerCounter)
				return 1;

			var key:IQualifiedKey = _keys[_i];
			var value:* = _column.getValueFromKey(key, _dataType);
			var binIndex:int = 0;
			for (; binIndex < _binClassifiers.length; binIndex++)
			{
				if ((_binClassifiers[binIndex] as IBinClassifier).contains(value))
				{
					_keyToBinIndexMap[key] = binIndex;
					var array:Array = _binnedKeysArray[binIndex] as Array;
					if (array.push(key) > _largestBinSize)
						_largestBinSize = array.length;
					break;
				}
			}
			
			_i++;
			
			return _i / _keys.length;
		}

		/**
		 * This is the number of bins that have been generated by
		 * the binning definition using with the internal column.
		 */
		public function get numberOfBins():uint
		{
			validateBins();
			return _binNames.length;
		}
		
		/**
		 * This is the largest number of records in any of the bins.
		 */		
		public function get largestBinSize():uint
		{
			validateBins();
			return _largestBinSize;
		}
		
		/**
		 * This function gets a list of keys in a bin.
		 * @param binIndex The index of the bin to get the keys from.
		 * @return An Array of keys in the specified bin.
		 */
		public function getKeysFromBinIndex(binIndex:uint):Array
		{
			validateBins();
			if (binIndex < _binnedKeysArray.length)
				return _binnedKeysArray[binIndex];
			return null;
		}
		
		/**
		 * This function gets a list of keys in a bin.
		 * @param binIndex The name of the bin to get the keys from.
		 * @return An Array of keys in the specified bin.
		 */
		public function getKeysFromBinName(binName:String):Array
		{
			validateBins();
			return _binnedKeysMap[binName] as Array;
		}
		
		public function getBinIndexFromDataValue(value:*):Number
		{
			validateBins();
			if (_binClassifiers)
				for (var i:int = 0; i < _binClassifiers.length; i++)
					if ((_binClassifiers[i] as IBinClassifier).contains(value))
						return i;
			return NaN;
		}

		/**
		 * This function returns different results depending on the dataType.
		 * Supported types:
		 *     default -> IBinClassifier that matches the given record key
		 *     Number -> bin index for the given record key
		 *     String -> bin name for the given record key
		 *     Array -> list of keys in the same bin as the given record key
		 * @param key A record identifier.
		 * @param dataType The requested return type.
		 * @return If the specified dataType is supported, a value of that type.  Otherwise, the default return value for the given record key.
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			validateBins();
			
			var binIndex:Number = Number(_keyToBinIndexMap[key]); // undefined -> NaN
			
			// Number: return bin index
			if (dataType == Number)
				return binIndex;
			
			// String: return bin name
			if (dataType == String)
				return isNaN(binIndex) ? '' : _binNames[binIndex];
			
			if (isNaN(binIndex))
				return undefined;
			
			// Array: return list of keys in the same bin
			if (dataType == Array)
				return _binnedKeysArray[binIndex] as Array;
			
			// default: return IBinClassifier
			return _binClassifiers && _binClassifiers[binIndex];
		}
		
		
		/**
		 * From a bin index, this function returns the name of the bin.
		 * @param value A bin index
		 * @return The name of the bin
		 */
		public function deriveStringFromNumber(value:Number):String
		{
			validateBins();
			
			try
			{
				return _binNames[value];
			}
			catch (e:Error) { } // ok to ignore Array[index] error
			
			return '';
		}
	}
}
