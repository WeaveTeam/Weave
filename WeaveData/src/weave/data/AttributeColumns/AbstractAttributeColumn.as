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
	
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.compiler.Compiler;
	import weave.core.CallbackCollection;
	import weave.primitives.Dictionary2D;
	import weave.utils.ColumnUtils;
	import weave.utils.HierarchyUtils;
	import weave.utils.VectorUtils;
	
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
		 * Copies key/value pairs from an Object or XML attributes.
		 * Converts Array values to Strings using WeaveAPI.CSVParser.createCSVRow().
		 */
		protected static function copyValues(obj_or_xml:Object):Object
		{
			if (obj_or_xml is XML_Class)
				return HierarchyUtils.getMetadata(XML(obj_or_xml));
			
			var copy:Object = {};
			for (var key:String in obj_or_xml)
			{
				var value:* = obj_or_xml[key];
				if (value is Array)
					copy[key] = Compiler.stringify(value);
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
			return VectorUtils.getKeys(_metadata);
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
			return dataTask.arrayData[key] !== undefined;
		}

		/**
		 * @inheritDoc
		 */
		public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			var array:Array = dataTask.arrayData[key] as Array;
			if (!array)
				return dataType === String ? '' : undefined;
			
			if (!dataType || dataType === Array)
				return array;
			
			var cache:Dictionary = dataCache.dictionary[dataType] as Dictionary;
			if (!cache)
				dataCache.dictionary[dataType] = cache = new Dictionary();
			var value:* = cache[key];
			if (value === undefined)
				cache[key] = value = dataType(generateValue(key, dataType));
			return value;
		}
		
		/**
		 * Used by default getValueFromKey() implementation to cache values.
		 */
		protected /* abstract */ function generateValue(key:IQualifiedKey, dataType:Class):Object
		{
			return null;
		}
		
		public function toString():String
		{
			return debugId(this) + '(' + ColumnUtils.getTitle(this) + ')';
		}
	}
}
