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
	import weave.api.data.EntityType;

	public class EntityHierarchyInfo
	{
		public var id:int;
		public var entityType:String;
		public var title:String;
		public var numChildren:int;
		
		public function getLabel(debug:Boolean = false):String
		{
			var branchInfo:EntityHierarchyInfo = this;
			var tableTitle:String = branchInfo.title || lang("Untitled {0}#{1}", entityType, branchInfo.id);
			
			// this is a table node, so avoid calling getEntity()
			var str:String = tableTitle;
			
			if (entityType == EntityType.TABLE)
				str = lang("{0} ({1})", str, branchInfo.numChildren);
			
			if (debug)
				str = lang("({0}#{1}) {2}", entityType, branchInfo.id, str);
			
			return str;
		}
	}
}