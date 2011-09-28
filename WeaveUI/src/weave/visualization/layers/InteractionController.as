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
	import weave.core.LinkableString;

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
		
		public const probe:LinkableString 				= newLinkableChild(this, LinkableString,invalidateEvents);
		public const select:LinkableString 				= newLinkableChild(this, LinkableString,invalidateEvents);
		public const selectRemove:LinkableString 		= newLinkableChild(this, LinkableString,invalidateEvents);
		public const selectAdd:LinkableString 			= newLinkableChild(this, LinkableString,invalidateEvents);
		public const pan:LinkableString 				= newLinkableChild(this, LinkableString,invalidateEvents);
		public const zoom:LinkableString 				= newLinkableChild(this, LinkableString,invalidateEvents);
		public const zoomIn:LinkableString 				= newLinkableChild(this, LinkableString,invalidateEvents);
		public const zoomOut:LinkableString 			= newLinkableChild(this, LinkableString,invalidateEvents);
		public const zoomToExtent:LinkableString 		= newLinkableChild(this, LinkableString,invalidateEvents);
		
		private var _sortedValues:Dictionary = new Dictionary(true);
		private const whitespace:RegExp = new RegExp("\s") ;
		
		private function cacheSortedValues():void
		{
			_sortedValues = new Dictionary(true);
			var array:Array = [];
			for each( var s:LinkableString in [probe, select, selectRemove, selectAdd, pan, zoom, zoomIn, zoomOut, zoomToExtent])
			{
				var str:String = s.value;
				if(!str)
				{
					_sortedValues[s] = str;
					continue;
				}
				// remove spaces from string
				array = str.split(" ");
				str = array.join("");
				
				// use commas as delimeters between event strings
				array = str.split(",");
				array = array.sort();
				_sortedValues[s] = array.toString();
			}
		}
		
		
		private var _eventActionCache:Dictionary = new Dictionary(true);
		private var keyboardEventCache:Dictionary;
		private var _validateCache:Boolean = false;
		
		private function invalidateEvents():void
		{
			_validateCache = true;
			cacheSortedValues();
		}
		
		/**
		 * Determine current mouse action from values in internal list of mouse events
		 * @param optionalString optional parameter to use instead of internal list
		 * @return returns a string representing current mouse action to execute
		 * 
		 */		
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
		
		/**
		 * Determine current mouse cursor mode from values in internal list of keyboard events
		 * @return returns a string representing which mouse cursor to use
		 */
		public function determineMouseMode():String
		{
			if (!keyboardEventCache)
				cacheKeyboardEvents();
			_keyboardEvents = _keyboardEvents.sort();
			var mode:String = keyboardEventCache[_keyboardEvents.toString()];
			if (!mode)
				cacheKeyboardEvents();
			return mode;
		}
		
		private function cacheEventActions():void
		{
			_eventActionCache = new Dictionary(true);
			
			_eventActionCache[_sortedValues[probe]] = PROBE;
			_eventActionCache[_sortedValues[select]] = SELECT;
			_eventActionCache[_sortedValues[selectRemove]] = SELECT_REMOVE;
			_eventActionCache[_sortedValues[selectAdd]] = SELECT_ADD;
			_eventActionCache[_sortedValues[pan]] = PAN;
			_eventActionCache[_sortedValues[zoom]] = ZOOM;
			_eventActionCache[_sortedValues[zoomIn]] = ZOOM_IN;
			_eventActionCache[_sortedValues[zoomOut]] = ZOOM_OUT;
			_eventActionCache[_sortedValues[zoomToExtent]] = ZOOM_TO_EXTENT;
			_validateCache = false;
		}		
		  
		private function cacheKeyboardEvents():void
		{
			keyboardEventCache = new Dictionary(true);			
			for each( var s:LinkableString in [pan, probe, select, selectAdd, selectRemove, zoom])
			{
				var e:Array = _sortedValues[s].split(",");
				removeElements(e, [CLICK, DRAG, DCLICK, MOVE]);
				keyboardEventCache[String(e)] = determineAction(_sortedValues[s]);
			}
			_validateCache = false;
		}
		
		private var _events:Array = [];
		private var _keyboardEvents:Array = [];
		
		/**
		 * Clears internal list of mouse events
		 */		
		public function clearEvents():void
		{
			_events = [];
		}
		
		/**
		 * Inserts a mouse event to list of events 
		 * @param event string representing mouse event
		 */		
		public function insertEvent(event:String):void
		{
			insert(_events, event);
		}
		
		/**
		 * Clears internal list of keyboard events
		 */		
		public function clearKeyboardEvents():void
		{
			_keyboardEvents = [];
		}
		
		/**
		 * Inserts a keyboard event to internal list of keyboard events
		 * @param event string representing keyboard event or modifier key(s) pressed
		 */		
		public function insertKeyboardEvent(event:String):void
		{
			insert(_keyboardEvents, event);
		}
		
		/**
		 * Removes elements specified from internal list of keyboard events 
		 * @param event first event to remove
		 * @param moreEvents optional additional events to remove
		 */		
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
