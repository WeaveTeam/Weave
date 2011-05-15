/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/
package org.oicweave.beans;

import java.util.Map;

public class WeaveRecordList
{
	// this is a list of columns that were used to get the values in this record
	public Map<String,String>[] attributeColumnMetadata = null;
	
	// this is the keyType of the keys in recordKeys.
	public String keyType = null;
	
	// this is a list of the record identifiers that correspond to the rows in recordData.
	public String[] recordKeys = null;
	
	// this is a 2D table of data.
	// the column index corresponds to the index in attributeColumnMetadata.
	// the row index corresponds to the index in recordKeys.
	public Object[][] recordData = null;
}
