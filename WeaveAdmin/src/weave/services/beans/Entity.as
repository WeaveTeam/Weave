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
	import mx.rpc.events.ResultEvent;

	public class Entity extends EntityMetadata
	{
		public var id:int;
		public var type:int;
		public var childIds:Array;
		
		public function Entity()
		{
			id = -1;
			type = TYPE_ANY;
		}
		
		public static const TYPE_ANY:int = -1;
		public static const TYPE_TABLE:int = 0;
		public static const TYPE_COLUMN:int = 1;
		public static const TYPE_CATEGORY:int = 2;
		
		public static function getEntityIdFromResult(result:Object):int
		{
			return result.id;
		}
		
		public function copyFromResult(result:Object):void
		{
			this.id = getEntityIdFromResult(result);
			this.type = result.type;
			this.privateMetadata = result.privateMetadata || {};
			this.publicMetadata = result.publicMetadata || {};
			this.childIds = result.childIds;
	
			// replace nulls with empty strings
			var name:String;
			for (name in this.privateMetadata)
				if (this.privateMetadata[name] == null)
					this.privateMetadata[name] = '';
			for (name in this.publicMetadata)
				if (this.publicMetadata[name] == null)
					this.publicMetadata[name] = '';
		}
	}
}
