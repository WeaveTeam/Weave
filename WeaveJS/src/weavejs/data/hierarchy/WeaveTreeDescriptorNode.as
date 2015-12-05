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
    import weavejs.api.data.IWeaveTreeNode;
    import weavejs.utils.JS;
    import weavejs.utils.StandardLib;
    import weavejs.utils.WeaveTreeItem;

	/**
	 * A node in a tree whose leaves identify attribute columns.
	 * The following properties are used for equality comparison, in addition to node class definitions:<br>
	 * <code>dependency, data</code><br>
	 * The following properties are used by WeaveTreeDescriptorNode but not for equality comparison:<br>
	 * <code>label, children, hasChildBranches</code><br>
	 */
	[RemoteClass] public class WeaveTreeDescriptorNode extends WeaveTreeItem implements IWeaveTreeNode
	{
		/**
		 * The following properties are used for equality comparison, in addition to node class definitions:
		 *     <code>dependency, data</code><br>
		 * The following properties are used by WeaveTreeDescriptorNode but not for equality comparison:
		 *     <code>label, children, hasChildBranches</code><br>
		 * @param params An values for the properties of this WeaveTreeDescriptorNode.
		 */
		public function WeaveTreeDescriptorNode(params:Object)
		{
			childItemClass = WeaveTreeDescriptorNode;
			
			for (var key:String in params)
			{
				if (this[key] is Function && JS.hasProperty(this, '_' + key))
					this['_' + key] = params[key];
				else
					this[key] = params[key];
			}
		}
		
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
		 * @inheritDoc
		 */
		public function equals(other:IWeaveTreeNode):Boolean
		{
			var that:WeaveTreeDescriptorNode = other as WeaveTreeDescriptorNode;
			if (!that)
				return false;
			
			// compare constructor
			if (Object(this).constructor != Object(that).constructor)
				return false; // constructor differs
			
			// compare dependency
			if (this.dependency != that.dependency)
				return false; // dependency differs
			
			if (StandardLib.compare(this.data, that.data) != 0)
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
			// assume that if children property was defined that this is a branch
			return _children != null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function hasChildBranches():Boolean
		{
			var id:String = 'hasChildBranches';
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
	}
}
