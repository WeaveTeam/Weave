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
	 * Constants associated with different data types.
	 * @see weave.api.data.ColumnMetadata
	 */
	public class DataType
	{
		public static const ALL_TYPES:Array/*/<string>/*/ = [NUMBER, STRING, DATE, GEOMETRY];
		
		public static const NUMBER:String = "number";
		public static const STRING:String = "string";
		public static const DATE:String = "date";
		public static const GEOMETRY:String = "geometry";
		
		/**
		 * Gets the Class associated with a dataType metadata value.
		 * This Class indicates the type of values stored in a column with given dataType metadata value.
		 * @param dataType A dataType metadata value.
		 * @return The associated Class, which can be used to pass to IAttributeColumn.getValueFromKey().
		 * @see weave.api.data.IAttributeColumn#getValueFromKey()
		 */
		public static function getClass(dataType:String):Class
		{
			switch (dataType)
			{
				case NUMBER:
					return Number;
				case DATE:
					return Date;
				case GEOMETRY:
					return Array;
				default:
					return String;
			}
		}
		
		/**
		 * @param data An Array of data values.
		 * @return A dataType metadata value, or null if no data was found.
		 */
		public static function getDataTypeFromData(data:Array):String
		{
			for each (var value:* in data)
			{
				if (value is Number)
					return NUMBER;
				if (value is Date)
					return DATE;
				if (value != null)
					return STRING;
			}
			return null;
		}
	}
}
