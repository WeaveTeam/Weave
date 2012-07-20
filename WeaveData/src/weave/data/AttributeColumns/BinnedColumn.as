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
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IBinningDefinition;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.data.BinClassifiers.BinClassifierCollection;
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

			addImmediateCallback(this, handleChange);
//			var stats:IColumnStatistics = WeaveAPI.StatisticsCache.getColumnStatistics(internalDynamicColumn);
//			getCallbackCollection(stats).addImmediateCallback(this, handleChange);
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
				case AttributeColumnMetadata.MIN:
					return numberOfBins > 0 ? "0" : null;
				case AttributeColumnMetadata.MAX:
					var binCount:int = numberOfBins;
					return binCount > 0 ? String(binCount - 1) : null;
			}
			return super.getMetadata(propertyName);
		}
		
		/**
		 * This defines how to generate the bins for this BinnedColumn.
		 * This is used to generate the derivedBins.
		 */
		public const binningDefinition:DynamicBinningDefinition = newLinkableChild(this, DynamicBinningDefinition);

		/**
		 * This contains the bins generated from the binningDefinition.
		 * Derived values don't need to appear in the session state.
		 * These bins are provided for convenience only and should not be modified.
		 */
		public function getDerivedBins():BinClassifierCollection
		{
			if (_dirty)
				validateBins();
			return _derivedBins;
		}
		
		private const _derivedBins:BinClassifierCollection = newLinkableChild(this, BinClassifierCollection); // returned by public getter
		private var _binNames:Array = null; // maps a bin index to a bin name
		private var _keyToBinIndexMap:Dictionary = null; // maps a record key to a bin index
		private var _binnedKeysArray:Array = null; // maps a bin index to a list of keys in that bin
		private var _binnedKeysMap:Object = null; // maps a bin name to a list of keys in that bin
		private var _largestBinSize:uint = 0;
		
		/**
		 * This flag is true when the derivedBins are invalid.
		 */		
		private var _dirty:Boolean = true;
		private var _validateBinsCompleted:Boolean = false;
		
		/**
		 * This function updates the _dirty flag
		 */		
		private function handleChange():void
		{
			if (_validateBinsCompleted)
			{
				_validateBinsCompleted = false;
				_dirty = false;
			}
			else
			{
				_dirty = true;
			}
		}
		
		/**
		 * This function generates bins using the binning definition and the internal column,
		 * and also saves lookups for mapping between bins and keys.
		 */
		private function validateBins():void
		{
			_dirty = false;
			_derivedBins.delayCallbacks(); // make sure callbacks don't run until we're done
			
			_column = internalDynamicColumn.getInternalColumn();
			_def = (binningDefinition.internalObject as IBinningDefinition);
			// reset cached values
			_keyToBinIndexMap = new Dictionary();
			_binnedKeysArray = [];
			_binnedKeysMap = {};
			_largestBinSize = 0;
			_derivedBins.removeAllObjects();
			if (_def != null && _column != null)
				_def.getBinClassifiersForColumn(_column, _derivedBins);
			// save bin names for faster lookup
			_binNames = _derivedBins.getNames();
			var bins:Array = _derivedBins.getObjects();
			var i:int;
			// create empty key arrays
			for (i = 0; i < _binNames.length; i++)
				_binnedKeysMap[_binNames[i]] = _binnedKeysArray[i] = []; // same Array pointer
			// fill all mappings
			_keys = internalDynamicColumn.keys;
			_i = 0;
			WeaveAPI.StageUtils.startTask(this, _asyncIterate, WeaveAPI.TASK_PRIORITY_BUILDING, _asyncComplete);
		}
		
		private var _column:IAttributeColumn;
		private var _def:IBinningDefinition;
		private var _i:int;
		private var _keys:Array;
		private function _asyncIterate():Number
		{
			var progress:Number = 1;
			if (_i < _keys.length)
			{
				var key:IQualifiedKey = _keys[_i];
				// hack: assuming bin classifiers are NumberClassifiers except for CategoryBinningDefinition
				var dataType:Class = _def is CategoryBinningDefinition ? String : Number;
				var value:* = _column.getValueFromKey(key, dataType);
				var binIndex:Number = _derivedBins.getBinIndexFromDataValue(value);
				if (!isNaN(binIndex))
				{
					_keyToBinIndexMap[key] = binIndex;
					var array:Array = _binnedKeysArray[binIndex] as Array;
					if (array.push(key) > _largestBinSize)
						_largestBinSize = array.length;
				}
				progress = _i++ / _keys.length;
			}
			return progress;
		}
		
		private function _asyncComplete():void
		{
			_validateBinsCompleted = true; // tells handleChange() that the bins are now valid
			_derivedBins.resumeCallbacks(true); // allow callbacks to run now
		}

		/**
		 * This is the number of bins that have been generated by
		 * the binning definition using with the internal column.
		 */
		public function get numberOfBins():uint
		{
			if (_dirty)
				validateBins();
			return _binNames.length;
		}
		
		/**
		 * This is the largest number of records in any of the bins.
		 */		
		public function get largestBinSize():uint
		{
			if (_dirty)
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
			if (_dirty)
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
			if (_dirty)
				validateBins();
			return _binnedKeysMap[binName] as Array;
		}
		
		public function getBinIndexFromDataValue(value:*):Number
		{
			return _derivedBins.getBinIndexFromDataValue(value);
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
			if (_dirty)
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
			return _derivedBins.getObject(_binNames[binIndex]);
		}
		
		
		/**
		 * From a bin index, this function returns the name of the bin.
		 * @param value A bin index
		 * @return The name of the bin
		 */
		public function deriveStringFromNumber(value:Number):String
		{
			if (_dirty)
				validateBins();
			
			try
			{
				return _derivedBins.getNames()[value];
			}
			catch (e:Error) { } // ok to ignore Array[index] error
			
			return '';
		}
	}
}
