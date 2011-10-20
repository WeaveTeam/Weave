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

public class AttributeColumnDataWithKeys {
	private Map<String,String> metadata;
	private String[] keys;
	private Object[] data;
	private String[] secKeys;
	
	public AttributeColumnDataWithKeys(){}
	
	public AttributeColumnDataWithKeys(
			Map<String,String> metadata,
			String[] keys, 
			Object[] data,
			String[] secKeys) 
	{
		this.metadata = metadata;
		this.keys = keys;
		this.data = data;
		this.secKeys = secKeys;
	}
	
	public Map<String,String> getMetadata() {
		return metadata;
	}
	public void setMetadata(Map<String,String> metadata) {
		this.metadata = metadata;
	}
	public String[] getKeys() {
		return keys;
	}
	public void setKeys(String[] keys) {
		this.keys = keys;
	}
	public String[] getSecKeys() {
		return secKeys;
	}
	public void setSecKeys(String[] secKeys){
		this.secKeys = secKeys;
	}
	public Object[] getData() {
		return data;
	}
	public void setData(Object[] data) {
		this.data = data;
	}
}

