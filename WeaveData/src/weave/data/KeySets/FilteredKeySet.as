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
	
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IDynamicKeyFilter;
	import weave.api.data.IFilteredKeySet;
	import weave.api.data.IKeyFilter;
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.disposeObjects;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.compiler.StandardLib;
	import weave.core.CallbackCollection;
	import weave.core.LinkableBoolean;
	
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
		private var _filteredKeys:Array; // stores the filtered list of keys
		private var _filteredKeysMap:Dictionary; // this maps a key to a value of true if the key is included in this key set
		private var _generatedKeySets:Array;
		private var _sortColumns:Array;
		private var _descendingFlags:Array;
		
		/**
		 * When this is set to true, the inverse of the filter will be used to filter the keys.
		 * This means any keys appearing in the filter will be excluded from this key set.
		 */
		private const inverseFilter:LinkableBoolean = newLinkableChild(this, LinkableBoolean);
		
		/**
		 * This sets up the FilteredKeySet to get its base set of keys from a list of columns and provide them in sorted order.
		 * @param columns An Array of IAttributeColumns to use for comparing IQualifiedKeys.
		 * @param descendingFlags An Array of Boolean values to denote whether the corresponding columns should be used to sort descending or not.
		 * @param keyCompare If specified, descendingFlags will be ignored and this compare function will be used instead.
		 * @param keyInclusionLogic Passed to KeySetUnion constructor.
		 */
		public function setColumnKeySources(sortColumns:Array, descendingFlags:Array = null, keyCompare:Function = null, keyInclusionLogic:Function = null):void
		{
			if (StandardLib.arrayCompare(_sortColumns, sortColumns) == 0 &&
				StandardLib.arrayCompare(_descendingFlags, descendingFlags) == 0)
			{
				return;
			}
			
			// unlink from the old key set
			if (_generatedKeySets)
			{
				disposeObjects.apply(null, _generatedKeySets);
				_generatedKeySets = null;
			}
			else
			{
				setSingleKeySource(null);
			}
			
			_sortColumns = sortColumns;
			_descendingFlags = descendingFlags;
			
			if (sortColumns)
			{
				// KeySetUnion should not trigger callbacks
				var union:KeySetUnion = registerDisposableChild(this, new KeySetUnion(keyInclusionLogic));
				for each (var column:IAttributeColumn in sortColumns)
					union.addKeySetDependency(column);
				// SortedKeySet should trigger callbacks
				var compare:Function = keyCompare || SortedKeySet.generateCompareFunction(sortColumns, descendingFlags);
				var sorted:SortedKeySet = registerLinkableChild(this, new SortedKeySet(union, compare, sortColumns));
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
				getCallbackCollection(_baseKeySet).addImmediateCallback(this, triggerCallbacks);
			
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
			return _filteredKeysMap[key] !== undefined;
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
			
			// TODO: key type conversion here?
			
			var i:int;
			var inverse:Boolean = inverseFilter.value;
			var key:IQualifiedKey;
			var keyFilter:IKeyFilter = _dynamicKeyFilter.getInternalKeyFilter();
			if (_baseKeySet == null)
			{
				// no keys when base key set is undefined
				_filteredKeys = [];
			}
			else if (keyFilter != null)
			{
				// copy the keys that appear in both the base key set and the filter
				_filteredKeys = [];
				if (_baseKeySet != null)
				{
					var baseKeys:Array = _baseKeySet.keys;
					for (i = 0; i < baseKeys.length; i++)
					{
						key = baseKeys[i] as IQualifiedKey;
						var contains:Boolean = keyFilter.containsKey(key);
						if (contains != inverse)
							_filteredKeys.push(key);
					}
				}
			}
			else
			{
				// use base set of keys
				_filteredKeys = _baseKeySet.keys;
			}
			
			_filteredKeysMap = new Dictionary(true);
			for (i = _filteredKeys.length; i--;)
				_filteredKeysMap[_filteredKeys[i]] = i;
		}
	}
}
