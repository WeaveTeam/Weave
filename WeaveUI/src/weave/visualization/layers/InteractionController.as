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
	import weave.api.getCallbackCollection;
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
		
		public const probe:LinkableValueList 				= newLinkableChild(this, LinkableValueList,invalidateEventCache);
		public const select:LinkableValueList 				= newLinkableChild(this, LinkableValueList,invalidateEventCache);
		public const selectRemove:LinkableValueList 		= newLinkableChild(this, LinkableValueList,invalidateEventCache);
		public const selectAdd:LinkableValueList 			= newLinkableChild(this, LinkableValueList,invalidateEventCache);
		public const pan:LinkableValueList 					= newLinkableChild(this, LinkableValueList,invalidateEventCache);
		public const zoom:LinkableValueList 				= newLinkableChild(this, LinkableValueList,invalidateEventCache);
		public const zoomIn:LinkableValueList 				= newLinkableChild(this, LinkableValueList,invalidateEventCache);
		public const zoomOut:LinkableValueList 				= newLinkableChild(this, LinkableValueList,invalidateEventCache);
		public const zoomToExtent:LinkableValueList 		= newLinkableChild(this, LinkableValueList,invalidateEventCache);
		
		private var _eventActionCache:Dictionary = new Dictionary(true);
		private var keyboardEventCache:Dictionary;
		private var _validateCache:Boolean = false;
		
		private function invalidateEventCache():void
		{
			_validateCache = true;
		}
		
		public function determineAction(optionalString:String = null):String
		{
			if(_validateCache)
			{
				cacheEventActions();
				cacheKeyboardEvents();				
			}
			if(optionalString)
			{
				return _eventActionCache[optionalString];
			}
			_events = _events.sort();		
			return _eventActionCache[String(_events)];
		}
		
		public function determineMouseMode():String
		{
			if(!keyboardEventCache)
				cacheKeyboardEvents();
			_keyboardEvents = _keyboardEvents.sort();
			var mode:String = keyboardEventCache[_keyboardEvents.toString()];
			if(!mode)
				cacheKeyboardEvents();
			return mode;
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
			_validateCache = false;
		}		
		  
		private function cacheKeyboardEvents():void
		{
			keyboardEventCache = new Dictionary(true);			
			for each( var s:LinkableValueList in [pan, probe, select, selectAdd, selectRemove, zoom])
			{
				var e:Array = s.sortedValue.split(",");
				removeElements(e, [CLICK, DRAG, DCLICK, MOVE]);
				keyboardEventCache[String(e)] = determineAction(s.sortedValue);
			}
			_validateCache = false;
		}
		
		private var _events:Array = [];
		private var _keyboardEvents:Array = [];
		
		public function clearEvents():void
		{
			_events = [];
		}
		
		public function insertEvent(event:String):void
		{
			insert(_events, event);
		}
		
		public function clearKeyboardEvents():void
		{
			_keyboardEvents = [];
		}
		
		public function insertKeyboardEvent(event:String):void
		{
			insert(_keyboardEvents, event);
		}
		
		public function removeKeyboardEvents(event:String, ...moreEvents):void
		{
			moreEvents.unshift(event);
			removeElements( _keyboardEvents, moreEvents);
		}
				
		private function insert(array:Array, event:String):void
		{
			if(!array) 
				return;
			
			array.push(event);
			array = array.filter(function(e:String,i:int,a:Array):Boolean {return a.indexOf(e) == i;});			
		}
		
		private function removeElements(array:Array, events:Array):void
		{			
			for each(var str:String in events)
			{
				var i:int = array.indexOf(str);
				if(i != -1)
					array.splice(i, 1);
			}
		}			
	}
}
