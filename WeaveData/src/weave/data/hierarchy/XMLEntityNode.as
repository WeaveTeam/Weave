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
    import weave.api.WeaveAPI;
    import weave.api.data.ColumnMetadata;
    import weave.api.data.IDataSource;
    import weave.api.data.IWeaveTreeNode;
    import weave.data.DataSources.IDataSource_old;
    import weave.data.DataSources.MultiDataSource;
    import weave.data.DataSources.WeaveDataSource;

	[RemoteClass]
    public class XMLEntityNode implements IWeaveTreeNode
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
		
		private function getMetadata(property:String):String
		{
			return String(_xml['@' + property]);
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
		
		public function getSource():Object
		{
			return WeaveAPI.globalHashMap.getObject(dataSourceName) || MultiDataSource.instance;
		}
		
		public function getLabel():String
		{
			var label:String = getMetadata(ColumnMetadata.TITLE)
				|| getMetadata('name')
				|| (_xml.parent() ? 'Untitled' : dataSourceName);
			
			if (isBranch())
			{
				var ds:IDataSource = getSource() as IDataSource;
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
			
			if (getMetadata('source'))
				label = lang('{0} (Source: {1})', label, getMetadata('source'));
			
			return label;
		}
		
		public function isBranch():Boolean
		{
			return String(_xml.localName()) != 'attribute';
		}
		
		public function hasChildBranches():Boolean
		{
			return _xml.child('category').length() > 0;
		}
		
		public function getChildren():Array
		{
			if (!isBranch())
				return null;
			
			var ds:IDataSource = getSource() as IDataSource;
			
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
			
			if (_childNodes.length == 0)
			{
				if (ds is IDataSource_old)
					(ds as IDataSource_old).initializeHierarchySubtree(_xml);
			}
			
			return _childNodes;
		}
		
		public function addChildAt(newChild:IWeaveTreeNode, index:int):Boolean
		{
			throw new Error("Not implemented");
		}
		
		public function removeChild(child:IWeaveTreeNode):Boolean
		{
			throw new Error("Not implemented");
		}
    }
}
