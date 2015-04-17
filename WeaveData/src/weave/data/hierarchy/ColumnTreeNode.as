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
	 * The following properties are used for equality comparison, in addition to node class definitions:<br>
	 * <code>source, data, idFields, columnMetadata</code><br>
	 * The following properties are used by ColumnTreeNode but not for equality comparison:<br>
	 * <code>label, children, isBranch, hasChildBranches</code><br>
	 */
	[RemoteClass] public class ColumnTreeNode extends WeaveTreeItem implements IWeaveTreeNode, IColumnReference
	{
		/**
		 * The following properties are used for equality comparison, in addition to node class definitions:<br>
		 * <code>dependency, data, dataSource, idFields, columnMetadata</code><br>
		 * The following properties are used by ColumnTreeNode but not for equality comparison:<br>
		 * <code>label, children, isBranch, hasChildBranches</code><br>
		 * @params An values for the properties of this ColumnTreeNode.
		 *         Either the <code>dataSource</code> property or the <code>dependency</code> property must be specified.
		 *         If no <code>dependency</code> property is given, <code>dataSource.hierarchyRefresh</code> will be used as the dependency.
		 */
		public function ColumnTreeNode(params:Object)
		{
			childItemClass = ColumnTreeNode;
			
			for (var key:String in params)
			{
				if (this[key] is Function && this.hasOwnProperty('_' + key))
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
		 * Column metadata for this node.
		 */
		public var columnMetadata:Object = null;
		
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
			if (!str && columnMetadata)
				str = columnMetadata[ColumnMetadata.TITLE];
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
				return false; // constructors differ
			
			// compare dependency
			if (this.dependency != that.dependency)
				return false; // dependency differs
			
			// compare data
			if (StandardLib.compare(this.data, that.data) != 0)
				return false; // data differs
			
			// compare dataSource
			if (this.dataSource != that.dataSource)
				return false; // dataSource differs
			
			// compare idFields
			if (StandardLib.compare(this.idFields, that.idFields) != 0)
				return false; // idFields differs
			
			// compare columnMetadata
			if (this.columnMetadata == that.columnMetadata)
				return true; // columnMetadata equal or both null
			if (!this.columnMetadata || !that.columnMetadata)
				return false; // columnMetadata differs
			if (this.idFields) // partial columnMetadata comparison
			{
				for each (var field:String in idFields)
					if (StandardLib.compare(this.columnMetadata[field], that.columnMetadata[field]) != 0)
						return false; // columnMetadata differs
				return true; // columnMetadata equivalent
			}
			else // full columnMetadata comparison
				return StandardLib.compare(this.columnMetadata, that.columnMetadata) == 0;
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
				return cache(id, getChildren() != null);
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
			return columnMetadata;
		}
	}
}
