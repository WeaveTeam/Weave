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

/**
 * The DbfFilter class is a utility class that allows for collecting records
 * that match on one of the given values for a field.
 * @author Edwin
 * 
 */	
public class DbfFilter
{
	/**
	 * Array containing DbfRecord typed values that match on one of the given 
	 * values for a field. 
	 */	
	public var matches: Array;
	
	/**
	 * Constructor.
	 * @param src ByteArray containing the DBF file to filter.
	 * @param header DbfHeader instance previously read from the ByteArray.
	 * @param field Field to filter on.
	 * @param values Array of values to match field against.
	 * @param append If specified, the found records will be added to the specified Array instead of to the instance's matches array.
	 * @return 
	 * @see DbfHeader
	 * 
	 */	
	public function DbfFilter(src: ByteArray, header: DbfHeader, field: String, values: Array, append: Array=null) {
		matches = append || [];
		src.position = header.recordsOffset;
		var record: DbfRecord;
		var i: uint, j: uint;
		for (i= 0; i<header.recordCount; i++) {
			record = DbfTools.getRecord(src,header,i);
			for (j=0; j<values.length; j++) {
				if (record.values[field.toString()].match(values[j])) {
					matches.push(record);				
					break;
				}
			}			
		}				
	}
	
}

} // package