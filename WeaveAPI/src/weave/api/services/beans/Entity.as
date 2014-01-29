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

package weave.api.services.beans
{
	import weave.api.data.ColumnMetadata;
	import weave.api.services.beans.EntityMetadata;

	/**
	 * @author adufilie
	 */
	public class Entity extends EntityMetadata
	{
		public function Entity()
		{
			_id = -1;
		}
		
		private var _id:int;
		private var _parentIds:Array;
		private var _childIds:Array;
		private var _hasParent:Object;
		private var _hasChild:Object;
		
		/**
		 * Resets this object so it does not contain any information.
		 */		
		public function reset():void
		{
			_id = -1;
			_parentIds = null;
			_childIds = null;
			_hasParent = null;
			_hasChild = null;
			publicMetadata = {};
			privateMetadata = {};
		}
		
		/**
		 * Tests if this object has been initialized.
		 */		
		public function get initialized():Boolean
		{
			return _id != -1;
		}
		
		public function get id():int
		{
			return _id;
		}
		public function getEntityType():String
		{
			return publicMetadata[ColumnMetadata.ENTITY_TYPE];
		}
		public function get parentIds():Array
		{
			return _parentIds;
		}
		public function get childIds():Array
		{
			return _childIds;
		}
		
		public function hasParent(parentId:int):Boolean
		{
			return _hasParent[parentId];
		}
		
		public function hasChild(childId:int):Boolean
		{
			return _hasChild[childId];
		}
		
		public function copyFromResult(result:Object):void
		{
			_id = getEntityIdFromResult(result);
			privateMetadata = result.privateMetadata || {};
			publicMetadata = result.publicMetadata || {};
			_parentIds = result.parentIds;
			_childIds = result.childIds;
			_hasParent = {};
			_hasChild = {};
			var id:int;
			for each (id in _parentIds)
				_hasParent[id] = true;
			for each (id in _childIds)
				_hasChild[id] = true;
	
			// replace nulls with empty strings
			var name:String;
			for (name in privateMetadata)
				if (privateMetadata[name] == null)
					privateMetadata[name] = '';
			for (name in publicMetadata)
				if (publicMetadata[name] == null)
					publicMetadata[name] = '';
		}
		
		public static function getEntityIdFromResult(result:Object):int
		{
			return result.id;
		}
	}
}
