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
	/**
	 * @author adufilie
	 */
	public class Entity extends EntityMetadata
	{
		private var _id:int;
		private var _type:int;
		private var _childIds:Array;
		
		public function get id():int
		{
			return _id;
		}
		public function get type():int
		{
			return _type;
		}
		public function get childIds():Array
		{
			return _childIds;
		}
		
		public function Entity()
		{
			_id = -1;
			_type = EntityType.ANY;
		}
		
		public function getTypeString():String
		{
			return EntityType.getTypeString(_type);
		}
		
		public static function getEntityIdFromResult(result:Object):int
		{
			return result.id;
		}
		
		public function copyFromResult(result:Object):void
		{
			_id = getEntityIdFromResult(result);
			_type = result.type;
			privateMetadata = result.privateMetadata || {};
			publicMetadata = result.publicMetadata || {};
			_childIds = result.childIds;
	
			// replace nulls with empty strings
			var name:String;
			for (name in privateMetadata)
				if (privateMetadata[name] == null)
					privateMetadata[name] = '';
			for (name in publicMetadata)
				if (publicMetadata[name] == null)
					publicMetadata[name] = '';
		}
	}
}
