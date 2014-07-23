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

package weave.data.KeySets
{
	import mx.utils.ObjectUtil;
	
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.linkableObjectIsBusy;
	import weave.api.newDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.compiler.StandardLib;
	import weave.core.CallbackCollection;
	import weave.data.QKeyManager;
	import weave.utils.AsyncSort;
	
	/**
	 * This provides the keys from an existing IKeySet in a sorted order.
	 * Callbacks will trigger when the sorted result changes.
	 * 
	 * @author adufilie
	 */
	public class SortedKeySet implements IKeySet
	{
		public static var debug:Boolean = false;
		
		/**
		 * @param keySet An IKeySet to sort.
		 * @param compare A function that compares two IQualifiedKey objects and returns an integer.
		 * @param dependencies A list of ILinkableObjects that affect the result of the compare function.
		 */		
		public function SortedKeySet(keySet:IKeySet, keyCompare:Function = null, dependencies:Array = null)
		{
			_keySet = keySet;
			_compare = keyCompare || QKeyManager.keyCompare;
			
			getCallbackCollection(_asyncSort).addImmediateCallback(this, _handleSorted);
			
			for each (var object:ILinkableObject in dependencies)
				registerLinkableChild(_dependencies, object);
			registerLinkableChild(_dependencies, _keySet);
			_dependencies.addImmediateCallback(this, _validate, true);
			
			if (debug)
				getCallbackCollection(this).addImmediateCallback(this, _firstCallback);
		}
		
		private function _firstCallback():void { debugTrace(this,'trigger',keys.length,'keys'); }
		
		/**
		 * This is the list of keys from the IKeySet, sorted.
		 */
		public function get keys():Array
		{
			if (_triggerCounter != _dependencies.triggerCounter)
				_validate();
			return _sortedKeys;
		}
		
		/**
		 * @inheritDoc
		 */
		public function containsKey(key:IQualifiedKey):Boolean
		{
			return _keySet.containsKey(key);
		}
		
		private var _triggerCounter:uint = 0;
		private var _dependencies:ICallbackCollection = newDisposableChild(this, CallbackCollection);
		private var _keySet:IKeySet;
		private var _compare:Function;
		private var _asyncSort:AsyncSort = newDisposableChild(this, AsyncSort);
		private var _sortedKeys:Array = [];
		private var _prevSortedKeys:Array = [];
		
		private function _validate():void
		{
			_triggerCounter = _dependencies.triggerCounter;

			// if actively sorting, don't overwrite previous keys
			if (!linkableObjectIsBusy(_asyncSort))
				_prevSortedKeys = _sortedKeys;
			
			// begin sorting a copy of the new keys
			_sortedKeys = _keySet.keys.concat();
			_asyncSort.beginSort(_sortedKeys, _compare);
		}
		
		private function _handleSorted():void
		{
			if (StandardLib.arrayCompare(_prevSortedKeys, _sortedKeys) != 0)
				getCallbackCollection(this).triggerCallbacks();
		}
		
		/**
		 * This funciton generates a compare function that will compare IQualifiedKeys based on the corresponding values in the specified columns.
		 * @param columns An Array of IAttributeColumns to use for comparing IQualifiedKeys.
		 * @param descendingFlags An Array of Boolean values to denote whether the corresponding columns should be used to sort descending or not.
		 * @return A new Function that will compare two IQualifiedKeys using numeric values from the specified columns.
		 */
		public static function generateCompareFunction(columns:Array, descendingFlags:Array = null):Function
		{
			var i:int;
			var column:IAttributeColumn;
			var result:int;
			var n:int = columns.length;
			var desc:Array = descendingFlags ? descendingFlags.concat() : [];
			desc.length = n;
			
			// when any of the columns are disposed, disable the compare function
			for each (column in columns)
				column.addDisposeCallback(null, function():void { n = 0; });
			
			return function(key1:IQualifiedKey, key2:IQualifiedKey):int
			{
				for (i = 0; i < n; i++)
				{
					column = columns[i] as IAttributeColumn;
					if (!column)
						continue;
					var value1:* = column.getValueFromKey(key1, Number);
					var value2:* = column.getValueFromKey(key2, Number);
					result = ObjectUtil.numericCompare(value1, value2);
					if (result != 0)
					{
						if (desc[i])
							return -result;
						return result;
					}
				}
				return QKeyManager.keyCompare(key1, key2);
			}
		}
	}
}
