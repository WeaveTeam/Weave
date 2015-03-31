/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

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
