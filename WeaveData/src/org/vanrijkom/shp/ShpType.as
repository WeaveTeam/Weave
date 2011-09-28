/* ************************************************************************ */
/*																			*/
/*  SHP (ESRI ShapeFile Reader)												*/
/*  Copyright (c)2007 Edwin van Rijkom										*/
/*  http://www.vanrijkom.org												*/
/*																			*/
/* This library is free software; you can redistribute it and/or			*/
/* modify it under the terms of the GNU Lesser General Public				*/
/* License as published by the Free Software Foundation; either				*/
/* version 2.1 of the License, or (at your option) any later version.		*/
/*																			*/
/* This library is distributed in the hope that it will be useful,			*/
/* but WITHOUT ANY WARRANTY; without even the implied warranty of			*/
/* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU		*/
/* Lesser General Public License or the LICENSE file for more details.		*/
/*																			*/
/* ************************************************************************ */

package org.vanrijkom.shp
{

/**
 * The ShpType class is a place holder for the ESRI Shapefile defined
 * shape types.
 * @author Edwin van Rijkom
 * 
 */	
public class ShpType
{	
	/**
	 * Unknow Shape Type (for internal use) 
	 */
	public static const SHAPE_UNKNOWN		: int = -1;
	/**
	 * ESRI Shapefile Null Shape shape type.
	 */	
	public static const SHAPE_NULL			: int = 0;
	/**
	 * ESRI Shapefile Point Shape shape type.
	 */
	public static const SHAPE_POINT			: int = 1;
	/**
	 * ESRI Shapefile PolyLine Shape shape type.
	 */
	public static const SHAPE_POLYLINE		: int = 3;
	/**
	 * ESRI Shapefile Polygon Shape shape type.
	 */
	public static const SHAPE_POLYGON		: int = 5;
	/**
	 * ESRI Shapefile Multipoint Shape shape type
	 * (currently unsupported).
	 */
	public static const SHAPE_MULTIPOINT	: int = 8;
	/**
	 * ESRI Shapefile PointZ Shape shape type.
	 */
	public static const SHAPE_POINTZ		: int = 11;
	/**
	 * ESRI Shapefile PolylineZ Shape shape type
	 * (currently unsupported).
	 */
	public static const SHAPE_POLYLINEZ 	: int = 13;
	/**
	 * ESRI Shapefile PolygonZ Shape shape type
	 * (currently unsupported).
	 */
	public static const SHAPE_POLYGONZ		: int = 15;
	/**
	 * ESRI Shapefile MultipointZ Shape shape type
	 * (currently unsupported).
	 */
	public static const SHAPE_MULTIPOINTZ	: int = 18;
	/**
	 * ESRI Shapefile PointM Shape shape type
	 */
	public static const SHAPE_POINTM		: int = 21;
	/**
	 * ESRI Shapefile PolyLineM Shape shape type
	 * (currently unsupported).
	 */
	public static const SHAPE_POLYLINEM		: int = 23;
	/**
	 * ESRI Shapefile PolygonM Shape shape type
	 * (currently unsupported).
	 */
	public static const SHAPE_POLYGONM		: int = 25;
	/**
	 * ESRI Shapefile MultiPointM Shape shape type
	 * (currently unsupported).
	 */
	public static const SHAPE_MULTIPOINTM	: int = 28;
	/**
	 * ESRI Shapefile MultiPatch Shape shape type
	 * (currently unsupported).
	 */
	public static const SHAPE_MULTIPATCH	: int = 31;
}

} // package