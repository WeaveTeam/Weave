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

/**
 * Instances of the DbfError class are thrown from the DBF library classes
 * on encountering errors.
 * @author Edwin van Rijkom
 * 
 */	
public class DbfError extends Error
{
	/**
	 * Defines the identifier value of an undefined error.  
	 */	
	public static const ERROR_UNDEFINED		: int = 0;
	/**
	 * Defines the identifier value of a 'out of bounds' error, which is thrown
	 * when an invalid item index is passed.
	 */	
	public static const ERROR_OUTOFBOUNDS	: int = 1;
	
	public function DbfError(msg: String, id: int=0) {
		super(msg,id);
	}
}

} // package