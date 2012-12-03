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

public class AttributeColumnData
{
	public int id;
	public Map<String,String> metadata;
	public String[] keys;
	public Object[] data;
	public Object[] thirdColumn; // hack for dimension slider format
	public byte[] metadataTileDescriptors; // for geometry column
	public byte[] geometryTileDescriptors; // for geometry column
}

