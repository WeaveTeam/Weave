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
	import flash.utils.Dictionary;
	
	import weave.api.getCallbackCollection;
	import weave.api.registerLinkableChild;
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IDataSource;
	import weave.api.data.IWeaveTreeNode;
	import weave.data.AttributeColumns.CSVColumn;
	import weave.data.AttributeColumns.EquationColumn;
	import weave.data.hierarchy.ColumnTreeNode;
	
	public class GlobalColumnDataSource implements IDataSource
	{
		public static function getInstance(root:ILinkableHashMap):IDataSource
		{
			var instance:IDataSource = instances[root];
			if (!instance)
				instances[root] = instance = new GlobalColumnDataSource(root);
			return instance;
		}
		
		private static const instances:Dictionary = new Dictionary(true);
		
		public function GlobalColumnDataSource(root:ILinkableHashMap)
		{
			this._root = root;
			registerLinkableChild(this, root.childListCallbacks);
			
			var source:IDataSource = this;
			_rootNode = new ColumnTreeNode({
				dataSource: source,
				label: function():String {
					return root.getObjects(CSVColumn).length
					? lang('Generated columns')
					: lang('Equations');
				},
				hasChildBranches: false,
				children: function():Array {
					return getGlobalColumns().map(function(column:IAttributeColumn, ..._):* {
						registerLinkableChild(source, column);
						return createColumnNode(root.getName(column));
					});
				}
			});
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
			return getCallbackCollection(this);
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
