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

package weavejs.api.data
{
	/**
	 * Constants that refer to standard metadata property names used by the IAttributeColumn.getMetadata() function.
	 * 
	 * @author adufilie
	 */
	public class ColumnMetadata
	{
		public static const ENTITY_TYPE:String = 'entityType';
		public static const TITLE:String = "title";
		public static const NUMBER:String = "number";
		public static const STRING:String = "string";
		public static const KEY_TYPE:String = "keyType";
		public static const DATA_TYPE:String = "dataType";
		public static const PROJECTION:String = "projection";
		public static const AGGREGATION:String = "aggregation";
		public static const DATE_FORMAT:String = "dateFormat";
		public static const DATE_DISPLAY_FORMAT:String = "dateDisplayFormat";
		public static const OVERRIDE_BINS:String = "overrideBins";
		public static const MIN:String = "min";
		public static const MAX:String = "max";
		
		public static function getAllMetadata(column:IAttributeColumn):Object
		{
			var meta:Object = {};
			var names:Array = column.getMetadataPropertyNames();
			for each (var name:String in names)
				meta[name] = column.getMetadata(name);
			return meta;
		}
		
		/**
		 * @param propertyName The name of a metadata property.
		 * @return An Array of suggested String values for the specified metadata property.
		 */
		public static function getSuggestedPropertyValues(propertyName:String):Array
		{
			switch (propertyName)
			{
				case ColumnMetadata.ENTITY_TYPE:
					return EntityType.ALL_TYPES;
				
				case ColumnMetadata.DATA_TYPE:
					return DataType.ALL_TYPES;
				
				case ColumnMetadata.DATE_DISPLAY_FORMAT:
				case ColumnMetadata.DATE_FORMAT:
					return DateFormat.getSuggestions();
				
				case ColumnMetadata.AGGREGATION:
					return Aggregation.ALL_TYPES;
				
				default:
					return [];
			}
		}
	}
}
