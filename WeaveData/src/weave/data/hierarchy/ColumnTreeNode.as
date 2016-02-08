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
    import weave.compiler.StandardLib;
    import weave.utils.HierarchyUtils;

	/**
	 * A node in a tree whose leaves identify attribute columns.
	 * The <code>data</code> property is used for column metadata on leaf nodes.
	 * The following properties are used for equality comparison, in addition to node class definitions:<br>
	 * <code>dataSource, data, idFields</code><br>
	 * The following properties are used by ColumnTreeNode but not for equality comparison:<br>
	 * <code>label, children, hasChildBranches</code><br>
	 */
	[RemoteClass] public class ColumnTreeNode extends WeaveTreeDescriptorNode implements IWeaveTreeNodeWithPathFinding, IColumnReference
	{
		/**
		 * The <code>data</code> parameter is used for column metadata on leaf nodes.
		 * The following properties are used for equality comparison, in addition to node class definitions:
		 *     <code>dependency, data, dataSource, idFields</code><br>
		 * The following properties are used by ColumnTreeNode but not for equality comparison:
		 *     <code>label, children, hasChildBranches</code><br>
		 * @param params An values for the properties of this ColumnTreeNode.
		 *               The <code>dataSource</code> property is required.
		 *               If no <code>dependency</code> property is given, <code>dataSource.hierarchyRefresh</code> will be used as the dependency.
		 */
		public function ColumnTreeNode(params:Object)
		{
			super(params);
			
			childItemClass = ColumnTreeNode;
			
			if (!dataSource)
				throw new Error('ColumnTreeNode constructor: "dataSource" parameter is required');
			if (!dependency)
				dependency = dataSource.hierarchyRefresh;
		}
		
		/**
		 * IDataSource for this node.
		 */
		public var dataSource:IDataSource = null;
		
		/**
		 * A list of data fields to use for node equality tests.
		 */
		public var idFields:Array = null;

		/**
		 * If there is no label, this will use data['title'] if defined.
		 */
		override public function get label():String
		{
			var str:String = super.label;
			if (!str && data)
				str = (typeof data == 'object' && data.hasOwnProperty(ColumnMetadata.TITLE))
					? data[ColumnMetadata.TITLE]
					: data.toString();
			return str;
		}
		
		/**
		 * Compares constructor, dataSource, dependency, data, idFields.
		 * @inheritDoc
		 */
		override public function equals(other:IWeaveTreeNode):Boolean
		{
			var that:ColumnTreeNode = other as ColumnTreeNode;
			if (!that)
				return false;
			
			// compare constructor
			if (Object(this).constructor != Object(that).constructor)
				return false; // constructor differs
			
			// compare dependency
			if (this.dependency != that.dependency)
				return false; // dependency differs
			
			// compare dataSource
			if (this.dataSource != that.dataSource)
				return false; // dataSource differs
			
			// compare idFields
			if (StandardLib.compare(this.idFields, that.idFields) != 0)
				return false; // idFields differs
			
			// compare data
			if (this.idFields) // partial data comparison
			{
				for each (var field:String in idFields)
					if (StandardLib.compare(this.data[field], that.data[field]) != 0)
						return false; // data differs
			}
			else if (StandardLib.compare(this.data, that.data) != 0) // full data comparison
				return false; // data differs
			
			return true;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getDataSource():IDataSource
		{
			return dataSource;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getColumnMetadata():Object
		{
			if (isBranch())
				return null;
			return data;
		}
		
		/**
		 * @inheritDoc
		 */
		public function findPathToNode(descendant:IWeaveTreeNode):Array
		{
			// base case - if nodes are equal
			if (this.equals(descendant))
				return [this];
			
			// stopping condition - if ColumnTreeNode descendant dataSource or idFields values differ
			var _descendant:ColumnTreeNode = descendant as ColumnTreeNode;
			if (_descendant)
			{
				// don't look for a descendant with different a dataSource
				if (StandardLib.compare(this.dataSource, _descendant.dataSource) != 0)
					return null;
				
				// if this node has idFields, make sure the id values match those of the descendant
				if (this.idFields && this.data && _descendant.data)
					for each (var field:String in this.idFields)
						if (this.data[field] != _descendant.data[field])
							return null;
			}
			
			// finally, check each child
			for each (var child:IWeaveTreeNode in this.getChildren())
			{
				var path:Array = HierarchyUtils.findPathToNode(child, descendant);
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
