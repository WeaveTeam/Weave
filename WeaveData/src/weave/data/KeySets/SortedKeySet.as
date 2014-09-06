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
		// Note: not using newLinkableChild for _asyncSort because we do not trigger if sorting does not affect order
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
			// only trigger callbacks if sorting changes order
			if (StandardLib.arrayCompare(_prevSortedKeys, _sortedKeys) != 0)
				getCallbackCollection(this).triggerCallbacks();
		}
		
		/**
		 * This funciton generates a compare function that will compare IQualifiedKeys based on the corresponding values in the specified columns.
		 * @param columns An Array of IAttributeColumns to use for comparing IQualifiedKeys.
		 * @param sortDirections Array of sort directions corresponding to the columns and given as integers (1=ascending, -1=descending, 0=none).
		 * @return A new Function that will compare two IQualifiedKeys using numeric values from the specified columns.
		 */
		public static function generateCompareFunction(columns:Array, sortDirections:Array = null):Function
		{
			return new KeyComparator(columns, sortDirections).compare;
		}
	}
}

import mx.utils.ObjectUtil;

import weave.api.core.ILinkableObject;
import weave.api.data.IAttributeColumn;
import weave.api.data.IQualifiedKey;
import weave.api.getCallbackCollection;
import weave.data.QKeyManager;

internal class KeyComparator
{
	public function KeyComparator(columns:Array, sortDirections:Array)
	{
		this.columns = columns.concat();
		this.n = columns.length;
		this.sortDirections = sortDirections ? sortDirections.concat() : [];
		this.sortDirections.length = columns.length;
		
		// when any of the columns are disposed, disable the compare function
		for each (var obj:ILinkableObject in columns)
			getCallbackCollection(obj).addDisposeCallback(null, dispose);
	}
	
	private var columns:Array;
	private var sortDirections:Array;
	private var n:int;
	
	public function compare(key1:IQualifiedKey, key2:IQualifiedKey):int
	{
		for (var i:int = 0; i < n; i++)
		{
			var column:IAttributeColumn = columns[i] as IAttributeColumn;
			if (!column || !sortDirections[i])
				continue;
			var value1:* = column.getValueFromKey(key1, Number);
			var value2:* = column.getValueFromKey(key2, Number);
			var result:int = ObjectUtil.numericCompare(value1, value2);
			if (result != 0)
			{
				if (sortDirections[i] < 0)
					return -result;
				return result;
			}
		}
		return QKeyManager.keyCompare(key1, key2);
	}
	
	public function dispose():void
	{
		columns = null;
		sortDirections = null;
		n = 0;
	}
}
