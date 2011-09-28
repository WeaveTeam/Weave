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
 * The ShpObject class is the base class of all specialized Shapefile
 * record type parsers.
 * @author Edwin van Rijkom
 * @see ShpPoint
 * @see ShpPointZ
 * @see ShpPolygon
 * @see ShpPolyline
 */	
public class ShpObject
{
	/**
	 * Type of this Shape object. Should match one of the constant 
	 * values defined in the ShpType class.
	 * @see ShpType
	 */	
	public var type: int;	
}

} // package