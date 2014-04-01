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
	import flash.events.ContextMenuEvent;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.core.mx_internal;
	import mx.events.ListEvent;
	
	import weave.api.core.ILinkableObject;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.data.IWeaveTreeNodeWithPathFinding;
	import weave.api.getCallbackCollection;
	import weave.utils.EventUtils;
	import weave.utils.VectorUtils;
	
	use namespace mx_internal;
	
	/**
	 * This tree will display a hierarchy comprised of IWeaveTreeNode objects.
	 * To make this tree automatically refresh, register dependencies of the
	 * rootNode as linkable children of the WeaveTree.
	 * 
	 * @author adufilie
	 */
    public class WeaveTree extends CustomTree implements ILinkableObject
    {
		public function WeaveTree()
		{
			setStyle('openDuration', 0);
			dragEnabled = true;
			allowMultipleSelection = true;
			showRoot = false;
		}
		
		override protected function childrenCreated():void
		{
			super.childrenCreated();
			
			dataDescriptor = new WeaveTreeDataDescriptor();
			getCallbackCollection(this).addImmediateCallback(this, delayedRefresh, true);
			labelFunction = getNodeLabel;
			dataTipFunction = getNodeLabel;
			selectedItemsCompareFunction = compareNodes;
		}
		
		private function compareNodes(a:IWeaveTreeNode, b:IWeaveTreeNode):Boolean
		{
			return a == b || a.equals(b);
		}
		
		private function getNodeLabel(node:IWeaveTreeNode):String
		{
			return node.getLabel();
		}
		
		/**
		 * Adds a context menu item "Select all child nodes"
		 */
		public function setupContextMenu():void
		{
			contextMenu = new ContextMenu();
			var selectChildren:ContextMenuItem = new ContextMenuItem("Select all child nodes");
			contextMenu.customItems = [selectChildren];
			contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, function(event:*):void {
				var node:IWeaveTreeNode = selectedItem as IWeaveTreeNode;
				selectChildren.enabled = node && node.isBranch() && node.getChildren() && node.getChildren().length;
			});
			selectChildren.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(event:*):void {
				selectedItems = VectorUtils.flatten(selectedItems.map(function(node:IWeaveTreeNode, i:int, a:Array):*{
					expandItem(node, true);
					return node.getChildren() || [];
				}));
				dispatchEvent(new ListEvent(ListEvent.CHANGE));
			});
		}
		
		private var _rootNode:IWeaveTreeNode;
		
		override public function set dataProvider(value:Object):void
		{
			_rootNode = value as IWeaveTreeNode;
			super.dataProvider = value;
		}
		
		/**
		 * This is the root node of the tree.
		 * Setting the rootNode will refresh the tree, even if it's the same object.
		 */
		public function get rootNode():IWeaveTreeNode
		{
			return _rootNode;
		}
		public function set rootNode(node:IWeaveTreeNode):void
		{
			if (_rootNode != node)
				dataProvider = _rootNode = node;
			else
				delayedRefresh();
		}
		
		override mx_internal function addChildItem(parent:Object, child:Object, index:Number):Boolean
		{
			// replace null parent with rootNode
			return super.addChildItem(parent || _rootNode, child, index);
		}
		
		override mx_internal function removeChildItem(parent:Object, child:Object, index:Number):Boolean
		{
			// replace null parent with rootNode
			return super.removeChildItem(parent || _rootNode, child, index);
		}
		
		override public function getParentItem(item:Object):*
		{
			// super.getParentItem() only works if item is currently visible.
			var parent:Object = super.getParentItem(item);
			if (parent)
				return parent;
			
			// if item is not visible, try to find a path to the node
			var path:Array = findPathToNode(_rootNode, item as IWeaveTreeNode);
			if (path)
				return path[path.length - 2]; // the parent is the second-to-last item
			return null;
		}
		
		/**
		 * This will refresh the tree and dispatch a change event.
		 * @param immediately If this is set to true, the table will be refreshed immediately.
		 *                    Otherwise there will be a small delay before the actual refresh happens.
		 */
		public function refresh(immediately:Boolean):void
		{
			if (immediately)
				refreshImmediately();
			else
				delayedRefresh();
		}
		
		private const delayedRefresh:Function = EventUtils.generateDelayedCallback(this, refreshImmediately, 100);
		private function refreshImmediately():void
		{
			// Because we are not rendering the root node, we need to explicitly request the children from
			// the root so that the children will be fetched.
			if (_rootNode)
				_rootNode.getChildren();
			
			refreshDataProvider();
			
			// since this function may be called some time after the EntityCache updates,
			// dispatching an event here allows other code to know when data is actually refreshed
			dispatchEvent(new ListEvent(ListEvent.CHANGE));
		}
		
		/**
		 * Finds a series of IWeaveTreeNode objects which can be traversed as a path to a descendant node.
		 * @param descendant The descendant IWeaveTreeNode.
		 * @return An Array of IWeaveTreeNode objects which can be followed as a path from this node to the descendant, including this node and the descendant node.
		 *         Returns null if the descendant is unreachable from this node.
		 */
		public static function findPathToNode(root:IWeaveTreeNode, descendant:IWeaveTreeNode):Array
		{
			if (!root)
				return null;
			
			if (root == descendant)
				return [root];
			var path:Array;
			for each (var child:IWeaveTreeNode in root.getChildren())
			{
				if (child is IWeaveTreeNodeWithPathFinding)
					path = (child as IWeaveTreeNodeWithPathFinding).findPathToNode(descendant);
				else
					path = findPathToNode(child, descendant);
				if (path)
				{
					path.unshift(child);
					return path;
				}
			}
			return null;
		}
    }
}
