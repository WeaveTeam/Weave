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
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.core.CallbackCollection;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableHashMap;
	import weave.data.KeySets.KeySetUnion;
	import weave.utils.ColumnUtils;
	
	/**
	 * This provides a wrapper for a dynamic column, and allows new properties to be added.
	 * The purpose of this class is to provide a base for extending DynamicColumn.
	 * 
	 * @author adufilie
	 */
	public class CombinedColumn extends CallbackCollection implements IAttributeColumn
	{
		public function CombinedColumn()
		{
			registerLinkableChild(this, keySetUnion.busyStatus);
			columns.childListCallbacks.addImmediateCallback(this, handleColumnsList);
		}
		
		public const useFirstColumnMetadata:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		public const columns:ILinkableHashMap = registerLinkableChild(this, new LinkableHashMap(IAttributeColumn));
		private const keySetUnion:KeySetUnion = newLinkableChild(this, KeySetUnion);
		
		private var _columnsArray:Array = [];
		
		private function handleColumnsList():void
		{
			_columnsArray = columns.getObjects();
			if (columns.childListCallbacks.lastObjectAdded)
				keySetUnion.addKeySetDependency(columns.childListCallbacks.lastObjectAdded as IKeySet);
		}
		
		/************************************
		 * Begin IAttributeColumn interface
		 ************************************/

		public function getMetadata(propertyName:String):String
		{
			if (useFirstColumnMetadata.value)
			{
				var firstColumn:IAttributeColumn = _columnsArray[0] as IAttributeColumn;
				return firstColumn ? firstColumn.getMetadata(propertyName) : null;
			}
			return ColumnUtils.getCommonMetadata(_columnsArray, propertyName);
		}

		public function getMetadataPropertyNames():Array
		{
			// TEMPORARY SOLUTION
			var firstColumn:IAttributeColumn = _columnsArray[0] as IAttributeColumn;
			return firstColumn ? firstColumn.getMetadataPropertyNames() : null;
		}
		
		/**
		 * @return the keys associated with this column.
		 */
		public function get keys():Array
		{
			return keySetUnion.keys;
		}
		
		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		public function containsKey(key:IQualifiedKey):Boolean
		{
			return keySetUnion.containsKey(key);
		}

		/**
		 * getValueFromKey
		 * @param key A key of the type specified by keyType.
		 * @return The value associated with the given key.
		 */
		public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			for each (var column:IAttributeColumn in _columnsArray)
				if (column.containsKey(key))
					return column.getValueFromKey(key, dataType);
			return dataType == String ? '' : undefined;
		}
		
		public function toString():String
		{
			return debugId(this) + '(' + ColumnUtils.getTitle(this) + ')';
		}
	}
}
