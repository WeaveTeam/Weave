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

package weave.services.beans
{	
	public class AttributeColumnDataWithKeys 
	{
		public static const NUMBER_DATATYPE:String = 'number';
		public static const STRING_DATATYPE:String = 'string';
		
		public function AttributeColumnDataWithKeys(result:Object)
		{
			this.attributeColumnName = result.attributeColumnName;
			this.keyType = result.keyType;
			this.dataType = result.dataType;

			this.keys = result.keys;
			this.data = result.data;
			this.secKeys = result.secKeys;
			this.min = result.min;
			this.max = result.max;
			this.year = result.year;
		}
		
		public var attributeColumnName: String;
		public var keyType: String;
		public var dataType: String;
		public var min: String;
		public var max: String;
		public var year: String;
		public var keys: Array;
		public var data: Array;
		public var secKeys: Array;
	}

}