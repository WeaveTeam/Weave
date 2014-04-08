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
 * The DbfHeader class parses a DBF file loaded to a ByteArray
 * @author Edwin van Rijkom
 * 
 */
public class DbfHeader
{
	/**
	 * File length
	 */	
	public var fileLength: int;
	/**
	 * File version
	 */
	public var version: int;
	/**
	 * Date of last update, Year.
	 */
	public var updateYear: int;
	/**
	 * Date of last update, Month. 
	 */	
	public var updateMonth: int;
	/**
	 * Data of last update, Day. 
	 */	
	public var updateDay: int;
	/**
	 * Number of records on file. 
	 */	
	public var recordCount: uint;
	/**
	 * Header structure size. 
	 */	
	public var headerSize: uint;
	/**
	 * Size of each record.
	 */	
	public var recordSize: uint;
	/**
	 * Incomplete transaction flag 
	 */	
	public var incompleteTransaction: uint;
	/**
	 * Encrypted flag.
	 */	
	public var encrypted: uint;
	/**
	 * DBase IV MDX flag. 
	 */	
	public var mdx: uint;
	/**
	 * Language driver.
	 */	
	public var language: uint;
	
	/**
	 * Array of DbfFields describing the fields found
	 * in each record. 
	 */	
	public var fields: Array;
		
	private  var _recordsOffset: uint;
				
	/**
	 * Constructor
	 * @param src
	 * @return 
	 * 
	 */	
	public function DbfHeader(src: ByteArray) {
		// endian:
		src.endian = Endian.LITTLE_ENDIAN;	
		
		version = src.readByte();
		updateYear = 1900+src.readUnsignedByte();
		updateMonth = src.readUnsignedByte();
		updateDay = src.readUnsignedByte();
		recordCount = src.readUnsignedInt();
		headerSize = src.readUnsignedShort();
		recordSize = src.readUnsignedShort();
		
		//skip 2:
		src.position += 2;
		
		incompleteTransaction = src.readUnsignedByte();
		encrypted = src.readUnsignedByte();
		
		// skip 12:
		src.position += 12;
		
		mdx = src.readUnsignedByte();
		language = src.readUnsignedByte();
		
		// skip 2;
		src.position += 2;
		
		// iterate field descriptors:
		fields = [];
		while (src.readByte() != 0X0D){
			src.position--;
			fields.push(new DbfField(src));
		}
		
		_recordsOffset = headerSize+1;					
	}
	
	internal function get recordsOffset(): uint {
		return _recordsOffset;
	}	
}			

}  // package