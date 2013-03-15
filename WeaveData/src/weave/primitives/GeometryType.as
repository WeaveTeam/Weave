/*
	Weave (Web-based Analysis and Visualization Environment)
	Copyright (C) 2008-present University of Massachusetts Lowell
	
	This file is a part of Weave.
	
	Weave is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License, Version 3,
	as published by the Free Software Foundation.
	
	Weave is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package weave.primitives
{
	public class GeometryType
	{
		public static const POINT:String = "Point";
		public static const LINE:String = "Arc";
		public static const POLYGON:String = "Polygon";
		
		public static function getPostGISGeomTypeFromInt(geomType:int):String
		{
			/*
			PostGIS Specific geometry types. 
			*/

			switch (geomType) // read shapeType
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