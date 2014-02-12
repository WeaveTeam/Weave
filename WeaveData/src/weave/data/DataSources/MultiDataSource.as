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

package weave.data.DataSources
{
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableDynamicObject;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IDataSource;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.registerLinkableChild;
	import weave.data.AttributeColumns.CSVColumn;
	import weave.data.AttributeColumns.EquationColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.ColumnReferences.HierarchyColumnReference;
	import weave.data.hierarchy.DataSourceTreeNode;
	import weave.utils.HierarchyUtils;

	/**
	 * This is a class to keep an updated list of all the available data sources
	 * 
	 * @author skolman
	*/
	public class MultiDataSource implements IDataSource
	{
		public function MultiDataSource()
		{
			var dependencies:Array = _root.getObjects(IDataSource).concat(_root.getObjects(EquationColumn), _root.getObjects(CSVColumn));
			for each (var obj:ILinkableObject in dependencies)
				registerLinkableChild(this, obj);
			
			_root.childListCallbacks.addImmediateCallback(this, handleWeaveChildListChange, true);
		}
		
		private static var _instance:MultiDataSource;
		public static function get instance():MultiDataSource
		{
			if (!_instance)
				_instance = new MultiDataSource();
			return _instance;
		}
		private var _root:ILinkableHashMap = WeaveAPI.globalHashMap;
		
		public function refreshHierarchy():void
		{
			var sources:Array = WeaveAPI.globalHashMap.getObjects(IDataSource);
			for each (var source:IDataSource in sources)
				source.refreshHierarchy();
		}
		
		protected const _rootNode:IWeaveTreeNode = new DataSourceTreeNode();
		
		/**
		 * Gets the root node of the attribute hierarchy.
		 */
		public function getHierarchyRoot():IWeaveTreeNode
		{
			return _rootNode;
		}
		
		/**
		 * Populates a LinkableDynamicObject with an IColumnReference corresponding to a node in the attribute hierarchy.
		 */
		public function getColumnReference(node:IWeaveTreeNode, output:ILinkableDynamicObject):Boolean
		{
			var ds:IDataSource = node.getSource() as IDataSource;
			if (ds)
				return ds.getColumnReference(node, output);
			return false;
		}
		
		private function handleWeaveChildListChange():void
		{
			// add callback to new IDataSource or IAttributeColumn so we refresh the hierarchy when it changes
			var obj:ILinkableObject = _root.childListCallbacks.lastObjectAdded
			if (obj is IDataSource || obj is IAttributeColumn)
				registerLinkableChild(this, obj);
		}
		
		public function getAttributeColumn(columnReference:IColumnReference):IAttributeColumn
		{
			if (columnReference.getDataSource() == null)
			{
				// special case -- global column hack
				var hcr:HierarchyColumnReference = columnReference as HierarchyColumnReference;
				try
				{
					var name:String = HierarchyUtils.getLeafNodeFromPath(hcr.hierarchyPath.value).@name;
					return _root.getObject(name) as IAttributeColumn;
				}
				catch (e:Error)
				{
					// do nothing
				}
				return ProxyColumn.undefinedColumn;
			}
			
			return WeaveAPI.AttributeColumnCache.getColumn(columnReference);
		}
	}
}