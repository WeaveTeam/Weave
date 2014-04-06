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
	import weave.api.getCallbackCollection;
	import weave.utils.EventUtils;
	import weave.utils.HierarchyUtils;
	import weave.utils.VectorUtils;
	
	use namespace mx_internal;
	
	/**
	 * This tree will display a hierarchy comprised of IWeaveTreeNode objects.
	 * To make this tree automatically refresh, register dependencies of the
	 * rootNode as linkable children of the WeaveTree.
	 * 
	 * The dataDescriptor is an instance of WeaveTreeDataDescriptor.
	 * 
	 * @author adufilie
	 */
    public class WeaveTree extends CustomTree implements ILinkableObject
    {
		public function WeaveTree()
		{
			_dataDescriptor = new WeaveTreeDataDescriptor();
			setStyle('openDuration', 0);
			dragEnabled = true;
			allowMultipleSelection = true;
			showRoot = false;
		}
		
		override protected function childrenCreated():void
		{
			super.childrenCreated();
			
			getCallbackCollection(this).addImmediateCallback(this, delayedRefresh, true);
			labelFunction = getNodeLabel;
			dataTipFunction = getNodeLabel;
			selectedItemsCompareFunction = compareNodes;
		}
		
		/**
		 * The dataDescriptor for this WeaveTree.
		 */
		public function get weaveTreeDataDescriptor():WeaveTreeDataDescriptor
		{
			return _dataDescriptor as WeaveTreeDataDescriptor;
		}
		
		/**
		 * Shortcut for setting weaveTreeDataDescriptor.displayMode
		 * @see #weaveTreeDataDescriptor
		 */
		public function set displayMode(weaveTreeDataDescriptorDisplayMode:int):void
		{
			weaveTreeDataDescriptor.displayMode = weaveTreeDataDescriptorDisplayMode;
		}
		
		/**
		 * Shortcut for setting weaveTreeDataDescriptor.nodeFilter
		 * @see #weaveTreeDataDescriptor
		 */
		public function set nodeFilter(weaveTreeDataDescriptorNodeFilter:Function):void
		{
			weaveTreeDataDescriptor.nodeFilter = weaveTreeDataDescriptorNodeFilter;
		}
		
		private function compareNodes(a:IWeaveTreeNode, b:IWeaveTreeNode):Boolean
		{
			return a == b || a.equals(b);
		}
		
		private function getNodeLabel(node:IWeaveTreeNode):String
		{
			return node.getLabel();
		}
		
		private function getSelectedBranches():Array
		{
			return selectedItems.filter(function(item:*, i:*, a:*):Boolean { return dataDescriptor.isBranch(item, iterator.view); });
		}
		
		/**
		 * Adds a context menu items "Expand" and "Select all child nodes"
		 */
		public function setupContextMenu():void
		{
			contextMenu = new ContextMenu();
			var expandChildren:ContextMenuItem = new ContextMenuItem("Expand");
			var selectChildren:ContextMenuItem = new ContextMenuItem(lang("Select all child nodes"));
			contextMenu.customItems = [expandChildren, selectChildren];
			contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, function(event:*):void {
				var branches:Array = getSelectedBranches();
				selectChildren.enabled = expandChildren.enabled = branches.length > 0;
				expandChildren.caption = lang(isItemOpen(branches.pop()) ? "Collapse" : "Expand");
			});
			expandChildren.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(event:*):void {
				var branches:Array = getSelectedBranches();
				var expand:Boolean = !isItemOpen(branches[branches.length - 1]);
				for each (var item:* in branches)
					expandChildrenOf(item, expand);
			});
			selectChildren.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(event:*):void {
				selectedItems = VectorUtils.flatten(getSelectedBranches().map(function(node:IWeaveTreeNode, i:int, a:Array):*{
					expandItem(node, true);
					return node.getChildren();
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
			var path:Array = HierarchyUtils.findPathToNode(_rootNode, item as IWeaveTreeNode);
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
		
		public function expandPathAndSelectNode(node:IWeaveTreeNode):void
		{
			if (!rootNode)
			{
				// if there is no root node, we assume it's only showing a flat list of leaf nodes
				scrollToAndSelectMatchingItem(node);
				return;
			}
			var path:Array = HierarchyUtils.findPathToNode(rootNode, node);
			if (!path)
				return;
			// expand every node along the path
			for each (node in path)
				if (iterator && dataDescriptor.hasChildren(node, iterator.view))
					expandItem(node, true);
			// select the last item in the path (the equivalent node in the hierarchy)
			scrollToAndSelectMatchingItem(path[path.length - 1]);
			// if the node does not appear in the tree, select its parent instead
			if (!selectedItem)
				scrollToAndSelectMatchingItem(path[path.length - 2]);
		}
    }
}
