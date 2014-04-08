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
	import mx.utils.ObjectUtil;
	
	import weave.api.data.ColumnMetadata;
	import weave.api.services.beans.EntityMetadata;

	/**
	 * @author adufilie
	 */
	public class Entity extends EntityMetadata
	{
		public function Entity(info:EntityHierarchyInfo = null)
		{
			id = -1;
			if (info)
			{
				id = info.id;
				publicMetadata[ColumnMetadata.TITLE] = info.title;
				publicMetadata[ColumnMetadata.ENTITY_TYPE] = info.entityType;
			}
		}
		
		public var id:int;
		public var parentIds:Array;
		public var childIds:Array;
		public var hasChildBranches:Boolean;
		private var _hasParent:Object;
		private var _hasChild:Object;
		
		/**
		 * Resets this object so it does not contain any information.
		 */		
		public function reset():void
		{
			id = -1;
			parentIds = null;
			childIds = null;
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
			return id != -1 && parentIds && childIds;
		}
		
		public function getEntityType():String
		{
			return publicMetadata[ColumnMetadata.ENTITY_TYPE];
		}
		
		public function hasParent(parentId:int):Boolean
		{
			if (!parentIds)
				return false;
			if (!_hasParent)
			{
				_hasParent = {};
				for each (var pid:String in parentIds)
					_hasParent[pid] = true;
			}
			return _hasParent[parentId];
		}
		
		public function hasChild(childId:int):Boolean
		{
			if (!childIds)
				return false;
			if (!_hasChild)
			{
				_hasChild = {};
				for each (var cid:String in childIds)
					_hasChild[cid] = true;
			}
			return _hasChild[childId];
		}
		
		override public function toString():String
		{
			return ObjectUtil.toString(this);
		}
	}
}
