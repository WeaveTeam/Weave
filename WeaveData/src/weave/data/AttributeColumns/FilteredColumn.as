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
			// also make internal column request because it may trigger callbacks
			internalDynamicColumn.keys;
			return _filteredKeySet.keys;
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
