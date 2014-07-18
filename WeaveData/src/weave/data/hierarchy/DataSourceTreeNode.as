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
    import weave.api.core.ILinkableHashMap;
    import weave.api.core.ILinkableObject;
    import weave.api.data.ColumnMetadata;
    import weave.api.data.IAttributeColumn;
    import weave.api.data.IDataSource;
    import weave.api.data.IWeaveTreeNode;
    import weave.api.detectLinkableObjectChange;
    import weave.api.registerLinkableChild;
    import weave.data.AttributeColumns.CSVColumn;
    import weave.data.AttributeColumns.EquationColumn;

	[RemoteClass]
    public class DataSourceTreeNode implements IWeaveTreeNode, ILinkableObject
    {
		public function DataSourceTreeNode()
		{
			registerLinkableChild(this, WeaveAPI.globalHashMap.childListCallbacks);
		}
		
		private var _dataSourceToNode:Dictionary = new Dictionary(true);
		
		// the node can re-use the same children array
		private const _childNodes:Array = [];
		
		public function equals(other:IWeaveTreeNode):Boolean
		{
			return other is DataSourceTreeNode;
		}
		
		public function getLabel():String
		{
			return lang("Data Sources");
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
			// data sources
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
			
			// global columns
			var _root:ILinkableHashMap = WeaveAPI.globalHashMap;
			var eqCols:Array = _root.getObjects(EquationColumn).concat(_root.getObjects(CSVColumn));
			if (eqCols.length)
			{
				var eqCategory:XML = <category title={ lang("Equations") }/>;
				for each (var col:IAttributeColumn in eqCols)
					eqCategory.appendChild(<attribute name={ _root.getName(col) } title={ col.getMetadata(ColumnMetadata.TITLE) }/>);
				_globalColumnNode.xml = eqCategory;
				_childNodes.push(_globalColumnNode);
			}
			
			return _childNodes;
		}
		
		private var _globalColumnNode:XMLEntityNode = new XMLEntityNode();
		
		public function dispose():void
		{
			_childNodes.length = 0;
		}
    }
}
