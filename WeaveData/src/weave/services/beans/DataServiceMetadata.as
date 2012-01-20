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

	public class DataServiceMetadata
	{
		public function DataServiceMetadata(result:Object)
		{
			serverName = result.serverName;
			dataTableMetadata = result.dataTableMetadata;
			geometryCollectionNames = result.geometryCollectionNames;
			geometryCollectionKeyTypes = result.geometryCollectionKeyTypes;
			
			// add metadata for geometry collections that have no data table
			var nameMap:Object = {};
			for each (var obj:Object in dataTableMetadata)
			{
				nameMap[obj.name] = obj;
				if (!obj.title)
					obj.title = obj.name;
			}
			for each (var geomName:String in geometryCollectionNames)
				if (!nameMap[geomName])
					dataTableMetadata.push({name: geomName, title: geomName});
			dataTableMetadata.sortOn("title", Array.CASEINSENSITIVE);
		}
		
		public var serverName:String;
		public var dataTableMetadata:Array;
		public var geometryCollectionNames:Array;
		public var geometryCollectionKeyTypes:Array;
	}
}