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
    import weave.compiler.StandardLib;
    import weave.primitives.WeaveTreeItem;

	/**
	 * A node in a tree whose leaves identify attribute columns.
	 * The following properties are used for equality comparison, in addition to node class definitions:<br>
	 * <code>dataSource, data, idFields, columnMetadata</code><br>
	 * The following properties are used by ColumnTreeNode but not for equality comparison:<br>
	 * <code>label, children, isBranch, hasChildBranches</code><br>
	 */
	[RemoteClass] public class ColumnTreeNode extends WeaveTreeItem implements IWeaveTreeNode, IColumnReference
	{
		/**
		 * This constructor accepts a special parameter named <code>columnMetadata</code> which has
		 * the same effect as including the following parameter-value pairs:
		 *     <code>{isBranch: false, hasChildBranches: false, data: columnMetadata}</code><br>
		 * The following properties are used for equality comparison, in addition to node class definitions:
		 *     <code>dependency, data, dataSource, idFields</code><br>
		 * The following properties are used by ColumnTreeNode but not for equality comparison:
		 *     <code>label, children, isBranch, hasChildBranches</code><br>
		 * @params An values for the properties of this ColumnTreeNode.
		 *         Either the <code>dataSource</code> property or the <code>dependency</code> property must be specified.
		 *         If no <code>dependency</code> property is given, <code>dataSource.hierarchyRefresh</code> will be used as the dependency.
		 */
		public function ColumnTreeNode(params:Object)
		{
			childItemClass = ColumnTreeNode;
			
			for (var key:String in params)
			{
				if (key == 'columnMetadata')
				{
					this._isBranch = false;
					this._hasChildBranches = false;
					this.data = params[key];
				}
				else if (this[key] is Function && this.hasOwnProperty('_' + key))
					this['_' + key] = params[key];
				else
					this[key] = params[key];
			}
			if (!dataSource && !dependency)
				throw new Error('ColumnTreeNode constructor: Either the "dataSource" property or the "dependency" property must be specified');
			if (!dependency)
				dependency = dataSource.hierarchyRefresh;
		}
		
		/**
		 * IDataSource for this node.
		 */
		public var dataSource:IDataSource = null;
		
		/**
		 * A list of columnMetadata fields to use for node equality tests.
		 */
		public var idFields:Array = null;
		
		/**
		 * Set this to true if this node is a branch, or false if it is not.
		 * Otherwise, isBranch() will check getChildren().
		 */
		public function set _isBranch(value:*):void
		{
			_counter['isBranch'] = undefined;
			__isBranch = value;
		}
		private var __isBranch:* = null;
		
		/**
		 * Set this to true if this node is a branch, or false if it is not.
		 * Otherwise, hasChildBranches() will check isBranch() on each child returned by getChildren().
		 */
		public function set _hasChildBranches(value:*):void
		{
			_counter['hasChildBranches'] = undefined;
			__hasChildBranches = value;
		}
		private var __hasChildBranches:* = null;

		/**
		 * If there is no label, this will use columnMetadata['title'] if defined.
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
		 * Compares source, data, idFields, and columnMetadata.
		 * @inheritDoc
		 */
		public function equals(other:IWeaveTreeNode):Boolean
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
		public function getLabel():String
		{
			return label;
		}
		
		/**
		 * @inheritDoc
		 */
		public function isBranch():Boolean
		{
			const id:String = 'isBranch';
			if (isCached(id))
				return cache(id);
			
			if (__isBranch != null)
				return cache(id, getBoolean(__isBranch, id));
			else
				return cache(id, _children != null); // assume that if children property was defined that this is a branch
		}
		
		/**
		 * @inheritDoc
		 */
		public function hasChildBranches():Boolean
		{
			const id:String = 'hasChildBranches';
			if (isCached(id))
				return cache(id);
			
			if (__hasChildBranches != null)
				return cache(id, getBoolean(__hasChildBranches, id));
			
			var children:Array = getChildren();
			for each (var child:IWeaveTreeNode in children)
				if (child.isBranch())
					return cache(id, true);
			return cache(id, false);
		}
		
		/**
		 * @inheritDoc
		 */
		public function getChildren():Array
		{
			return children;
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
	}
}
