/*http://flexponential.com/2011/11/10/accordionlist-with-expanding-item-renderers/*/
package weave.ui.infomap.ui
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	
	import mx.core.IVisualElement;
	import mx.core.UIComponent;
	import mx.core.mx_internal;
	import mx.events.ResizeEvent;
	
	import spark.components.List;
	
	use namespace mx_internal;
	
	public class AccordionList extends List
	{    
		public function AccordionList()
		{
			super();
			// Don't use virtual layout so the previously selected item can shrink
			useVirtualLayout = false;
			
			addEventListener("expandEffectStart", item_expandStartHandler, true);
		}
		
		private var expandingItem:EventDispatcher;
		
		// Called when the new selected item is expanding
		// As the resize effect is playing, we want to ensure it is visible in the viewable area
		protected function item_expandStartHandler(event:Event):void
		{
			expandingItem = null;
			
			addEventListener("expandEffectEnd", item_expandEndHandler, true);
			var item:EventDispatcher = event.target as EventDispatcher;
			if (item)
			{
				item.addEventListener(ResizeEvent.RESIZE, item_resizeHandler);
				expandingItem = item;
			}
		}
		
		protected function item_resizeHandler(event:ResizeEvent):void
		{
			var item:IVisualElement = event.target as IVisualElement;
			if (item && layout)
			{ 
				// Find out the delta to ensure the item is fully inside the viewable area
				var delta:Point = layout.getScrollPositionDeltaToAnyElement(item);
				if (delta)
				{   
					var adjustedVSP:Number = dataGroup.verticalScrollPosition + delta.y;
					// Constrain the vsp so it doesn't go beyond 0 or the max scroll position
					dataGroup.verticalScrollPosition = Math.round(Math.min(Math.max(adjustedVSP, 0), maxVerticalScrollPosition));
				}
			}
		}
		
		// The new selected item has stopped expanding. Stop listening to resize
		protected function item_expandEndHandler(event:Event):void
		{
			removeEventListener("expandEffectEnd", item_expandEndHandler, true);
			if (expandingItem)
				expandingItem.removeEventListener(ResizeEvent.RESIZE, item_resizeHandler);
		}
		
		// Helper property to get the maximum allowed vertical scroll position of the Scroller
		private function get maxVerticalScrollPosition():Number
		{
			return scroller.viewport.contentHeight - scroller.viewport.height;
		}
	}
}