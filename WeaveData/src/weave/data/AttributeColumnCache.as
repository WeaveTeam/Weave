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

package weave.data
{
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IAttributeColumnCache;
	import weave.api.data.IDataSource;
	import weave.compiler.Compiler;
	import weave.primitives.Dictionary2D;
	import weave.utils.WeakReference;
	
	/**
	 * @inheritDoc
	 */
	public class AttributeColumnCache implements IAttributeColumnCache
	{
		/**
		 * @inheritDoc
		 */
		public function getColumn(dataSource:IDataSource, metadata:Object):IAttributeColumn
		{
			// null means no column
			if (metadata === null)
				return null;
			
			// special case - if dataSource is null, use WeaveAPI.globalHashMap
			if (dataSource == null)
				return globalColumnDataSource.getAttributeColumn(metadata);

			// Get the column pointer associated with the hash value.
			var hashCode:String = Compiler.stringify(metadata);
			var weakRef:WeakReference = d2d_dataSource_metadataHash.get(dataSource, hashCode) as WeakReference;
			if (weakRef != null && weakRef.value != null)
			{
				if (WeaveAPI.SessionManager.objectWasDisposed(weakRef.value))
					d2d_dataSource_metadataHash.remove(dataSource, hashCode);
				else
					return weakRef.value as IAttributeColumn;
			}
			
			// If no column is associated with this hash value, request the
			// column from its data source and save the column pointer.
			var column:IAttributeColumn = dataSource.getAttributeColumn(metadata);
			d2d_dataSource_metadataHash.set(dataSource, hashCode, new WeakReference(column));

			return column;
		}
		
		private const d2d_dataSource_metadataHash:Dictionary2D = new Dictionary2D(true, true);
		
		private static var _globalColumnDataSource:IDataSource;
		
		public static function get globalColumnDataSource():IDataSource
		{
			if (!_globalColumnDataSource)
				_globalColumnDataSource = new GlobalColumnDataSource();
			return _globalColumnDataSource;
		}
	}
}

import weave.api.core.ICallbackCollection;
import weave.api.data.ColumnMetadata;
import weave.api.data.IAttributeColumn;
import weave.api.data.IDataSource;
import weave.api.data.IWeaveTreeNode;
import weave.api.getCallbackCollection;
import weave.api.registerLinkableChild;
import weave.data.AttributeColumns.CSVColumn;
import weave.data.AttributeColumns.EquationColumn;
import weave.data.hierarchy.ColumnTreeNode;

internal class GlobalColumnDataSource implements IDataSource
{
	public function GlobalColumnDataSource()
	{
		registerLinkableChild(this, WeaveAPI.globalHashMap.childListCallbacks);
		
		var source:IDataSource = this;
		_rootNode = new ColumnTreeNode({
			dataSource: source,
			label: function():String {
				return WeaveAPI.globalHashMap.getObjects(CSVColumn).length
				? lang('Generated columns')
				: lang('Equations');
			},
			hasChildBranches: false,
			children: function():Array {
				return getGlobalColumns().map(function(column:IAttributeColumn, ..._):* {
					registerLinkableChild(source, column);
					return createColumnNode(WeaveAPI.globalHashMap.getName(column));
				});
			}
		});
	}
	
	/**
	 * The metadata property name used to identify a column appearing in WeaveAPI.globalHashMap.
	 */
	public static const NAME:String = 'name';
	
	private var _rootNode:ColumnTreeNode;
	
	private function getGlobalColumns():Array
	{
		var csvColumns:Array = WeaveAPI.globalHashMap.getObjects(CSVColumn);
		var equationColumns:Array = WeaveAPI.globalHashMap.getObjects(EquationColumn);
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
		var name:String = WeaveAPI.globalHashMap.getName(column);
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
		return WeaveAPI.globalHashMap.getObject(name) as IAttributeColumn;
	}
}
