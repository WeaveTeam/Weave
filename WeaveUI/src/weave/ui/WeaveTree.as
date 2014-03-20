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
			getCallbackCollection(this).addImmediateCallback(this, EventUtils.generateDelayedCallback(this, refresh, 100), true);
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
		
		public function set rootNode(node:IWeaveTreeNode):void
		{
			dataProvider = _rootNode = node;
		}
		
		public function get rootNode():IWeaveTreeNode
		{
			return _rootNode;
		}
		
		override mx_internal function addChildItem(parent:Object, child:Object, index:Number):Boolean
		{
			if (parent == null)
				parent = _rootNode;
			return super.addChildItem(parent, child, index);
		}
		
		override mx_internal function removeChildItem(parent:Object, child:Object, index:Number):Boolean
		{
			if (parent == null)
				parent = _rootNode;
			return super.removeChildItem(parent, child, index);
		}
		
		public function refresh():void
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
    }
}
