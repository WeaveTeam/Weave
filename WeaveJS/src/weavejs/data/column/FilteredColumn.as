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

package weavejs.data.column
{
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IDynamicKeyFilter;
	import weavejs.api.data.IKeyFilter;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.data.EquationColumnLib;
	import weavejs.data.key.FilteredKeySet;
	
	/**
	 * FilteredColumn
	 * 
	 * @author adufilie
	 */
	public class FilteredColumn extends ExtendedDynamicColumn
	{
		public function FilteredColumn()
		{
			super();
			_filteredKeySet.setSingleKeySource(internalDynamicColumn);
		}
		
		/**
		 * This is private because it doesn't need to appear in the session state -- keys are returned by the "get keys()" accessor function
		 */		
		private var _filteredKeySet:FilteredKeySet = Weave.linkableChild(this, FilteredKeySet);
		
		/**
		 * This is the dynamically created filter that filters the keys in the column.
		 */		
		public var filter:IDynamicKeyFilter = Weave.linkableChild(this, _filteredKeySet.keyFilter);
		
		/**
		 * This stores the filtered keys
		 */		
		private var _keys:Array;
		
		override public function get keys():Array
		{
			// also make internal column request because it may trigger callbacks
			if (internalDynamicColumn.keys)
				return _filteredKeySet.keys;
			return [];
		}
		
		/**
		 * The filter removes certain records from the column.  This function will return false if the key is not contained in the filter.
		 */
		override public function containsKey(key:IQualifiedKey):Boolean
		{
			// also make internal column request because it may trigger callbacks
			internalDynamicColumn.containsKey(key);
			return _filteredKeySet.containsKey(key);
		}

		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			var column:IAttributeColumn = internalDynamicColumn.getInternalColumn();
			var keyFilter:IKeyFilter = filter.getInternalKeyFilter();
			if (column)
			{
				// always make internal column request because it may trigger callbacks
				var value:* = column.getValueFromKey(key, dataType);
				if (!keyFilter || keyFilter.containsKey(key))
					return value;
			}
			
			if (dataType)
				return EquationColumnLib.cast(undefined, dataType);
			
			return undefined;
		}
	}
}
