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

package weavejs.data.hierarchy
{
	import weavejs.api.core.ICallbackCollection;
	import weavejs.api.core.ILinkableHashMap;
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IDataSource;
	import weavejs.api.data.IWeaveTreeNode;
	import weavejs.data.column.CSVColumn;
	import weavejs.data.column.EquationColumn;
	import weavejs.util.JS;
	
	public class GlobalColumnDataSource implements IDataSource
	{
		public static function getInstance(root:ILinkableHashMap):IDataSource
		{
			var instance:IDataSource = map_root_instance.get(root);
			if (!instance)
				map_root_instance.set(root, instance = new GlobalColumnDataSource(root));
			return instance;
		}
		
		private static const map_root_instance:Object = new JS.Map();
		
		public function GlobalColumnDataSource(root:ILinkableHashMap)
		{
			this._root = root;
			Weave.linkableChild(this, root.childListCallbacks);
			
			var source:IDataSource = this;
			_rootNode = new ColumnTreeNode({
				dataSource: source,
				label: getLabel,
				hasChildBranches: false,
				children: function():Array {
					return getGlobalColumns().map(function(column:IAttributeColumn, ..._):* {
						Weave.linkableChild(source, column);
						return createColumnNode(root.getName(column));
					});
				}
			});
		}
		
		
		public function getLabel():String
		{
			return _root.getObjects(CSVColumn).length
				?	Weave.lang('Generated columns')
				:	Weave.lang('Equations');
		}
		
		/**
		 * The metadata property name used to identify a column appearing in root.
		 */
		public static const NAME:String = 'name';
		
		private var _root:ILinkableHashMap;
		
		private var _rootNode:ColumnTreeNode;
		
		private function getGlobalColumns():Array
		{
			var csvColumns:Array = _root.getObjects(CSVColumn);
			var equationColumns:Array = _root.getObjects(EquationColumn);
			return equationColumns.concat(csvColumns);
		}
		private function createColumnNode(name:String):ColumnTreeNode
		{
			var column:IAttributeColumn = getAttributeColumn(name);
			if (!column)
				return null;
			
			var meta:Object = {};
			meta[NAME] = name;
			return new ColumnTreeNode({
				dataSource: this,
				dependency: column,
				label: function():String {
					return column.getMetadata(ColumnMetadata.TITLE);
				},
				data: meta,
				idFields: [NAME]
			});
		}
		
		public function get hierarchyRefresh():ICallbackCollection
		{
			return Weave.getCallbacks(this);
		}
		
		public function getHierarchyRoot():IWeaveTreeNode
		{
			return _rootNode;
		}
		
		public function findHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			var column:IAttributeColumn = getAttributeColumn(metadata);
			if (!column)
				return null;
			var name:String = _root.getName(column);
			var node:ColumnTreeNode = createColumnNode(name);
			var path:Array = _rootNode.findPathToNode(node);
			if (path)
				return path[path.length - 1];
			return null;
		}
		
		public function getAttributeColumn(metadata:Object):IAttributeColumn
		{
			if (!metadata)
				return null;
			var name:String;
			if (typeof metadata == 'object')
				name = metadata[NAME];
			else
				name = metadata as String;
			return _root.getObject(name) as IAttributeColumn;
		}
	}
}
