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
	import weavejs.api.data.IColumnWrapper;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.core.LinkableDynamicObject;
	import weavejs.util.Dictionary2D;
	import weavejs.util.JS;
	
	/**
	 * This provides a wrapper for a dynamically created column.
	 * 
	 * @author adufilie
	 */
	public class DynamicColumn extends LinkableDynamicObject implements IColumnWrapper
	{
		public function DynamicColumn(columnTypeRestriction:Class = null)
		{
			if (columnTypeRestriction == null)
			{
				columnTypeRestriction = IAttributeColumn;
			}
			else
			{
				// make sure the columnTypeRestriction implements IAttributeColumn
				if (!(columnTypeRestriction.prototype is IAttributeColumn))
				{
					JS.error("DynamicColumn(): columnTypeRestriction does not implement IAttributeColumn:", columnTypeRestriction);
					columnTypeRestriction = IAttributeColumn;
				}
			}
			
			super(columnTypeRestriction);
		}
		
		/**
		 * This function lets you skip the step of casting internalObject as an IAttributeColumn.
		 */
		public function getInternalColumn():IAttributeColumn
		{
			return internalObject as IAttributeColumn;
		}
		
		/************************************
		 * Begin IAttributeColumn interface
		 ************************************/

		public function getMetadata(propertyName:String):String
		{
			if (internalObject)
				return (internalObject as IAttributeColumn).getMetadata(propertyName);
			return null;
		}
		
		public function getMetadataPropertyNames():Array
		{
			if (internalObject)
				return (internalObject as IAttributeColumn).getMetadataPropertyNames();
			return [];
		}
		
		/**
		 * @return the keys associated with this column.
		 */
		public function get keys():Array
		{
			return getInternalColumn() ? getInternalColumn().keys : [];
		}
		
		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		public function containsKey(key:IQualifiedKey):Boolean
		{
			var col:IAttributeColumn = internalObject as IAttributeColumn;
			return col ? col.containsKey(key) : false;
		}

		// TEMPORARY PERFORMANCE IMPROVEMENT SOLUTION
		public static var cache:Boolean = true;
		private var d2d_type_key:Dictionary2D = new Dictionary2D(true, true);
		private var _cacheCounter:int = 0;
		
		/**
		 * @param key A key of the type specified by keyType.
		 * @return The value associated with the given key.
		 */
		public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (!cache)
			{
				var col:IAttributeColumn = internalObject as IAttributeColumn;
				return col ? col.getValueFromKey(key, dataType) : undefined;
			}
			
			if (triggerCounter != _cacheCounter)
			{
				_cacheCounter = triggerCounter;
				d2d_type_key = new Dictionary2D(true, true);
			}
			
			var value:* = d2d_type_key.get(dataType, key);
			if (value === undefined)
			{
				col = internalObject as IAttributeColumn;
				if (col)
					value = col.getValueFromKey(key, dataType);
				d2d_type_key.set(dataType, key, value === undefined ? UNDEFINED : value);
			}
			return value === UNDEFINED ? undefined : value;
		}
		
		private static const UNDEFINED:Object = {};
	}
}
