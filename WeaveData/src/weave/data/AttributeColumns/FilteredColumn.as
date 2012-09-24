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
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IDynamicKeyFilter;
	import weave.api.data.IKeyFilter;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.data.KeySets.FilteredKeySet;
	import weave.utils.EquationColumnLib;
	
	/**
	 * FilteredColumn
	 * 
	 * @author adufilie
	 */
	public class FilteredColumn extends ExtendedDynamicColumn
	{
		public function FilteredColumn()
		{
			_filteredKeySet.setSingleKeySource(internalDynamicColumn);
		}
		
		/**
		 * This is private because it doesn't need to appear in the session state -- keys are returned by the "get keys()" accessor function
		 */		
		private const _filteredKeySet:FilteredKeySet = newLinkableChild(this, FilteredKeySet);
		
		/**
		 * This is the dynamically created filter that filters the keys in the column.
		 */		
		public const filter:IDynamicKeyFilter = registerLinkableChild(this, _filteredKeySet.keyFilter);
		
		/**
		 * This stores the filtered keys
		 */		
		private var _keys:Array;
		
		override public function get keys():Array
		{
			return _filteredKeySet.keys;
		}
		
		/**
		 * The filter removes certain records from the column.  This function will return false if the key is not contained in the filter.
		 */
		override public function containsKey(key:IQualifiedKey):Boolean
		{
			return _filteredKeySet.containsKey(key);
		}

		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			var column:IAttributeColumn = getInternalColumn();
			var keyFilter:IKeyFilter = filter.getInternalKeyFilter();
			if (column && (!keyFilter || keyFilter.containsKey(key)))
				return column.getValueFromKey(key, dataType);
			
			if (dataType)
				return EquationColumnLib.cast(undefined, dataType);
			
			return undefined;
		}
	}
}
