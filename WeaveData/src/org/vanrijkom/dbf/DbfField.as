/* ************************************************************************ */
/*																			*/
/*  DBF (XBase File Reader) 												*/
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

package org.vanrijkom.dbf
{
	
import flash.utils.ByteArray;
import flash.utils.Endian;

/**
 * The DbfField class parses a field definition from a DBF file loaded to a
 * ByteArray.
 * @author Edwin van Rijkom
 * 
 */
public class DbfField
{
	/**
	 * Field name. 
	 */	
	public var name: String;
	/**
	 * Field type. 
	 */	
	public var type: uint;
	/**
	 * Field address.
	 */	
	public var address: uint;
	/**
	 * Field lenght. 
	 */	
	public var length: uint;
	/**
	 * Field decimals.
	 */	
	public var decimals: uint;
	/**
	 * Field id.
	 */	
	public var id: uint;
	/**
	 * Field set flag. 
	 */	
	public var setFlag: uint;
	/**
	 * Field index flag. 
	 */	
	public var indexFlag: uint;
	
	/**
	 * Constructor.
	 * @param src
	 * @return 
	 * 
	 */			
	public function DbfField(src: ByteArray) {
	
		name = DbfTools.readZeroTermANSIString(src);
		
		// fixed length: 10, so:
		src.position += (10-name.length);
	
		type = src.readUnsignedByte();
		address = src.readUnsignedInt();
		length = src.readUnsignedByte();
		decimals = src.readUnsignedByte();
		
		// skip 2:
		src.position += 2;
		
		id = src.readUnsignedByte();
		
		// skip 2:
		src.position += 2;
		
		setFlag = src.readUnsignedByte();
		
		// skip 7:
		src.position += 7;
		
		indexFlag = src.readUnsignedByte();		
	}
}

} // package