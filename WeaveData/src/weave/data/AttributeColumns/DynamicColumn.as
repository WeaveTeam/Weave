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
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnWrapper;
	import weave.api.data.IQualifiedKey;
	import weave.api.reportError;
	import weave.core.ClassUtils;
	import weave.core.LinkableDynamicObject;
	import weave.utils.ColumnUtils;
	
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
				var columnTypeQName:String = getQualifiedClassName(columnTypeRestriction);
				var baseQName:String = getQualifiedClassName(IAttributeColumn);
				if (!ClassUtils.classIs(columnTypeQName, baseQName))
				{
					reportError("DynamicColumn(): columnTypeRestriction does not implement IAttributeColumn: " + columnTypeQName);
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
		private var _cache_type_key:Dictionary = new Dictionary(true);
		private var _cacheCounter:int = 0;
		
		/**
		 * @param key A key of the type specified by keyType.
		 * @return The value associated with the given key.
		 */
		public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (!dataType)
				dataType = Array;
			if (!cache)
			{
				var col:IAttributeColumn = internalObject as IAttributeColumn;
				return col ? col.getValueFromKey(key, dataType) : undefined;
			}
			
			if (triggerCounter != _cacheCounter)
			{
				_cacheCounter = triggerCounter;
				_cache_type_key = new Dictionary(true);
			}
			var _cache:Dictionary = _cache_type_key[dataType];
			if (!_cache)
				_cache_type_key[dataType] = _cache = new Dictionary(true);
			
			var value:* = _cache[key];
			if (value === undefined)
			{
				col = internalObject as IAttributeColumn;
				if (col)
					value = col.getValueFromKey(key, dataType);
				_cache[key] = value === undefined ? UNDEFINED : value;
			}
			return value === UNDEFINED ? undefined : value;
		}
		
		private static const UNDEFINED:Object = {};
		
		public function toString():String
		{
			return debugId(this) + '(' + (getInternalColumn() ? getInternalColumn() : ColumnUtils.getTitle(this)) + ')';
		}
	}
}
