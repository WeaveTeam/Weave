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

public class AttributeColumnDataWithKeys {
	private String attributeColumnName;
	private String keyType;
	private String dataType;
	private String[] keys;
	private Object[] data;
	private String[] secKeys;
	private String min;
	private String max;
	private String year;
	public AttributeColumnDataWithKeys(){}
	
	public AttributeColumnDataWithKeys(
			String attributeColumnName, 
			String keyType, 
			String dataType, 
			String min, String max, String year, 
			String[] keys, 
			Object[] data,
			String[] secKeys) 
	{
		this.attributeColumnName = attributeColumnName;
		this.keyType = keyType;
		this.dataType = dataType;
		this.keys = keys;
		this.data = data;
		this.secKeys = secKeys;
		this.min = min;
		this.max = max;
		this.year = year;
	}
	
	public String getAttributeColumnName() {
		return attributeColumnName;
	}
	public void setAttributeColumnName(String attributeColumnName) {
		this.attributeColumnName = attributeColumnName;
	}
	public String getKeyType() {
		return keyType;
	}
	public void setKeyType(String keyType) {
		this.keyType = keyType;
	}
	public String getDataType()
	{
		return dataType;
	}
	public void setDataType(String dataType)
	{
		this.dataType = dataType;
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

	public void setMin(String min) {
		this.min = min;
	}

	public String getMin() {
		return min;
	}

	public void setMax(String max) {
		this.max = max;
	}

	public String getMax() {
		return max;
	}

	public String getYear()
	{
		return year;
	}
	
	public void setYear(String year)
	{
		this.year = year;
	}
}

