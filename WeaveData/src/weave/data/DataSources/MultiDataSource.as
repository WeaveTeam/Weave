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
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IAttributeHierarchy;
	import weave.api.data.IColumnReference;
	import weave.api.data.IDataSource;
	import weave.api.getCallbackCollection;
	import weave.api.getSessionState;
	import weave.api.newLinkableChild;
	import weave.core.LinkableDynamicObject;
	import weave.core.LinkableXML;
	import weave.data.AttributeColumns.EquationColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.ColumnReferences.HierarchyColumnReference;
	import weave.primitives.AttributeHierarchy;
	import weave.services.beans.HierarchicalClusteringResult;
	import weave.utils.ColumnUtils;
	import weave.utils.HierarchyUtils;

	/**
	 * MultiDataSource
	 * This is a class to keep an updated list of all the available data sources
	 * 
	 * @author skolman
	*/
	public class MultiDataSource implements IDataSource, IDisposableObject
	{
		public function MultiDataSource()
		{
			var sources:Array = _root.getObjects(IDataSource);
			
			for each(var source:IDataSource in sources)
			{
				if(!(source is MultiDataSource))
				{
					getCallbackCollection(source.attributeHierarchy).addImmediateCallback(this, handleHierarchyChange);
				}
			}
			
			_root.childListCallbacks.addImmediateCallback(this, handleWeaveChildListChange);
			handleHierarchyChange();
		}
		
		private static var _instance:MultiDataSource;
		public static function get instance():MultiDataSource
		{
			if (!_instance)
				_instance = new MultiDataSource();
			return _instance;
		}
		
		private function get _root():ILinkableHashMap { return LinkableDynamicObject.globalHashMap; }
		
		/**
		 * attributeHierarchy
		 * @return An AttributeHierarchy object that will be updated when new pieces of the hierarchy are filled in.
		 */
		private const _attributeHierarchy:AttributeHierarchy = newLinkableChild(this, AttributeHierarchy);
		public function get attributeHierarchy():IAttributeHierarchy
		{
			return _attributeHierarchy;
		}
		
		
		private function handleWeaveChildListChange():void
		{
			// add callback to new IDataSource or IAttributeColumn so we refresh the hierarchy when it changes
			var newObj:ILinkableObject = _root.childListCallbacks.lastObjectAdded;
			if (!(newObj is MultiDataSource))
				if (newObj is IDataSource || newObj is IAttributeColumn)
					getCallbackCollection(newObj).addImmediateCallback(this, handleHierarchyChange);
			
			handleHierarchyChange();
		}
		
		private function handleHierarchyChange():void
		{
			var rootNode:XML = <hierarchy name="DataSources"/>;
			
			// add category for each IDataSource
			var sources:Array = _root.getObjects(IDataSource);
			for each(var source:IDataSource in sources)
			{
				if(!(source is MultiDataSource))
				{
					var xml:XML = (source.attributeHierarchy as AttributeHierarchy).value;
					if (xml != null)
					{
						var category:XML = xml.copy();
						category.setName("category");
						category.@dataSourceName = _root.getName(source);
						rootNode.appendChild(category);
					}
				}
			}
			
			// add category for global column objects
			// TEMPORARY SOLUTION -- only allow EquationColumns
			var eqCols:Array = _root.getObjects(EquationColumn);
			if (eqCols.length > 0)
			{
				var globalCategory:XML = <category title="Equations"/>;
				for each(var col:IAttributeColumn in eqCols)
				{
					globalCategory.appendChild(<attribute name={ _root.getName(col) } title={ col.getMetadata(AttributeColumnMetadata.TITLE) }/>);
				}
				rootNode.appendChild(globalCategory);
			}
			
			_attributeHierarchy.value = rootNode;
			
		}
		
		
		/**
		 * initializeHierarchySubtree
		 * @param subtreeNode A node in the hierarchy representing the root of the subtree to initialize, or null to initialize the root of the hierarchy.
		 */
		public function initializeHierarchySubtree(subtreeNode:XML = null):void
		{
			
			var path:XML = _attributeHierarchy.getPathFromNode(subtreeNode);
			if (path == null)
				return;
			
			if (path.category.length() == 0)
				return;
			path = path.category[0];
			
			path.setName("hierarchy");
			
			var sourceName:String = path.@dataSourceName;
			
			var source:IDataSource = _root.getObject(sourceName) as IDataSource;
			
			if (source == null)
				return;
				
			
			delete path.@dataSourceName;
			
			var xml:XML = (source.attributeHierarchy as AttributeHierarchy).value;
			var currentSubTreeNode:XML = HierarchyUtils.getNodeFromPath(xml, path);
			
			source.initializeHierarchySubtree(currentSubTreeNode);
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
		
		/**
		 * This function is called when the object is no longer needed.
		 */
		public function dispose():void
		{
		}
	}
}