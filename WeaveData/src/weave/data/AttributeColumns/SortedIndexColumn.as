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
	
	import mx.utils.ObjectUtil;
	
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.compiler.StandardLib;
	import weave.core.LinkableWatcher;
	import weave.data.KeySets.SortedKeySet;
	import weave.data.QKeyManager;
	import weave.utils.AsyncSort;
	import weave.utils.VectorUtils;
	
	/**
	 * This column maps a record key to the index in the list of records sorted by numeric value.
	 * 
	 * @author adufilie
	 */
	public class SortedIndexColumn extends DynamicColumn implements IAttributeColumn, IPrimitiveColumn
	{
		public function SortedIndexColumn()
		{
			this.addImmediateCallback(this, _updateStats);
		}
		
		private var _sortedKeys:Array;
		private var _sortIndex:Dictionary;
		private var _column:IAttributeColumn;
		private var _triggerCount:uint = 0;
		private const _statsWatcher:LinkableWatcher = newLinkableChild(this, LinkableWatcher);
		
		private function _updateStats():void
		{
			_column = getInternalColumn();
			_statsWatcher.target = _column && WeaveAPI.StatisticsCache.getColumnStatistics(_column);
		}
		
		private function get _stats():IColumnStatistics
		{
			return _statsWatcher.target as IColumnStatistics;
		}
		
		private function validate():void
		{
			if (_column)
			{
				_sortIndex = _stats.getSortIndex();
				if (_sortIndex)
					_sortedKeys = StandardLib.sortOn(_column.keys, _sortIndex, null, false);
				else
					_sortedKeys = _column.keys;
			}
			else
			{
				_sortIndex = null;
				_sortedKeys = [];
			}
			
			_triggerCount = triggerCounter;
		}

		override public function get keys():Array
		{
			if (_triggerCount != triggerCounter)
				validate();
			
			return _sortedKeys;
		}
		
		/**
		 * @param key A key existing in the internal column.
		 * @param dataType A requested return type.
		 * @return If dataType is not specified, returns the index of the key in the sorted list of keys.
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (_triggerCount != triggerCounter)
				validate();
			
			if (!_column)
				return dataType == String ? '' : undefined;
			
			if (dataType == Number)
				return _sortIndex ? Number(_sortIndex[key]) : NaN;
			
			return _column.getValueFromKey(key, dataType);
		}
		
		/**
		 * @param index The index in the sorted keys vector.
		 * @return The key at the given index value.
		 */
		public function deriveStringFromNumber(index:Number):String
		{
			if (_triggerCount != triggerCounter)
				validate();
			
			if (!_column || index < 0 || index >= _sortedKeys.length || int(index) != index)
				return '';
			return _column.getValueFromKey(_sortedKeys[index], String);
		}
	}
}
