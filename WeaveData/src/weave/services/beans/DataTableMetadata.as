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
	import flash.utils.ByteArray;

	public class DataTableMetadata
	{
		public function DataTableMetadata(result:Object)
		{
			this.geometryCollectionExists = result.geometryCollectionExists;
			this.geometryCollectionKeyType = result.geometryCollectionKeyType;
			this.geometryCollectionProjectionSRS = result.geometryCollectionProjectionSRS;
			this.columnMetadata = result.columnMetadata;
		}
	
		public var geometryCollectionExists:Boolean;
		public var geometryCollectionKeyType:String;
		public var geometryCollectionProjectionSRS:String;
		public var columnMetadata:Array;
	}
}
