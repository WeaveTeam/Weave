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
    import weave.api.data.ColumnMetadata;
    import weave.api.data.IColumnReference;
    import weave.api.data.IDataSource;
    import weave.api.data.IWeaveTreeNode;
    import weave.api.getCallbackCollection;
    import weave.compiler.StandardLib;
    import weave.primitives.WeaveTreeItem;

	/**
	 * The following properties are used for equality comparison:<br>
	 * <code>source, data, columnMetadata, idFields</code><br>
	 * The following properties are used by ColumnTreeNode but not for equality comparison:<br>
	 * <code>label, children, isBranch, hasChildBranches</code><br>
	 */
	[RemoteClass] public class ColumnTreeNode extends WeaveTreeItem implements IWeaveTreeNode, IColumnReference
	{
		/**
		 * The following properties are used for equality comparison:<br>
		 * <code>source, data, columnMetadata, idFields</code><br>
		 * The following properties are used by ColumnTreeNode but not for equality comparison:<br>
		 * <code>label, children, isBranch, hasChildBranches</code><br>
		 */
		public function ColumnTreeNode(params:Object)
		{
			childItemClass = ColumnTreeNode;
			
			if (params is String)
			{
				this.label = params;
			}
			else
			{
				for (var key:String in params)
				{
					if (this[key] is Function && this.hasOwnProperty('_' + key))
						this['_' + key] = params[key];
					else
						this[key] = params[key];
				}
			}
		}
		
		/**
		 * A pointer to the IDataSource that created this node.
		 */
		public var source:IDataSource = null;
		
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
		public var _isBranch:* = null;
		
		/**
		 * Set this to true if this node is a branch, or false if it is not.
		 * Otherwise, hasChildBranches() will check getChildren() and isBranch() on each child.
		 */
		public var _hasChildBranches:* = null;

		/**
		 * Cached values that get invalidated when the source triggers callbacks.
		 */
		private var _cache:Object = {};
		
		/**
		 * Cached values of getCallbackCollection(source).triggerCounter.
		 */
		private var _counter:Object = {};
		
		/**
		 * Checks if cached value is valid.
		 */
		private function isCached(id:String):Boolean
		{
			return _counter[id] == getCallbackCollection(source).triggerCounter;
		}
		
		/**
		 * Updates _cache[id] and _counter[id] and returns the value.
		 */
		private function cache(id:String, value:Object):*
		{
			_counter[id] = getCallbackCollection(source).triggerCounter;
			return _cache[id] = value;
		}
		
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
		 * Compares source, isColumn, data, and columnMetadata.
		 * @inheritDoc
		 */
		public function equals(other:IWeaveTreeNode):Boolean
		{
			var that:ColumnTreeNode = other as ColumnTreeNode;
			if (!that)
				return other.equals(this);
			
			// compare source
			if (this.source != that.source)
				return false; // source differs
			
			// compare data
			if (StandardLib.compareDynamicObjects(this.data, that.data) != 0)
				return false; // data differs
			
			// compare idFields
			if (StandardLib.arrayCompare(this.idFields, that.idFields) != 0)
				return false; // idFields differs
			
			// compare columnMetadata
			if (this.columnMetadata == that.columnMetadata)
				return true; // columnMetadata equal or both null
			if (!this.columnMetadata || !that.columnMetadata)
				return false; // columnMetadata differs
			if (this.idFields) // partial columnMetadata comparison
			{
				for each (var field:String in idFields)
					if (StandardLib.compareDynamicObjects(this.columnMetadata[field], that.columnMetadata[field]) != 0)
						return false; // columnMetadata differs
				return true; // columnMetadata equivalent
			}
			else // full columnMetadata comparison
				return StandardLib.compareDynamicObjects(this.columnMetadata, that.columnMetadata) == 0;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getLabel():String
		{
			const id:String = 'getLabel';
			if (isCached(id))
				return _cache[id];
			
			return cache(id, label);
		}
		
		/**
		 * @inheritDoc
		 */
		public function isBranch():Boolean
		{
			const id:String = 'isBranch';
			if (isCached(id))
				return _cache[id];
			
			if (_isBranch != null)
				return cache(id, getBoolean(_isBranch, '_isBranch'));
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
				return _cache[id];
			
			if (_hasChildBranches != null)
				return cache(id, getBoolean(_hasChildBranches, '_hasChildBranches'));
			
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
			const id:String = 'getChildren';
			if (isCached(id))
				return _cache[id];
			
			return cache(id, children);
		}
		
		/**
		 * @inheritDoc
		 */
		public function getDataSource():IDataSource
		{
			return source;
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
