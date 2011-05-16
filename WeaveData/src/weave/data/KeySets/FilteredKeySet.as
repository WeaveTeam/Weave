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
	
	import weave.api.core.ILinkableObject;
	import weave.api.data.IDynamicKeyFilter;
	import weave.api.data.IFilteredKeySet;
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
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
		public function FilteredKeySet()
		{
		}

		override public function dispose():void
		{
			super.dispose();
			setBaseKeySet(null);
		}
		
		private var _baseKeySet:IKeySet = null; // stores the base IKeySet
		// this stores the IKeyFilter
		private const _dynamicKeyFilter:DynamicKeyFilter = newLinkableChild(this, DynamicKeyFilter, invalidateFilteredKeys);
		private var _filteredKeys:Array; // stores the filtered list of keys
		private var _filteredKeysMap:Dictionary; // this maps a key to a value of true if the key is included in this key set
		
		/**
		 * When this is set to true, the inverse of the filter will be used to filter the keys.
		 * This means any keys appearing in the filter will be excluded from this key set.
		 */
		private const inverseFilter:LinkableBoolean = newLinkableChild(this, LinkableBoolean, invalidateFilteredKeys);
		
		/**
		 * This function sets the base IKeySet that is being filtered.
		 * @param newBaseKeySet A new IKeySet to use as the base for this FilteredKeySet.
		 */
		public function setBaseKeySet(newBaseKeySet:IKeySet):void
		{
			if (_baseKeySet == newBaseKeySet)
				return;
			
			// unlink from the old key set
			if (_baseKeySet != null)
				getCallbackCollection(_baseKeySet as ILinkableObject).removeCallback(handleBaseKeySetChange);
			
			_baseKeySet = newBaseKeySet; // save pointer to new base key set

			// link to new key set
			if (_baseKeySet != null)
				getCallbackCollection(_baseKeySet as ILinkableObject).addImmediateCallback(this, handleBaseKeySetChange);
			
			handleBaseKeySetChange();
		}
		
		private function handleBaseKeySetChange():void
		{
			invalidateFilteredKeys();
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
			if (_dirty)
				validateFilteredKeys();
			return _filteredKeysMap[key] != undefined;
		}

		/**
		 * @return The keys in this IKeySet.
		 */
		public function get keys():Array
		{
			if (_dirty)
				validateFilteredKeys();
			return _filteredKeys;
		}

		/**
		 * @private
		 */
		private function invalidateFilteredKeys():void
		{
			_dirty = true;
		}

		/**
		 * @private
		 */
		private function validateFilteredKeys():void
		{
			// TODO: key type conversion here?
			
			var inverse:int = inverseFilter.value ? 1 : 0;
			var key:IQualifiedKey;
			if (_baseKeySet == null)
			{
				// no keys when base key set is undefined
				_filteredKeys = [];
			}
			else if (_dynamicKeyFilter.internalObject != null)
			{
				// copy the keys that appear in both the base key set and the filter
				_filteredKeys = new Array();
				if (_baseKeySet != null)
				{
					var baseKeys:Array = _baseKeySet.keys;
					for (var i:int = 0; i < baseKeys.length; i++)
					{
						key = baseKeys[i] as IQualifiedKey;
						var contains:int = _dynamicKeyFilter.containsKey(key) ? 1 : 0;
						if (contains ^ inverse) // XOR
							_filteredKeys.push(key);
					}
				}
			}
			else
			{
				// use base set of keys
				_filteredKeys = _baseKeySet.keys;
			}
			
			_filteredKeysMap = new Dictionary();
			for each (key in _filteredKeys)
				_filteredKeysMap[key] = true;
			
			_dirty = false; // _filteredKeys are now valid.
		}
		private var _dirty:Boolean = true; // flag to remember if the _filteredKeys are valid
	}
}
