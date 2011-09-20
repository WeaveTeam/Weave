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

package weave.visualization.layers
{
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	
	import mx.utils.ObjectUtil;
	
	import weave.api.core.ILinkableObject;
	import weave.api.newLinkableChild;
	import weave.core.LinkableValueList;

	/**
	 * This class handles mouse/keyboard interactions performed within DisplayObjects
	 * 
	 * @author kmanohar
	 */
	public class InteractionController implements ILinkableObject
	{
		public static const DRAG:String = "drag";
		public static const DCLICK:String = "dclick";
		public static const CLICK:String = "click";
		public static const MOVE:String = "move";
		public static const CTRL:String = "ctrl";
		public static const ALT:String = "alt";
		public static const SHIFT:String = "shift";

		public static const PROBE:String = "probe";
		public static const SELECT:String = "select";
		public static const SELECT_ADD:String = "selectAdd";
		public static const SELECT_REMOVE:String = "selectRemove";
		
		public static const PAN:String = "pan";		
		public static const ZOOM:String = "zoom";
		public static const ZOOM_IN:String = "zoomIn";
		public static const ZOOM_OUT:String = "zoomOut";
		public static const ZOOM_TO_EXTENT:String = "zoomToExtent";
	
		public function InteractionController()			
		{
			super();
			
			probe.value = MOVE;
			select.value = [DRAG].toString();
			selectAdd.value = [CTRL, DRAG].toString();
			selectRemove.value = [CTRL, SHIFT, DRAG].toString();
			
			pan.value = [ALT, DRAG].toString();
			zoom.value = [SHIFT, DRAG].toString();
			zoomIn.value = DCLICK;
			zoomOut.value = [SHIFT, DCLICK].toString();
			zoomToExtent.value = [CTRL, ALT, SHIFT, DCLICK].toString();
		}
		
		public const probe:LinkableValueList 				= newLinkableChild(this, LinkableValueList,cacheEventActions, true);
		public const select:LinkableValueList 				= newLinkableChild(this, LinkableValueList,cacheEventActions, true);
		public const selectRemove:LinkableValueList 		= newLinkableChild(this, LinkableValueList,cacheEventActions, true);
		public const selectAdd:LinkableValueList 			= newLinkableChild(this, LinkableValueList,cacheEventActions, true);
		public const pan:LinkableValueList 					= newLinkableChild(this, LinkableValueList,cacheEventActions, true);
		public const zoom:LinkableValueList 				= newLinkableChild(this, LinkableValueList,cacheEventActions, true);
		public const zoomIn:LinkableValueList 				= newLinkableChild(this, LinkableValueList,cacheEventActions, true);
		public const zoomOut:LinkableValueList 				= newLinkableChild(this, LinkableValueList,cacheEventActions, true);
		public const zoomToExtent:LinkableValueList 		= newLinkableChild(this, LinkableValueList,cacheEventActions, true);
		
		private var _eventActionCache:Dictionary = new Dictionary(true);
		
		public function determineAction(events:String):String
		{
			return _eventActionCache[events];
		}
		
		private function cacheEventActions():void
		{
			_eventActionCache = new Dictionary(true);
			
			_eventActionCache[probe.sortedValue] = PROBE;
			_eventActionCache[select.sortedValue] = SELECT;
			_eventActionCache[selectRemove.sortedValue] = SELECT_REMOVE;
			_eventActionCache[selectAdd.sortedValue] = SELECT_ADD;
			_eventActionCache[pan.sortedValue] = PAN;
			_eventActionCache[zoom.sortedValue] = ZOOM;
			_eventActionCache[zoomIn.sortedValue] = ZOOM_IN;
			_eventActionCache[zoomOut.sortedValue] = ZOOM_OUT;
			_eventActionCache[zoomToExtent.sortedValue] = ZOOM_TO_EXTENT;
		}
	}
}
