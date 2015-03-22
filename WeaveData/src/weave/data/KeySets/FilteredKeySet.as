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
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IDynamicKeyFilter;
	import weave.api.data.IFilteredKeySet;
	import weave.api.data.IKeyFilter;
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.disposeObject;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.compiler.StandardLib;
	import weave.core.CallbackCollection;
	import weave.core.LinkableBoolean;
	import weave.utils.VectorUtils;
	
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
			if (debug)
				addImmediateCallback(this, _firstCallback);
		}
		
		private function _firstCallback():void { debugTrace(this,'trigger',keys.length,'keys'); }

		override public function dispose():void
		{
			super.dispose();
			setColumnKeySources(null);
		}
		
		private var _baseKeySet:IKeySet = null; // stores the base IKeySet
		// this stores the IKeyFilter
		private const _dynamicKeyFilter:DynamicKeyFilter = newLinkableChild(this, DynamicKeyFilter);
		private var _filteredKeys:Array = []; // stores the filtered list of keys
		private var _filteredKeyLookup:Dictionary = new Dictionary(true); // this maps a key to a value if the key is included in this key set
		private var _generatedKeySets:Array;
		private var _setColumnKeySources_arguments:Array;
		
		/**
		 * When this is set to true, the inverse of the filter will be used to filter the keys.
		 * This means any keys appearing in the filter will be excluded from this key set.
		 */
		private const inverseFilter:LinkableBoolean = newLinkableChild(this, LinkableBoolean);
		
		/**
		 * This sets up the FilteredKeySet to get its base set of keys from a list of columns and provide them in sorted order.
		 * @param columns An Array of IAttributeColumns to use for comparing IQualifiedKeys.
		 * @param sortDirections Array of sort directions corresponding to the columns and given as integers (1=ascending, -1=descending, 0=none).
		 * @param keySortCopy A function that returns a sorted copy of an Array of keys. If specified, descendingFlags will be ignored and this function will be used instead.
		 * @param keyInclusionLogic Passed to KeySetUnion constructor.
		 * @see weave.data.KeySets.SortedKeySet#generateCompareFunction()
		 */
		public function setColumnKeySources(columns:Array, sortDirections:Array = null, keySortCopy:Function = null, keyInclusionLogic:Function = null):void
		{
			if (StandardLib.compare(_setColumnKeySources_arguments, arguments) == 0)
				return;
			
			var keySet:IKeySet;
			
			// unlink from the old key set
			if (_generatedKeySets)
			{
				for each (keySet in _generatedKeySets)
					disposeObject(keySet);
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
				var union:KeySetUnion = registerDisposableChild(this, new KeySetUnion(keyInclusionLogic));
				for each (keySet in columns)
				{
					union.addKeySetDependency(keySet);
					if (keySet is IAttributeColumn)
					{
						var stats:IColumnStatistics = WeaveAPI.StatisticsCache.getColumnStatistics(keySet as IAttributeColumn);
						registerLinkableChild(union, stats);
					}
				}
				
				if (debug && keySortCopy == null)
					trace(debugId(this), 'sort by [', columns, ']');
				
				var sortCopy:Function = keySortCopy || SortedKeySet.generateSortCopyFunction(columns, sortDirections);
				// SortedKeySet should trigger callbacks
				var sorted:SortedKeySet = registerLinkableChild(this, new SortedKeySet(union, sortCopy, columns));
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
				getCallbackCollection(_baseKeySet).removeCallback(triggerCallbacks);
			
			_baseKeySet = keySet; // save pointer to new base key set
			
			// link to new key set
			if (_baseKeySet != null)
				getCallbackCollection(_baseKeySet).addImmediateCallback(this, triggerCallbacks, false, true);
			
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
			return _filteredKeyLookup[key] !== undefined;
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
				_filteredKeyLookup = new Dictionary(true);
				return;
			}
			if (!_asyncFilter)
			{
				// use base key set
				_filteredKeys = _baseKeySet.keys;
				_filteredKeyLookup = new Dictionary(true);
				VectorUtils.fillKeys(_filteredKeyLookup, _filteredKeys);
				return;
			}
			
			_i = 0;
			_asyncInput = _baseKeySet.keys;
			_asyncOutput = [];
			_asyncLookup = new Dictionary(true);
			_asyncInverse = inverseFilter.value;
			
			// high priority because all visualizations depend on key sets
			WeaveAPI.StageUtils.startTask(this, iterate, WeaveAPI.TASK_PRIORITY_HIGH, asyncComplete, lang('Filtering {0} keys in {1}', _asyncInput.length, debugId(this)));
		}
		
		private var _i:int;
		private var _asyncInverse:Boolean;
		private var _asyncFilter:IKeyFilter;
		private var _asyncInput:Array;
		private var _asyncOutput:Array;
		private var _asyncLookup:Dictionary;
		
		private function iterate(stopTime:int):Number
		{
			if (_prevTriggerCounter != triggerCounter)
				return 1;
			
			for (; _i < _asyncInput.length; ++_i)
			{
				if (getTimer() > stopTime)
					return _i / _asyncInput.length;
				
				var key:IQualifiedKey = _asyncInput[_i] as IQualifiedKey;
				var contains:Boolean = _asyncFilter.containsKey(key);
				if (contains != _asyncInverse)
				{
					_asyncOutput.push(key);
					_asyncLookup[key] = true;
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
			_filteredKeyLookup = _asyncLookup;
			triggerCallbacks();
		}
	}
}
