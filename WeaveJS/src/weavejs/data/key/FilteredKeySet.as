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

package weavejs.data.key
{
	import weavejs.WeaveAPI;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IColumnStatistics;
	import weavejs.api.data.IDynamicKeyFilter;
	import weavejs.api.data.IFilteredKeySet;
	import weavejs.api.data.IKeyFilter;
	import weavejs.api.data.IKeySet;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.core.CallbackCollection;
	import weavejs.core.LinkableBoolean;
	import weavejs.util.DebugUtils;
	import weavejs.util.JS;
	import weavejs.util.StandardLib;
	
	/**
	 * A FilteredKeySet has a base set of keys and an optional filter.
	 * The resulting set of keys becomes the intersection of the base set with the filter.
	 * 
	 * @author adufilie
	 */
	public class FilteredKeySet extends CallbackCollection implements IFilteredKeySet
	{
		public static var debug:Boolean = false;
		
		public function FilteredKeySet()
		{
			super();
			if (debug)
				addImmediateCallback(this, _firstCallback);
		}
		
		private function _firstCallback():void { DebugUtils.debugTrace(this,'trigger',keys.length,'keys'); }

		override public function dispose():void
		{
			super.dispose();
			setColumnKeySources(null);
		}
		
		private var _baseKeySet:IKeySet = null; // stores the base IKeySet
		// this stores the IKeyFilter
		private var _dynamicKeyFilter:DynamicKeyFilter = Weave.linkableChild(this, DynamicKeyFilter);
		private var _filteredKeys:Array = []; // stores the filtered list of keys
		private var map_key:Object = new JS.WeakMap();
		private var _generatedKeySets:Array;
		private var _setColumnKeySources_arguments:Array;
		
		/**
		 * When this is set to true, the inverse of the filter will be used to filter the keys.
		 * This means any keys appearing in the filter will be excluded from this key set.
		 */
		private const inverseFilter:LinkableBoolean = Weave.linkableChild(this, LinkableBoolean);
		
		/**
		 * This sets up the FilteredKeySet to get its base set of keys from a list of columns and provide them in sorted order.
		 * @param columns An Array of IAttributeColumns to use for comparing IQualifiedKeys.
		 * @param sortDirections Array of sort directions corresponding to the columns and given as integers (1=ascending, -1=descending, 0=none).
		 * @param keySortCopy A function that returns a sorted copy of an Array of keys. If specified, descendingFlags will be ignored and this function will be used instead.
		 * @param keyInclusionLogic Passed to KeySetUnion constructor.
		 * @see weave.data.KeySets.SortedKeySet#generateCompareFunction()
		 */
		public function setColumnKeySources(columns:Array/*/<IKeySet|IAttributeColumn>/*/, sortDirections:Array/*/<number>/*/ = null, keySortCopy:/*/(keys:IQualifiedKey[])=>IQualifiedKey[]/*/Function = null, keyInclusionLogic:/*/(key:IQualifiedKey)=>boolean/*/Function = null):void
		{
			if (StandardLib.compare(_setColumnKeySources_arguments, arguments) == 0)
				return;
			
			var keySet:IKeySet;
			
			// unlink from the old key set
			if (_generatedKeySets)
			{
				for each (keySet in _generatedKeySets)
					Weave.dispose(keySet);
				_generatedKeySets = null;
			}
			else
			{
				setSingleKeySource(null);
			}
			
			_setColumnKeySources_arguments = arguments;
			
			if (columns)
			{
				// KeySetUnion should not trigger callbacks
				var union:KeySetUnion = Weave.disposableChild(this, new KeySetUnion(keyInclusionLogic));
				for each (keySet in columns)
				{
					union.addKeySetDependency(keySet);
					if (keySet is IAttributeColumn)
					{
						var stats:IColumnStatistics = WeaveAPI.StatisticsCache.getColumnStatistics(keySet as IAttributeColumn);
						Weave.linkableChild(union, stats);
					}
				}
				
				if (debug && keySortCopy == null)
					trace(DebugUtils.debugId(this), 'sort by [', columns, ']');
				
				var sortCopy:Function = keySortCopy || SortedKeySet.generateSortCopyFunction(columns, sortDirections);
				// SortedKeySet should trigger callbacks
				var sorted:SortedKeySet = Weave.linkableChild(this, new SortedKeySet(union, sortCopy, columns));
				_generatedKeySets = [union, sorted];
				
				_baseKeySet = sorted;
			}
			else
			{
				_baseKeySet = null;
			}
			
			triggerCallbacks();
		}
		
		/**
		 * This function sets the base IKeySet that is being filtered.
		 * @param newBaseKeySet A new IKeySet to use as the base for this FilteredKeySet.
		 */
		public function setSingleKeySource(keySet:IKeySet):void
		{
			if (_generatedKeySets)
				setColumnKeySources(null);
			
			if (_baseKeySet == keySet)
				return;
			
			// unlink from the old key set
			if (_baseKeySet != null)
				Weave.getCallbacks(_baseKeySet).removeCallback(this, triggerCallbacks);
			
			_baseKeySet = keySet; // save pointer to new base key set
			
			// link to new key set
			if (_baseKeySet != null)
				Weave.getCallbacks(_baseKeySet).addImmediateCallback(this, triggerCallbacks, false, true);
			
			triggerCallbacks();
		}
		
		/**
		 * @return The interface for setting a filter that is applied to the base key set.
		 */
		public function get keyFilter():IDynamicKeyFilter { return _dynamicKeyFilter; }

		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		public function containsKey(key:IQualifiedKey):Boolean
		{
			if (_prevTriggerCounter != triggerCounter)
				validateFilteredKeys();
			return map_key.has(key);
		}

		/**
		 * @return The keys in this IKeySet.
		 */
		public function get keys():Array
		{
			if (_prevTriggerCounter != triggerCounter)
				validateFilteredKeys();
			return _filteredKeys;
		}
		
		private var _prevTriggerCounter:uint; // used to remember if the _filteredKeys are valid

		/**
		 * @private
		 */
		private function validateFilteredKeys():void
		{
			_prevTriggerCounter = triggerCounter; // this prevents the function from being called again before callbacks are triggered again.
			
			_asyncFilter = _dynamicKeyFilter.getInternalKeyFilter();
			
			if (_baseKeySet == null)
			{
				// no keys when base key set is undefined
				_filteredKeys = [];
				map_key = new JS.WeakMap();
				return;
			}
			if (!_asyncFilter)
			{
				// use base key set
				_filteredKeys = _baseKeySet.keys;
				map_key = new JS.WeakMap();
				for each (var key:IQualifiedKey in _filteredKeys)
					map_key.set(key, true);
				return;
			}
			
			_i = 0;
			_asyncInput = _baseKeySet.keys;
			_asyncOutput = [];
			_async_map_key = new JS.WeakMap();
			_asyncInverse = inverseFilter.value;
			
			// high priority because all visualizations depend on key sets
			WeaveAPI.Scheduler.startTask(this, iterate, WeaveAPI.TASK_PRIORITY_HIGH, asyncComplete, Weave.lang('Filtering {0} keys in {1}', _asyncInput.length, DebugUtils.debugId(this)));
		}
		
		private var _i:int;
		private var _asyncInverse:Boolean;
		private var _asyncFilter:IKeyFilter;
		private var _asyncInput:Array;
		private var _asyncOutput:Array;
		private var _async_map_key:Object;
		
		private function iterate(stopTime:int):Number
		{
			if (_prevTriggerCounter != triggerCounter)
				return 1;
			
			for (; _i < _asyncInput.length; ++_i)
			{
				if (!_asyncFilter)
					return 1;
				if (JS.now() > stopTime)
					return _i / _asyncInput.length;
				
				var key:IQualifiedKey = _asyncInput[_i] as IQualifiedKey;
				var contains:Boolean = _asyncFilter.containsKey(key);
				if (contains != _asyncInverse)
				{
					_asyncOutput.push(key);
					_async_map_key.set(key, true);
				}
			}
			
			return 1;
		}
		private function asyncComplete():void
		{
			if (_prevTriggerCounter != triggerCounter)
			{
				validateFilteredKeys();
				return;
			}
			
			_prevTriggerCounter++;
			_filteredKeys = _asyncOutput;
			map_key = _async_map_key;
			triggerCallbacks();
		}
	}
}
