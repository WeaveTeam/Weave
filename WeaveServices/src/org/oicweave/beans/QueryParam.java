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

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

public class QueryParam
{
	public QueryParam(){}
	
	public QueryParam(Entry<String,String> entry)
	{
		this.name = entry.getKey();
		this.value = entry.getValue();
	}
	
	public QueryParam(String name, String value)
	{
		this.name = name;
		this.value = value;
	}
	
	private String name;
	public String getName()
	{
		return name;
	}
	public void setName(String name)
	{
		this.name = name;
	}

	private String value;
	public String getValue()
	{
		return value;
	}
	public void setValue(String value)
	{
		this.value = value;
	}

	public String toString()
	{
		return name + "=" + value;
	}
	
	public static Map<String,String> toMap(List<QueryParam> queryParams)
	{
		Map<String,String> map = new HashMap<String,String>();
		for (int i = 0; i < queryParams.size(); i++)
		{
			QueryParam param = queryParams.get(i);
			map.put(param.name, param.value);
		}
		return map;
	}
	@SuppressWarnings("unchecked")
	public static QueryParam[] mapToArray(Map<String,String> queryParams)
	{
		Object[] entries = queryParams.entrySet().toArray();
		QueryParam[] results = new QueryParam[entries.length];
		for (int i = 0; i < entries.length; i++)
			results[i] = new QueryParam((Entry<String,String>)entries[i]);
		return results;
	}
	@SuppressWarnings("unchecked")
	public static List<QueryParam> mapToList(Map<String,String> queryParams)
	{
		Object[] entries = queryParams.entrySet().toArray();
		List<QueryParam> results = new ArrayList<QueryParam>(entries.length);
		for (int i = 0; i < entries.length; i++)
			results.add(new QueryParam((Entry<String,String>)entries[i]));
		return results;
	}
}
