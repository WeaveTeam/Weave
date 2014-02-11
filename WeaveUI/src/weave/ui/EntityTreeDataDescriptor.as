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
package weave.ui
{
    import flash.utils.Dictionary;
    
    import mx.collections.ArrayCollection;
    import mx.collections.ICollectionView;
    import mx.controls.treeClasses.ITreeDataDescriptor;
    
    import weave.api.data.IEntityTreeNode;
    
	/**
	 * Tells a Tree control how to work with IEntityTreeNode objects.
	 * 
	 * @author adufilie
	 */
    public class EntityTreeDataDescriptor implements ITreeDataDescriptor
    {
		public static const FILTER_MODE_ALL:uint = 0;
		public static const FILTER_MODE_BRANCHES:uint = 1;
		public static const FILTER_MODE_LEAVES:uint = 2;
		
		/**
		 * @param filterMode One of [FILTER_MODE_ALL, FILTER_MODE_BRANCHES, FILTER_MODE_LEAVES]. Default is FILTER_MODE_ALL.
		 */
		public function EntityTreeDataDescriptor(filterMode:uint = 0)
		{
			this._filterMode = filterMode;
		}
		
		private var _childViews:Dictionary = new Dictionary(true);
		private var _filterMode:uint;
		private function filterChildren(node:IEntityTreeNode):Boolean
		{
			if (_filterMode == FILTER_MODE_ALL)
				return true;
			return (_filterMode == FILTER_MODE_BRANCHES) == node.isBranch();
		}
		
		//weave.path('ct').libs('weave.api.WeaveAPI').request('CustomTool').push('children','tree').request('EntityHierarchySelector').exec("percentWidth=percentHeight=100;")
		
        public function getChildren(node:Object, model:Object = null):ICollectionView
        {
			var childArray:Array = (node as IEntityTreeNode).getChildren();
			if (!childArray)
				return null;
			
			var childView:ArrayCollection = _childViews[node] as ArrayCollection;
			if (!childView)
				_childViews[node] = childView = new ArrayCollection();
			
			if (childView.source != childArray)
				childView.source = childArray;
			
			if (_filterMode != FILTER_MODE_ALL)
			{
				if (childView.filterFunction != filterChildren)
					childView.filterFunction = filterChildren;
				childView.refresh();
			}
			
			return childView;
        }
        
		public function hasChildren(node:Object, model:Object = null):Boolean
        {
			// When we're not filtering anything, always behave as if branches have children
			// so the "expand" arrow icon always shows.
			// This allows dragging items into an empty branch.
			// When we're filtering, we assume we won't be modifying the hierarchy.
			if (_filterMode == FILTER_MODE_ALL)
				return isBranch(node, model);
			
			return (_filterMode == FILTER_MODE_BRANCHES)
				&& (node as IEntityTreeNode).hasChildBranches();
		}
		
		public function isBranch(node:Object, model:Object = null):Boolean
        {
			return (node as IEntityTreeNode).isBranch();
        }
		
		/**
		 * A non-op which returns a pointer to the node.
		 * @param node
		 * @param model
		 * @return The node itself. 
		 */		
        public function getData(node:Object, model:Object = null):Object
        {
			return node as IEntityTreeNode;
        }
        
		public function addChildAt(parent:Object, newChild:Object, index:int, model:Object = null):Boolean
        {
			var parentNode:IEntityTreeNode = parent as IEntityTreeNode;
			var childNode:IEntityTreeNode = newChild as IEntityTreeNode;
			if (parentNode && childNode)
				return parentNode.addChildAt(childNode, index);
			return false;
        }
        
		public function removeChildAt(parent:Object, child:Object, index:int, model:Object = null):Boolean
        {
			var parentNode:IEntityTreeNode = parent as IEntityTreeNode;
			var childNode:IEntityTreeNode = child as IEntityTreeNode;
			if (parentNode && childNode)
				return parentNode.removeChild(childNode);
			return false;
        }
    }
}
