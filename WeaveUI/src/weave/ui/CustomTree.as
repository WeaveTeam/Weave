// modified from http://www.frishy.com/2007/09/autoscrolling-for-flex-tree/
package weave.ui
{
	import flash.events.Event;
	
	import mx.collections.IList;
	import mx.controls.Tree;
	import mx.core.ScrollPolicy;
	import mx.core.mx_internal;
	
	import weave.utils.EventUtils;
	
	/**
	 * This class features a correctly behaving auto horizontal scroll policy.
	 */	
	public class CustomTree extends Tree
	{
		public function CustomTree(){
			super();
			horizontalScrollPolicy = ScrollPolicy.AUTO;
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
			if (_scrollInvalid)
			{
				mx_internal::_maxHorizontalScrollPosition = value;
				dispatchEvent(new Event("maxHorizontalScrollPositionChanged"));
				
				scrollAreaChanged = true;
				invalidateDisplayList();
			}
			else
			{
				super.maxHorizontalScrollPosition = value;
				_invalidateScrollLater();
			}
		}
		
		private var _invalidateScrollLater:Function = EventUtils.generateDelayedCallback(this, _invalidateScroll);
		private var _scrollInvalid:Boolean = false;
		private function _invalidateScroll():void
		{
			_scrollInvalid = true;
			invalidateDisplayList();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			if (_scrollInvalid)
			{
				// we call measureWidthOfItems to get the max width of the item renderers.
				// then we see how much space we need to scroll, setting maxHorizontalScrollPosition appropriately
				var diffWidth:Number = /*measureWidthOfItems(0,0)*/measuredWidth - (unscaledWidth - viewMetrics.left - viewMetrics.right);
				
				if (diffWidth <= 0)
					maxHorizontalScrollPosition = NaN;
				else
					maxHorizontalScrollPosition = diffWidth;
				
				_scrollInvalid = false;
			}
			else
			{
				_invalidateScrollLater();
			}
			
			// If showRoot is false and root is showing, force commitProperties() to fix the problem.
			// This workaround requires that the data descriptor reports that the root item is a branch and it has children, even if it doesn't.
			if (!showRoot)
			{
				var rootItem:Object = dataProvider is IList ? (dataProvider as IList).getItemAt(0) : null;
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