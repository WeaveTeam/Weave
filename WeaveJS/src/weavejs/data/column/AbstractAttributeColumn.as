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
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.core.CallbackCollection;
	import weavejs.util.Dictionary2D;
	import weavejs.util.JS;
	
	/**
	 * This object contains a mapping from keys to data values.
	 * 
	 * @author adufilie
	 */
	public class AbstractAttributeColumn extends CallbackCollection implements IAttributeColumn
	{
		public function AbstractAttributeColumn(metadata:Object = null)
		{
			super();
			if (metadata)
				setMetadata(metadata);
		}
		
		protected var _metadata:Object = null;

		/**
		 * This function should only be called once, before setting the record data.
		 * @param metadata Metadata for this column.
		 */
		public function setMetadata(metadata:Object):void
		{
			if (_metadata !== null)
				throw new Error("Cannot call setMetadata() if already set");
			// make a copy because we don't want any surprises (metadata being set afterwards)
			_metadata = copyValues(metadata);
			// make sure dataType will be included in getMetadataPropertyNames() result
			_metadata[ColumnMetadata.DATA_TYPE] = getMetadata(ColumnMetadata.DATA_TYPE);
		}
		
		/**
		 * Copies key/value pairs from an Object.
		 * Converts Array values to Strings using WeaveAPI.CSVParser.createCSVRow().
		 */
		protected static function copyValues(object:Object):Object
		{
			var copy:Object = {};
			for (var key:String in object)
			{
				var value:* = object[key];
				if (value is Array)
					copy[key] = JSON.stringify(value);
				else
					copy[key] = value;
			}
			return copy;
		}
		
		// metadata for this attributeColumn (statistics, description, unit, etc)
		public function getMetadata(propertyName:String):String
		{
			var value:String = null;
			if (_metadata)
				value = _metadata[propertyName] || null;
			return value;
		}
		
		public function getMetadataPropertyNames():Array
		{
			return JS.objectKeys(_metadata);
		}
		
		// 'abstract' functions, should be defined with override when extending this class

		/**
		 * Used by default getValueFromKey() implementation. Must be explicitly initialized.
		 */
		protected var dataTask:ColumnDataTask;
		
		/**
		 * Used by default getValueFromKey() implementation. Must be explicitly initialized.
		 */
		protected var dataCache:Dictionary2D;
		
		/**
		 * @inheritDoc
		 */
		public function get keys():Array
		{
			return dataTask.uniqueKeys;
		}
		
		/**
		 * @inheritDoc
		 */
		public function containsKey(key:IQualifiedKey):Boolean
		{
			return dataTask.map_key_arrayData.has(key);
		}

		/**
		 * @inheritDoc
		 */
		public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			var array:Array = dataTask.map_key_arrayData.get(key);
			if (!array)
				return dataType === String ? '' : undefined;
			
			if (!dataType || dataType === Array)
				return array;
			
			var value:* = dataCache.get(dataType, key);
			if (value === undefined)
				dataCache.set(dataType, key, value = dataType(generateValue(key, dataType)));
			return value;
		}
		
		/**
		 * Used by default getValueFromKey() implementation to cache values.
		 */
		protected /* abstract */ function generateValue(key:IQualifiedKey, dataType:Class):Object
		{
			return null;
		}
	}
}
