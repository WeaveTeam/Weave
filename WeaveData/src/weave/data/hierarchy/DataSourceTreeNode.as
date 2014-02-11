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
package weave.data.hierarchy
{
    import flash.utils.Dictionary;
    
    import weave.api.WeaveAPI;
    import weave.api.core.ILinkableObject;
    import weave.api.data.EntityType;
    import weave.api.data.IDataSource;
    import weave.api.detectLinkableObjectChange;
    import weave.api.registerLinkableChild;
    import weave.api.data.IEntityTreeNode;
    import weave.data.DataSources.WeaveDataSource;
    import weave.primitives.AttributeHierarchy;

	[RemoteClass]
    public class DataSourceTreeNode implements IEntityTreeNode, ILinkableObject
    {
		public function DataSourceTreeNode()
		{
			registerLinkableChild(this, WeaveAPI.globalHashMap.childListCallbacks);
		}
		
		private var _dataSourceToNode:Dictionary = new Dictionary(true);
		
		// the node can re-use the same children array
		private const _childNodes:Array = [];
		
		public function getSource():Object
		{
			return null;
		}
		
		public function getLabel():String
		{
			return "Data Sources";
		}
		
		public function isBranch():Boolean
		{
			return true;
		}
		
		public function hasChildBranches():Boolean
		{
			return true;
		}
		
		public function getChildren():Array
		{
			var dataSources:Array = WeaveAPI.globalHashMap.getObjects(IDataSource);
			for (var i:int = 0; i < dataSources.length; i++)
			{
				var ds:IDataSource = dataSources[i];
				
				if (!_dataSourceToNode[ds])
					registerLinkableChild(this, ds);
				
				if (detectLinkableObjectChange(getChildren, ds))
					_dataSourceToNode[ds] = ds.getHierarchyRoot();
				
				_childNodes[i] = _dataSourceToNode[ds];
			}
			_childNodes.length = dataSources.length;
			
			return _childNodes;
		}
		
		public function addChildAt(newChild:IEntityTreeNode, index:int):Boolean
		{
			throw new Error("Not implemented");
		}
		
		public function removeChild(child:IEntityTreeNode):Boolean
		{
			throw new Error("Not implemented");
		}
		
		public function dispose():void
		{
			_childNodes.length = 0;
		}
    }
}
