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
import org.vanrijkom.shp.ShpPointZ;
import org.vanrijkom.shp.ShpError;
import org.vanrijkom.shp.ShpPoint;

/**
 * The ShpPoint class parses an ESRI Shapefile Record Header from a ByteArray
 * as well as its associated Shape Object. The parsed object is stored as a 
 * ShpObject that can be cast to a specialized ShpObject deriving class using 
 * the found shapeType value.
 * @author Edwin van Rijkom
 * 
 */
public class ShpRecord
{
	/**
	 * Record number 
	 */	
	public var number: int;
	/**
	 * Content length in 16-bit words 
	 */
	public var contentLength: int;
	/**
	 * Content length in bytes 
	 */
	public var contentLengthBytes: uint;
	/**
	 * Type of the Shape Object associated with this Record Header.
	 * Should match one of the constant values defined in the ShpType class.
	 * @see ShpType
	 */	
	public var shapeType: int;
	/**
	 * Parsed Shape Object. Cast to the specialized ShpObject deriving class
	 * indicated by the shapeType property to obtain Shape type specific
	 * data. 
	 */	
	public var shape: ShpObject;
	
	/**
	 * Constructor.
	 * @param src
	 * @return 
	 * @throws ShpError Not a valid header
	 * @throws Shape type is currently unsupported by this library
	 * @throws Encountered unknown shape type
	 * 
	 */	
	public function ShpRecord(src: ByteArray) {
		var availableBytes: int = src.length - src.position;
		
		if (availableBytes == 0) 
			throw(new ShpError("",ShpError.ERROR_NODATA));
			
		if (src.length - src.position < 8)
			throw(new ShpError("Not a valid record header (too small)"));
	
		src.endian = Endian.BIG_ENDIAN;

		number = src.readInt();
		contentLength = src.readInt();
		contentLengthBytes = contentLength*2 - 4;			
		src.endian = Endian.LITTLE_ENDIAN;
		var shapeOffset: uint = src.position;
		shapeType = src.readInt();
				
		switch(shapeType) {
			case ShpType.SHAPE_POINT:
				shape = new ShpPoint(src,contentLengthBytes);
				break;
			case ShpType.SHAPE_POINTZ:
				shape = new ShpPointZ(src,contentLengthBytes);
				break;
			case ShpType.SHAPE_POLYGON:
				shape = new ShpPolygon(src, contentLengthBytes);
				break;
			case ShpType.SHAPE_POLYLINE:
				shape = new ShpPolyline(src, contentLengthBytes);
				break;
			case ShpType.SHAPE_MULTIPATCH:
			case ShpType.SHAPE_MULTIPOINT:
			case ShpType.SHAPE_MULTIPOINTM:
			case ShpType.SHAPE_MULTIPOINTZ:
			case ShpType.SHAPE_POINTM:
			case ShpType.SHAPE_POLYGONM:
			case ShpType.SHAPE_POLYGONZ:
			case ShpType.SHAPE_POLYLINEZ:
			case ShpType.SHAPE_POLYLINEM:
				throw(new ShpError(shapeType+" Shape type is currently unsupported by this library"));
				break;	
			default:	
				throw(new ShpError("Encountered unknown shape type ("+shapeType+")"));
				break;
		}
					
	}
}

} // package