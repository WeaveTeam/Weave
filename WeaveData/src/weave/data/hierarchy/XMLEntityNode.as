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

package weave.data.hierarchy
{
    import weave.api.data.ColumnMetadata;
    import weave.api.data.IColumnReference;
    import weave.api.data.IDataSource;
    import weave.api.data.IWeaveTreeNode;
    import weave.api.data.IWeaveTreeNodeWithPathFinding;
    import weave.data.DataSources.IDataSource_old;
    import weave.data.DataSources.WeaveDataSource;
    import weave.utils.HierarchyUtils;

	[RemoteClass]
    public class XMLEntityNode implements IWeaveTreeNodeWithPathFinding, IColumnReference
    {
		public function XMLEntityNode(dataSourceName:String = null, xml:XML = null)
		{
			this.dataSourceName = dataSourceName;
			this.xml = xml;
		}
		
		public var dataSourceName:String;
		private var _xml:XML;
		
		// the node can re-use the same children array
		private const _childNodes:Array = [];
		
		public function get xml():XML
		{
			return _xml;
		}
		public function set xml(value:XML):void
		{
			_xml = value || <hierarchy/>;
		}
		
		private function getMetadataProperty(property:String):String
		{
			return String(_xml.@[property]);
		}
		
		public function equals(other:IWeaveTreeNode):Boolean
		{
			if (other == this)
				return true;
			var node:XMLEntityNode = other as XMLEntityNode;
			return !!node
				&& this.dataSourceName == node.dataSourceName
				&& this.xml == node.xml;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getDataSource():IDataSource
		{
			return WeaveAPI.globalHashMap.getObject(dataSourceName) as IDataSource;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getColumnMetadata():Object
		{
			if (_xml.name() == 'attribute')
				return HierarchyUtils.getMetadata(_xml);
			return null; // not a column
		}
		
		/**
		 * @inheritDoc
		 */
		public function getLabel():String
		{
			var label:String = getMetadataProperty(ColumnMetadata.TITLE)
				|| getMetadataProperty('name')
				|| (_xml.parent() ? 'Untitled' : dataSourceName);
			
			if (isBranch())
			{
				var ds:IDataSource = getDataSource();
				if (ds is WeaveDataSource && !_xml.parent())
				{
					// do nothing
				}
				else
				{
					var numChildren:int = _xml.children().length();
					if (numChildren)
						label = lang('{0} ({1})', label, numChildren);
				}
			}
			
			if (getMetadataProperty('source'))
				label = lang('{0} (Source: {1})', label, getMetadataProperty('source'));
			
			return label;
		}
		
		/**
		 * @inheritDoc
		 */
		public function isBranch():Boolean
		{
			return String(_xml.localName()) != 'attribute';
		}
		
		/**
		 * @inheritDoc
		 */
		public function hasChildBranches():Boolean
		{
			return _xml.child('category').length() > 0;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getChildren():Array
		{
			return getChildrenExt(true);
		}
		
		/**
		 * Initializes child nodes, optionally requesting that the data source initialize the hierarchy subtree if empty.
		 */
		public function getChildrenExt(requestHierarchyFromDataSource:Boolean = false):Array
		{
			if (!isBranch())
				return null;
			
			var ds:IDataSource = getDataSource();
			
			var children:XMLList = _xml.children();
			for (var i:int = 0; i < children.length(); i++)
			{
				var child:XML = children[i];
				var idStr:String = child.attribute(WeaveDataSource.ENTITY_ID);
				if (ds is WeaveDataSource && idStr)
				{
					if (!(_childNodes[i] is EntityNode))
						_childNodes[i] = new EntityNode();
					
					(_childNodes[i] as EntityNode).setEntityCache((ds as WeaveDataSource).entityCache);
					(_childNodes[i] as EntityNode).id = int(idStr);
				}
				else
				{
					if (!(_childNodes[i] is XMLEntityNode))
						_childNodes[i] = new XMLEntityNode(dataSourceName, child);
					
					(_childNodes[i] as XMLEntityNode).dataSourceName = dataSourceName;
					(_childNodes[i] as XMLEntityNode).xml = child;
				}
			}
			
			_childNodes.length = children.length();
			
			if (requestHierarchyFromDataSource && _childNodes.length == 0)
			{
				if (ds is IDataSource_old)
					(ds as IDataSource_old).initializeHierarchySubtree(_xml);
			}
			
			return _childNodes;
		}
		
		/**
		 * @inheritDoc
		 */
		public function findPathToNode(descendant:IWeaveTreeNode):Array
		{
			if (!descendant)
				return null;
			
			if (this.equals(descendant))
				return [this];

			var descendantEntityNode:EntityNode = descendant as EntityNode;
			
			// make sure to avoid requesting new children
			for each (var childNode:IWeaveTreeNode in getChildrenExt())
			{
				// is the child equivalent to the descendant?
				if (childNode.equals(descendant))
					return [this, childNode];
				
				// is the child an EntityNode?
				var childEntityNode:EntityNode = childNode as EntityNode;
				if (childEntityNode)
				{
					// no path from EntityNode to non-EntityNode
					if (!descendantEntityNode)
						continue;
					
					// is the child a parent of the descendant?
					var parentIds:Array = descendantEntityNode.getEntity().parentIds;
					if (parentIds && parentIds.indexOf(childEntityNode.id) >= 0)
						return [this, childNode, descendant];
					
					// otherwise, don't attempt to find the path (avoid calling childEntityNode.getEntity())
					continue;
				}
				
				// otherwise, the child should be an XMLEntityNode
				var childXMLEntityNode:XMLEntityNode = childNode as XMLEntityNode;
				if (!childXMLEntityNode)
					return null;
				
				// find corresponding XML node
				var path:Array = childXMLEntityNode.findPathToNode(descendant);
				if (path)
				{
					path.unshift(this);
					return path;
				}
			}
			return null;
		}
    }
}
