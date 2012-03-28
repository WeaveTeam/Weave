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
 * The ShpHeader class parses an ESRI Shapefile Header from a ByteArray.
 * @author Edwin van Rijkom
 * 
 */
public class ShpHeader
{
	/**
	 * Size of the entire Shapefile as stored in the Shapefile, in bytes.
	 */	
	public var fileLength: int;
	/**
	 * Shapefile version. Expected value is 1000. 
	 */		
	public var version: int;
	/**
	 * Type of the Shape records contained in the remainder of the
	 * Shapefile. Should match one of the constant values defined
	 * in the ShpType class.
	 * @see ShpType
	 */	
	public var shapeType: int;
	/**
	 * The cartesian bounding box of all Shape records contained
	 * in this file.
	 */	
	public var boundsXY: Rectangle;
	/**
	 * The minimum (Point.x) and maximum Z (Point.y) value expected
	 * to be encountered in this file.
	 */	
	public var boundsZ: Point;
	/**
	 * The minimum (Point.x) and maximum M (Point.y) value expected
	 * to be encountered in this file.
	 */	
	public var boundsM: Point;
	
	/**
	 * Constructor.
	 * @param src
	 * @return
	 * @throws ShpError Not a valid shape file header
	 * @throws ShpError Not a valid signature
	 * 
	 */			
	public function ShpHeader(src: ByteArray) {
		// endian:
		src.endian = Endian.BIG_ENDIAN;		
		
		// check length:
		if (src.length-src.position<100)
			throw (new ShpError("Not a valid shape file header (too small)"));
		
		// check signature	
		if (src.readInt() != 9994)
			throw (new ShpError("Not a valid signature. Expected 9994"));
		
		 // skip 5 integers;
		src.position += 5*4;
		
		// read file-length:
		fileLength = src.readInt();
		
		// switch endian:
		src.endian = Endian.LITTLE_ENDIAN;
		
		// read version:
		version = src.readInt();
				
		// read shape-type:
		shapeType = src.readInt();
		
		// read bounds:
		boundsXY = new Rectangle
			( src.readDouble(), src.readDouble()
			, src.readDouble(), src.readDouble()
			);
		boundsZ = new Point( src.readDouble(), src.readDouble() );
		boundsM = new Point( src.readDouble(), src.readDouble() );				
	}
}

} // package