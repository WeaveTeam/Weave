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
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	
	import mx.collections.ICollectionView;
	import mx.collections.IViewCursor;
	import mx.controls.Tree;
	import mx.controls.listClasses.IListItemRenderer;
	import mx.controls.treeClasses.TreeListData;
	import mx.core.ScrollPolicy;
	import mx.core.mx_internal;
	import mx.events.ListEvent;
	import mx.utils.ObjectUtil;
	
	import weave.utils.EventUtils;
	
	use namespace mx_internal;
	
	/**
	 * This class features:<br>
	 * - correctly behaving auto scroll policy and scrollToIndex()<br>
	 * - fixes folder arrow visibility bug<br>
	 * - useful functions like refreshDataProvider()
	 * @author adufilie
	 */
	public class CustomTree extends Tree
	{
		[Bindable] public var highlightedItems:Array = [];
		
		public function CustomTree()
		{
			super();
			addEventListener("scroll", updateHScrollLater);
		}
		
		override public function set showRoot(value:Boolean):void
		{
			super.showRoot = value;
			if (value && _rootItem)
			{
				commitProperties();
				expandItem(_rootItem, true);
			}
		}
		
		override protected function addDragData(dragSource:Object):void
		{
			dragSource.addHandler(copySelectedItems, "items");
			super.addDragData(dragSource);
		}
		
		override protected function initListData(item:Object, treeListData:TreeListData):void
		{
			super.initListData(item, treeListData);

			// this makes the folder arrow hide when there are no children
			// This is a bug fix - Tree is supposed to do this but instead it uses isBranch()
			treeListData.hasChildren = item != null && _dataDescriptor.hasChildren(item, iterator.view);
		}
		
		///////////////////////////////////////////////////////////////////////////////
		// solution for automatic maxHorizontalScrollPosition calculation
		// modified from http://www.frishy.com/2007/09/autoscrolling-for-flex-tree/
		
		// we need to override maxHorizontalScrollPosition because setting
		// Tree's maxHorizontalScrollPosition adds an indent value to it,
		// which we don't need as measureWidthOfItems seems to return exactly
		// what we need.  Not only that, but getIndent() seems to be broken
		// anyways (SDK-12578).
		
		// I hate using mx_internal stuff, but we can't do
		// super.super.maxHorizontalScrollPosition in AS 3, so we have to
		// emulate it.
		override public function get maxHorizontalScrollPosition():Number
		{
			if (isNaN(mx_internal::_maxHorizontalScrollPosition))
				return 0;
			
			return mx_internal::_maxHorizontalScrollPosition;
		}
		
		override public function set maxHorizontalScrollPosition(value:Number):void
		{
			if (ObjectUtil.numericCompare(mx_internal::_maxHorizontalScrollPosition, value) != 0)
			{
				mx_internal::_maxHorizontalScrollPosition = value;
				dispatchEvent(new Event("maxHorizontalScrollPositionChanged"));
				
				scrollAreaChanged = true;
				invalidateDisplayList();
			}
		}
		
		private const updateHScrollLater:Function = EventUtils.generateDelayedCallback(this, updateHScrollNow, 0);
		
		private function updateHScrollNow():void
		{
			// we call measureWidthOfItems to get the max width of the item renderers.
			// then we see how much space we need to scroll, setting maxHorizontalScrollPosition appropriately
			var widthOfVisibleItems:int = measureWidthOfItems(verticalScrollPosition - offscreenExtraRowsTop, listItems.length);
			var maxHSP:Number = widthOfVisibleItems - (unscaledWidth - viewMetrics.left - viewMetrics.right);
			
			var hspolicy:String = ScrollPolicy.ON;
			if (maxHSP <= 0)
			{
				maxHSP = 0;
				horizontalScrollPosition = 0;
				
				// horizontal scroll is kept on except when there is no vertical scroll
				// this avoids an infinite hide/show loop where hiding/showing the h-scroll bar affects the max h-scroll value
				if (maxVerticalScrollPosition == 0)
					hspolicy = ScrollPolicy.OFF;
			}
			
			maxHorizontalScrollPosition = maxHSP;
			
			if (horizontalScrollPolicy != hspolicy)
				horizontalScrollPolicy = hspolicy;
		}
		
		/**
		 * This will expand all matching items in the collection.
		 * @param itemTest A function to test for a matching item:  function(item:Object):Boolean
		 * @param open Parameter for expandItem().
		 */
		public function expandMatchingItems(itemTest:Function, open:Boolean = true):void
		{
			if (!collection || !collection.length)
				return;
			var cursor:IViewCursor = collection.createCursor();
			do
			{
				if (itemTest(cursor.current))
					expandItem(cursor.current, open);
			}
			while (cursor.moveNext());
		}
		
		/**
		 * Gets children of an item using the dataDescriptor.
		 */
		public function getChildren(item:Object):ICollectionView
		{
			if (!item)
				return null;
			// iterator could be null if dataProvider has not been set yet.
			if (!iterator)
			{
				dataProvider = [];
				iterator = _rootModel.createCursor();
			}
			return _dataDescriptor.getChildren(item, iterator.view);
		}
		
		public function scrollToSelectedItem():void
		{
			scrollToAndSelectMatchingItem(selectedItem);
		}
		
		/**
		 * @param itemOrTestFunction Either an item or a function to test for a matching item:  function(item:Object):Boolean
		 * @return The matching item, if found.
		 */		
		public function scrollToAndSelectMatchingItem(itemOrTestFunction:Object):Object
		{
			if (!collection || !collection.length)
				return null;
			
			if (itemOrTestFunction == null)
			{
				if (selectedItem)
					selectedItem = null;
				return null;
			}
			
			var i:int = 0;
			var cursor:IViewCursor = collection.createCursor();
			var useBasicEqualityTest:Boolean = itemOrTestFunction == selectedItem || selectedItemsCompareFunction == null;
			do
			{
				if (useBasicEqualityTest
					? cursor.current == itemOrTestFunction
					: (itemOrTestFunction is Function
						? (itemOrTestFunction as Function)(cursor.current)
						: selectedItemsCompareFunction(cursor.current, itemOrTestFunction)))
				{
					// set selection before scrollToIndex() or it won't scroll
					if (selectedItem != cursor.current)
						selectedItem = cursor.current;
					scrollToIndex(i);
					return cursor.current;
				}
				i++;
			}
			while (cursor.moveNext());
			
			// no selection
			selectedItems = [];
			return null;
		}
		
		///////////////////////////////////////////////////////////////////////////////
		// solution for display bugs when hierarchical data changes
		
		private var _dataProvider:Object; // remembers previous value that was passed to "set dataProvider"
		private var _rootItem:Object;
		
		override public function set dataProvider(value:Object):void
		{
			_dataProvider = value;
			super.dataProvider = value;
			_rootItem = mx_internal::_hasRoot ? mx_internal::_rootModel.createCursor().current : null;
		}
		
		/**
		 * This function must be called whenever the hierarchical data changes.
		 * Otherwise, the Tree will not display properly.
		 * @param newDataProvider Optionally specifies a new dataProvider.  If not specified, previous dataProvider will be used.
		 */
		public function refreshDataProvider(newDataProvider:Object = null):void
		{
			var _firstVisibleItem:Object = firstVisibleItem;
			var _selectedItems:Array = selectedItems;
			var _openItems:Array = openItems.concat();
			
			// use value previously passed to "set dataProvider" in order to create a new collection wrapper.
			dataProvider = newDataProvider || _dataProvider;
			// commitProperties() behaves as desired when both dataProvider and openItems are set.
			openItems = _openItems;
			
			validateNow(); // necessary in order to select previous items and scroll back to the correct position
			
			if (showRoot || _firstVisibleItem != _rootItem)
			{
				// scroll to the previous item, but only if it is within scroll range
				var vsp:int = getItemIndex(_firstVisibleItem);
				if (vsp >= 0 && vsp <= maxVerticalScrollPosition)
					firstVisibleItem = _firstVisibleItem;
			}
			
			// selectedItems must be set last to avoid a bug where the Tree scrolls to the top.
			selectedItems = _selectedItems;
		}
		
		/**
		 * This contains a workaround for a problem in List.configureScrollBars relying on a non-working function CursorBookmark.getViewIndex().
		 * This fixes the bug where the tree would scroll all the way from the bottom to the top when a node is collapsed. 
		 */
		override protected function configureScrollBars():void
		{
			var ac:ICollectionView = actualCollection;
			var ai:IViewCursor = actualIterator;
			var rda:Boolean = runningDataEffect;
			
			runningDataEffect = true;
			actualCollection = ac || collection;
			actualIterator = ai || iterator;
			
			// This is not a perfect scrolling solution.  It looks ok when there is a partial row showing at the bottom.
			var mvsp:int = actualCollection ? Math.max(0, actualCollection.length - listItems.length + 1) : 0;
			if (verticalScrollPosition > mvsp)
				verticalScrollPosition = mvsp;
			
			super.configureScrollBars();
			
			runningDataEffect = rda;
			actualCollection = ac;
			actualIterator = ai;
		}
		
		

		protected function drawHighlightedItems():void
		{

		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			updateHScrollLater();
			
			// If showRoot is false and root is showing, force commitProperties() to fix the problem.
			// This workaround requires that the data descriptor reports that the root item is a branch and it has children, even if it doesn't.
			if (!showRoot && _rootItem && itemToItemRenderer(_rootItem))
			{
				mx_internal::showRootChanged = true;
				commitProperties();
			}
			
			// "iterator" is a HierarchicalViewCursor, and its movePrevious()/moveNext()/seek() functions do not work if "current" is null.
			// Calling refreshDataProvider() returns the tree to a working state.
			if (iterator && iterator.current == null && firstVisibleItem != null)
				refreshDataProvider();
			
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}

		public function drawItemForced(item:Object,
 										selected:Boolean = false,
 										highlighted:Boolean = false,
 										caret:Boolean = false,
 										transition:Boolean = false):void
		{
			var renderer:IListItemRenderer = itemToItemRenderer(item);
			drawItem(renderer, selected, highlighted, caret, transition);
		}

			

		private var _pendingScrollToIndex:int = -1;
		override public function scrollToIndex(index:int):Boolean
		{
			if (index < -1)
			{
				index /= -2;
				if (index != _pendingScrollToIndex)
				{
					_pendingScrollToIndex = -1;
					return false;
				}
			}
			_pendingScrollToIndex = -1;
			
			if (maxVerticalScrollPosition == 0 && index > 0)
			{
				_pendingScrollToIndex = index;
				callLater(scrollToIndex, [index * -2]);
				return false;
			}
			
			return super.scrollToIndex(index);
		}

		override protected function keyDownHandler(event:KeyboardEvent):void
		{
			if (!event.isDefaultPrevented())
				super.keyDownHandler(event);
		}
		
		/**
		 * Enables click-to-expand and double-click-to-collapse.
		 * @param singleClickExpands If set to false, double-click is required to expand a branch.
		 */
		public function enableClickToExpand(singleClickExpands:Boolean = true):void
		{
			if (singleClickExpands)
				this.addEventListener(ListEvent.ITEM_CLICK, handleClickExpand);
			doubleClickEnabled = true;
			this.addEventListener(ListEvent.ITEM_DOUBLE_CLICK, handleDoubleClickExpand);
		}
		private var _preMouseDownSelectedItem:*; // remembers the selectedItem before mouseDown occurred
		override protected function mouseDownHandler(event:MouseEvent):void
		{
			// remember which item was selected prior to mouseDown
			_preMouseDownSelectedItem = selectedItem;
			super.mouseDownHandler(event);
		}
		private function handleClickExpand(event:ListEvent):void
		{
			var item:* = event.itemRenderer ? event.itemRenderer.data : null;
			// only expand if this item was not selected prior to mouseDown
			if (item && item != _preMouseDownSelectedItem
				&& dataDescriptor.isBranch(item, iterator.view)
				&& dataDescriptor.hasChildren(item, iterator.view))
				expandItem(item, true);
		}
		private function handleDoubleClickExpand(event:ListEvent):void
		{
			var item:* = event.itemRenderer ? event.itemRenderer.data : null;
			// Toggle expanded state.
			// Note that this will toggle the folder icon whether or not the node has children.
			// Also note that the same behavior occurs when using the left and right arrow keys.
			if (item && dataDescriptor.isBranch(item, iterator.view))
				expandItem(item, !isItemOpen(item));
		}
	}
}
