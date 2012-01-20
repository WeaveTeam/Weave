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

public class DataServiceMetadata
{
	public DataServiceMetadata()
	{
	}
	public DataServiceMetadata(String serverName, Map<String,String>[] dataTableMetadata, String[] geometryCollectionNames, String[] geometryCollectionKeyTypes)
	{
		this.serverName = serverName;
		this.dataTableMetadata = dataTableMetadata;
		this.geometryCollectionNames = geometryCollectionNames;
		this.geometryCollectionKeyTypes = geometryCollectionKeyTypes;
	}
	
	private String serverName;
	private Map<String,String>[] dataTableMetadata;

	private String[] geometryCollectionNames;
	private String[] geometryCollectionKeyTypes;
	
	public String getServerName()
	{
		return serverName;
	}
	public void setServerName(String serverName)
	{
		this.serverName = serverName;
	}
	public Map<String,String>[] getDataTableMetadata()
	{
		return dataTableMetadata;
	}
	public void setDataTableMetadata(Map<String,String>[] dataTableMetadata)
	{
		this.dataTableMetadata = dataTableMetadata;
	}
	public String[] getGeometryCollectionNames()
	{
		return geometryCollectionNames;
	}
	public void setGeometryCollectionNames(String[] geometryCollectionNames)
	{
		this.geometryCollectionNames = geometryCollectionNames;
	}
	public String[] getGeometryCollectionKeyTypes()
	{
		return geometryCollectionKeyTypes;
	}
	public void setGeometryCollectionKeyTypes(String[] geometryCollectionKeyTypes)
	{
		this.geometryCollectionKeyTypes = geometryCollectionKeyTypes;
	}
}
