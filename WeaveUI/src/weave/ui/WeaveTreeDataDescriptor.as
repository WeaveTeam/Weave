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

package weave.ui
{
    import flash.utils.Dictionary;
    
    import mx.collections.ArrayCollection;
    import mx.collections.ICollectionView;
    import mx.controls.treeClasses.ITreeDataDescriptor;
    
    import weave.api.data.IWeaveTreeNode;
    import weave.api.data.IWeaveTreeNodeWithEditableChildren;
    
	/**
	 * Tells a Tree control how to work with IWeaveTreeNode objects.
	 * 
	 * @author adufilie
	 */
    public class WeaveTreeDataDescriptor implements ITreeDataDescriptor
    {
		public static const DISPLAY_MODE_ALL:uint = 0;
		public static const DISPLAY_MODE_BRANCHES:uint = 1;
		public static const DISPLAY_MODE_LEAVES:uint = 2;
		
		public function WeaveTreeDataDescriptor()
		{
		}
		
		/**
		 * One of [DISPLAY_MODE_ALL, DISPLAY_MODE_BRANCHES, DISPLAY_MODE_LEAVES].
		 * Default is DISPLAY_MODE_ALL.
		 */
		public var displayMode:int = DISPLAY_MODE_ALL;
		
		/**
		 * A function like <code>function(node:IWeaveTreeNode):Boolean</code> which filters child nodes.
		 */
		public var nodeFilter:Function = null;
		
		/**
		 * Maps a node to a cached ArrayCollection with the appropriate filterFunction set.
		 */
		private var _childViews:Dictionary = new Dictionary(true);
		
		/**
		 * Used as the filterFunction of ArrayCollections cached in _childViews.
		 */
		private function filterChildren(node:IWeaveTreeNode):Boolean
		{
			if (displayMode == DISPLAY_MODE_BRANCHES && !node.isBranch())
				return false;
			if (displayMode == DISPLAY_MODE_LEAVES && node.isBranch())
				return false;
			return nodeFilter == null || nodeFilter(node);
		}
		
		/**
		 * @inheritDoc
		 */
        public function getChildren(node:Object, model:Object = null):ICollectionView
        {
			var childArray:Array = (node as IWeaveTreeNode).getChildren();
			if (!childArray)
				return null;
			
			var childView:ArrayCollection = _childViews[node] as ArrayCollection;
			if (!childView)
				_childViews[node] = childView = new ArrayCollection();
			
			if (childView.source != childArray)
				childView.source = childArray;
			
			if (displayMode == DISPLAY_MODE_ALL && nodeFilter == null)
			{
				// no filtering
				if (childView.filterFunction != null)
				{
					childView.filterFunction = null;
					childView.refresh();
				}
			}
			else
			{
				// make sure filterFunction is set
				if (childView.filterFunction != filterChildren)
					childView.filterFunction = filterChildren;
				// need to refresh every time children are requested
				childView.refresh();
			}
			
			return childView;
        }
        
		/**
		 * @inheritDoc
		 */
		public function hasChildren(node:Object, model:Object = null):Boolean
        {
			// When we're not filtering anything, always behave as if branches have children
			// so the "expand" arrow icon always shows.
			// This allows dragging items into an empty branch.
			// When we're filtering, we assume we won't be modifying the hierarchy.
			if (displayMode == DISPLAY_MODE_ALL)
				return isBranch(node, model);
			
			return (displayMode == DISPLAY_MODE_BRANCHES)
				&& (node as IWeaveTreeNode).hasChildBranches();
		}
		
		/**
		 * @inheritDoc
		 */
		public function isBranch(node:Object, model:Object = null):Boolean
        {
			return (node as IWeaveTreeNode).isBranch();
        }
		
		/**
		 * A non-op which returns a pointer to the node.
		 * @param node
		 * @param model
		 * @return The node itself. 
		 */		
        public function getData(node:Object, model:Object = null):Object
        {
			return node;
        }
        
		/**
		 * @inheritDoc
		 */
		public function addChildAt(parent:Object, newChild:Object, index:int, model:Object = null):Boolean
        {
			var parentNode:IWeaveTreeNodeWithEditableChildren = parent as IWeaveTreeNodeWithEditableChildren;
			var childNode:IWeaveTreeNode = newChild as IWeaveTreeNode;
			if (parentNode && childNode)
				return parentNode.addChildAt(childNode, index);
			return false;
        }
        
		/**
		 * @inheritDoc
		 */
		public function removeChildAt(parent:Object, child:Object, index:int, model:Object = null):Boolean
        {
			var parentNode:IWeaveTreeNodeWithEditableChildren = parent as IWeaveTreeNodeWithEditableChildren;
			var childNode:IWeaveTreeNode = child as IWeaveTreeNode;
			if (parentNode && childNode)
				return parentNode.removeChild(childNode);
			return false;
        }
    }
}
