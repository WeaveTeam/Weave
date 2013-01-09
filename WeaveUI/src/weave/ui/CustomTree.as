// modified from http://www.frishy.com/2007/09/autoscrolling-for-flex-tree/
package weave.ui
{
	import flash.events.Event;
	
	import mx.collections.IList;
	import mx.controls.Tree;
	import mx.core.ScrollPolicy;
	import mx.core.mx_internal;
	import mx.utils.ObjectUtil;
	
	import weave.utils.EventUtils;
	
	/**
	 * This class features a correctly behaving auto horizontal scroll policy.
	 */	
	public class CustomTree extends Tree
	{
		public function CustomTree()
		{
			super();
			addEventListener("scroll", updateHScrollLater);
		}
		
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
		
		override protected function seekPositionSafely(index:int):Boolean
		{
			// "iterator" is a HierarchicalViewCursor, and its movePrevious()/moveNext()/seek() functions do not work if "current" is null.
			// To work around the problem, we create a new cursor.
			if (iterator && iterator.current == null)
				iterator = collection.createCursor();
			
			return super.seekPositionSafely(index);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			updateHScrollLater();
			
			// If showRoot is false and root is showing, force commitProperties() to fix the problem.
			// This workaround requires that the data descriptor reports that the root item is a branch and it has children, even if it doesn't.
			if (!showRoot)
			{
				var rootItem:Object = dataProvider is IList && (dataProvider as IList).length > 0 ? (dataProvider as IList).getItemAt(0) : null;
				if (rootItem && itemToItemRenderer(rootItem))
				{
					mx_internal::showRootChanged = true;
					commitProperties();
				}
			}
				
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
	}
}