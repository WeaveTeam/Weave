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

package weave.beans;

import java.util.Map;

public class DataTableMetadata
{
	public DataTableMetadata()
	{
	}
	
	public Map<String,String>[] getColumnMetadata()
	{
		return columnMetadata;
	}
	public void setColumnMetadata(Map<String,String>[] columnMetadata)
	{
		this.columnMetadata = columnMetadata;
	}
	public Boolean getGeometryCollectionExists()
	{
		return geometryCollectionExists;
	}
	public void setGeometryCollectionExists(Boolean geometryCollectionExists)
	{
		this.geometryCollectionExists = geometryCollectionExists;
	}
	public String getGeometryCollectionKeyType()
	{
		return geometryCollectionKeyType;
	}
	public void setGeometryCollectionKeyType(String geometryCollectionKeyType)
	{
		this.geometryCollectionKeyType = geometryCollectionKeyType;
	}
	public String getGeometryCollectionProjectionSRS()
	{
		return geometryCollectionProjectionSRS;
	}
	public void setGeometryCollectionProjectionSRS(String geometryCollectionProjectionSRS)
	{
		this.geometryCollectionProjectionSRS = geometryCollectionProjectionSRS;
	}

	Boolean geometryCollectionExists;
	String geometryCollectionKeyType;
	String geometryCollectionProjectionSRS;
	Map<String,String>[] columnMetadata;
}
