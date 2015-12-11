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

package weavejs.geom
{
	public class GeometryType
	{
		public static const POINT:String = "Point";
		public static const LINE:String = "Arc";
		public static const POLYGON:String = "Polygon";
		
		public static function toGeoJsonType(type:String, multi:Boolean):String
		{
			if (type == POINT)
				return multi ? GeoJSON.T_MULTI_POINT : GeoJSON.T_POINT;
			if (type == LINE)
				return multi ? GeoJSON.T_MULTI_LINE_STRING : GeoJSON.T_LINE_STRING;
			if (type == POLYGON)
				return multi ? GeoJSON.T_MULTI_POLYGON : GeoJSON.T_POLYGON;
			return null;
		}
		
		public static function fromPostGISType(postGISType:int):String
		{
			/*
			PostGIS Specific geometry types. 
			*/

			switch (postGISType) // read shapeType
			{
				case 1: //POINT
				case 4: //MULTIPOINT
					return GeometryType.POINT;
					break;
				case 2: //LINESTRING
				case 5: //MULTILINESTRING
					return GeometryType.LINE;
					break;
				case 3: //POLYGON
				case 6: //MULTIPOLYGON
					return GeometryType.POLYGON;
					break;
				default: 
					return null;
			}
			
		}
	}
}