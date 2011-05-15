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

/**
 * The ShpPoint class parses an ESRI Shapefile Point record from a ByteArray.
 * @author Edwin van Rijkom
 * 
 */	
public class ShpPoint extends ShpObject
{
	/**
	 * Constructor
	 * @throws ShpError Not a Point record 
	 */	
	public var x: Number; 
	public var y: Number;
	
	public function ShpPoint(src: ByteArray = null, size: uint = 0) {
		type = ShpType.SHAPE_POINTZ;
		if (src) {			
			if (src.length - src.position < size)
				throw(new ShpError("Not a Point record (to small)"));
			
			x = (size > 0)	? src.readDouble() : NaN;
			y = (size > 8) 	? src.readDouble() : NaN;			
		}
		//trace("Point", x,y);		
	}
}

} // package