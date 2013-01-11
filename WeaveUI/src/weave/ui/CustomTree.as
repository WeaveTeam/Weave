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
	
	import mx.collections.ICollectionView;
	import mx.collections.IList;
	import mx.collections.IViewCursor;
	import mx.controls.Tree;
	import mx.core.ScrollPolicy;
	import mx.core.mx_internal;
	import mx.utils.ObjectUtil;
	
	import weave.utils.EventUtils;
	
	/**
	 * This class features a correctly behaving auto horizontal scroll policy.
	 * @author adufilie
	 */	
	public class CustomTree extends Tree
	{
		public function CustomTree()
		{
			super();
			addEventListener("scroll", updateHScrollLater);
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
		 */
		public function refreshDataProvider():void
		{
			var _firstVisibleItem:Object = firstVisibleItem;
			var _selectedItems:Array = selectedItems;
			var _openItems:Array = openItems.concat();
			
			// use value previously passed to "set dataProvider" in order to create a new collection wrapper.
			dataProvider = _dataProvider;
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
			actualCollection = ac || collection; // avoids null pointer error
			actualIterator = ai || iterator;
			
			// This is not a perfect scrolling solution.  It looks ok when there is a partial row showing at the bottom.
			var mvsp:int = Math.max(0, collection.length - listItems.length + 1);
			if (verticalScrollPosition > mvsp)
				verticalScrollPosition = mvsp;
			
			super.configureScrollBars();
			
			runningDataEffect = rda;
			actualCollection = ac;
			actualIterator = ai;
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
			if (iterator && iterator.current == null)
				refreshDataProvider();
			
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
	}
}