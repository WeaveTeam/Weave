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
	public class AttributeColumnInfo
	{
		public var id:int;
		public var entity_type:int;
                public var parent_id:int;
		public var privateMetadata:Object;
		public var publicMetadata:Object;
		
		public function AttributeColumnInfo(o:Object)
		{
			this.id = o.id;
                        this.entity_type = o.type
			this.privateMetadata = o.privateMetadata;
			this.publicMetadata = o.publicMetadata;
			
			// replace nulls with empty strings
			for each (var metadata:Object in [privateMetadata, publicMetadata])
				for (var name:String in metadata)
					if (metadata[name] == null)
						metadata[name] = '';
		}
		
		[Deprecated] public function getAllMetadata():Object
		{
			var result:Object = {};
			for each (var metadata:Object in [privateMetadata, publicMetadata])
				for (var name:String in metadata)
					result[name] = metadata[name];
			return result;
		}
	}
}
