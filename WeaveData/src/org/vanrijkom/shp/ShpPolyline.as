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

import flash.utils.ByteArray;
import flash.utils.Endian;
import flash.geom.Rectangle;
import flash.geom.Point;

/**
 * The ShpPoint class parses an ESRI Shapefile Polyline record from a ByteArray.
 * @author Edwin van Rijkom
 * 
 */	
final public class ShpPolyline extends ShpPolygon
{
	/**
	 * Constructor.
	 * @inherit
	 * @param src
	 * @param size
	 * @return 
	 * 
	 */	
	public function ShpPolyline(src: ByteArray = null, size: uint = 0) {
		super(src,size);
		type = ShpType.SHAPE_POLYLINE;		
	}
}

} // package;