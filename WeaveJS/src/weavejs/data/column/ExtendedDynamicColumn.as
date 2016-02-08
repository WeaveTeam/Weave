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
	import weavejs.WeaveAPI;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IColumnWrapper;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.core.CallbackCollection;
	
	/**
	 * This provides a wrapper for a dynamic column, and allows new properties to be added.
	 * The purpose of this class is to provide a base for extending DynamicColumn.
	 * 
	 * @author adufilie
	 */
	public class ExtendedDynamicColumn extends CallbackCollection implements IColumnWrapper
	{
		public function ExtendedDynamicColumn()
		{
			super();
			Weave.linkableChild(this, WeaveAPI.StatisticsCache.getColumnStatistics(internalDynamicColumn));
		}
		
		/**
		 * This is for the IColumnWrapper interface.
		 */
		public function getInternalColumn():IAttributeColumn
		{
			return internalDynamicColumn.getInternalColumn();
		}
		
		/**
		 * This is the internal DynamicColumn object that is being extended.
		 */
		public function get internalDynamicColumn():DynamicColumn
		{
			return _internalDynamicColumn;
		}
		private var _internalDynamicColumn:DynamicColumn = Weave.linkableChild(this, DynamicColumn);
		
		/************************************
		 * Begin IAttributeColumn interface
		 ************************************/

		public function getMetadata(propertyName:String):String
		{
			return internalDynamicColumn.getMetadata(propertyName);
		}

		public function getMetadataPropertyNames():Array
		{
			return internalDynamicColumn.getMetadataPropertyNames();
		}
		
		/**
		 * @return the keys associated with this column.
		 */
		public function get keys():Array
		{
			return internalDynamicColumn.keys;
		}
		
		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		public function containsKey(key:IQualifiedKey):Boolean
		{
			return internalDynamicColumn.containsKey(key);
		}

		/**
		 * getValueFromKey
		 * @param key A key of the type specified by keyType.
		 * @return The value associated with the given key.
		 */
		public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			return internalDynamicColumn.getValueFromKey(key, dataType);
		}
	}
}
