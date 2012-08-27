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
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableObject;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.registerDisposableChild;
	import weave.core.LinkableString;

	/**
	 * This class handles mouse/keyboard interactions performed within InteractiveVisualizations
	 * 
	 * @author kmanohar
	 * @author adufilie
	 */
	public class InteractionController implements ILinkableObject
	{
		// mouse events
		public static const MOVE:String = "move";
		public static const DRAG:String = "drag";
		public static const CLICK:String = "click";
		public static const DCLICK:String = "dclick";
		public static const WHEEL:String = "wheel";
		
		private static const MOUSE_EVENTS:Array = [MOVE, DRAG, CLICK, DCLICK, WHEEL];
		
		// modifier keys
		public static const CTRL:String = "ctrl";
		public static const ALT:String = "alt";
		public static const SHIFT:String = "shift";

		// interactions
		public static const PROBE:String = "probe";
		public static const SELECT:String = "select";
		public static const SELECT_ADD:String = "selectAdd";
		public static const SELECT_REMOVE:String = "selectRemove";
		public static const SELECT_ALL:String = "selectAll";
		public static const PAN:String = "pan";
		public static const ZOOM:String = "zoom";
		public static const ZOOM_IN:String = "zoomIn";
		public static const ZOOM_OUT:String = "zoomOut";
		public static const ZOOM_TO_EXTENT:String = "zoomToExtent";
		
		public static const RECTANGLE_SELECTION_MODE = "rectangle";
		public static const CIRCULAR_SELECTION_MODE = "circle";
		public static const LASSO_SELECTION_MODE = "lasso";
		
		
		/**
		 * This is a list of what are considered "modes" that affect what moving the mouse does.
		 * This does not include one-time actions not affected by mouse movements.
		 */		
		private static const INTERACTION_MODES:Array = [PAN, SELECT, SELECT_ADD, SELECT_REMOVE, ZOOM, PROBE];
	
		public function InteractionController()			
		{
			super();
			
			// default session state
			probe.value = MOVE;
			select.value = [DRAG].join(DELIM);
			selectAdd.value = [CTRL, DRAG].join(DELIM);
			selectRemove.value = [CTRL, SHIFT, DRAG].join(DELIM);
			selectAll.value = [CTRL, DCLICK].join(DELIM);
			
			pan.value = [ALT, DRAG].join(DELIM);
			zoom.value = WeaveAPI.CSVParser.createCSV([[SHIFT, DRAG], [WHEEL]]);
			zoomIn.value = DCLICK;
			zoomOut.value = [SHIFT, DCLICK].join(DELIM);
			zoomToExtent.value = [CTRL, ALT, SHIFT, DCLICK].join(DELIM);
			
			getCallbackCollection(this).addImmediateCallback(this, invalidate);
		}
		
		/**
		 * This is the default mode to use when dragging and no modifier keys are pressed.
		 * Not included in session state.
		 */
		public const defaultDragMode:LinkableString = registerDisposableChild(this, new LinkableString(SELECT, verifyDefaultMode));
		private function verifyDefaultMode(value:String):Boolean
		{
			return !value || [PROBE, SELECT, PAN, ZOOM].indexOf(value) >= 0;
		}
		
		public const probe:LinkableString 				= newLinkableChild(this, LinkableString);
		public const select:LinkableString 				= newLinkableChild(this, LinkableString);
		public const selectRemove:LinkableString 		= newLinkableChild(this, LinkableString);
		public const selectAdd:LinkableString 			= newLinkableChild(this, LinkableString);
		public const selectAll:LinkableString 			= newLinkableChild(this, LinkableString);
		public const pan:LinkableString 				= newLinkableChild(this, LinkableString);
		public const zoom:LinkableString 				= newLinkableChild(this, LinkableString);
		public const zoomIn:LinkableString 				= newLinkableChild(this, LinkableString);
		public const zoomOut:LinkableString 			= newLinkableChild(this, LinkableString);
		public const zoomToExtent:LinkableString 		= newLinkableChild(this, LinkableString);
		
		//private const whitespace:RegExp = new RegExp("\s") ;
		private const DELIM:String = ',';
		private var _interactionLookup:Object;
		private var _interactionModeLookup:Object;
		
		private function invalidate():void
		{
			_interactionLookup = null;
			_interactionModeLookup = null;
		}
		private function validate():void
		{
			_interactionLookup = {};
			_interactionModeLookup = {};
			// pairs of [action, modifiers + event] in the order they should be checked
			var pairs:Array = [
				[PROBE, probe],
				[SELECT, select],
				[SELECT_REMOVE, selectRemove],
				[SELECT_ADD, selectAdd],
				[SELECT_ALL, selectAll],
				[PAN, pan],
				[ZOOM, zoom],
				[ZOOM_IN, zoomIn],
				[ZOOM_OUT, zoomOut],
				[ZOOM_TO_EXTENT, zoomToExtent]
			];
			for (var i:int = 0; i < pairs.length; i++)
			{
				var mouseMode:String = pairs[i][0];
				var linkableString:LinkableString = pairs[i][1];
				var rows:Array = WeaveAPI.CSVParser.parseCSV(linkableString.value);
				for each (var row:Array in rows)
				{
					// sort row
					row.sort();
					// save lookup from (modifier keys + mouse event) to action
					var actionStr:String = row.join(DELIM);
					if (!_interactionLookup.hasOwnProperty(actionStr))
						_interactionLookup[actionStr] = mouseMode;
					
					// remove event tokens, then save lookup from (modifier keys) to mouseMode
					for each (var eventType:String in MOUSE_EVENTS)
					{
						var index:int = row.indexOf(eventType);
						if (index >= 0)
							row.splice(index, 1);
					}
					// row now only consists of modifier keys
					var modeStr:String = row.join(DELIM);
					if (INTERACTION_MODES.indexOf(mouseMode) >= 0)
						if (!_interactionModeLookup.hasOwnProperty(modeStr))
							_interactionModeLookup[modeStr] = mouseMode;
				}
			}
		}
		
		/**
		 * @return An Array containing String items corresponding to the active modifier keys (alt,ctrl,shift) 
		 */
		private function getModifierSequence():Array
		{
			var array:Array = [];
			if (WeaveAPI.StageUtils.altKey)
				array.push(ALT);
			if (WeaveAPI.StageUtils.ctrlKey)
				array.push(CTRL);
			if (WeaveAPI.StageUtils.shiftKey)
				array.push(SHIFT);
			return array;
		}
		
		/**
		 * Determine current mouse action from values in internal list of mouse events
		 * @param mouseEventType A mouse event type such as move, drag, click, or dclick
		 * @return returns a string representing current mouse action to execute such as pan, zoom, or select
		 */
		public function determineInteraction(mouseEventType:String):String
		{
			if (!_interactionLookup)
				validate();
			
			var array:Array = getModifierSequence();
			
			// if no modifier keys are pressed, default mode is specified, and this is a drag event... use default drag mode
			if (array.length == 0 && defaultDragMode.value && mouseEventType == DRAG)
				return defaultDragMode.value;
			
			array.push(mouseEventType);
			
			var str:String = array.sort().join(DELIM);
			var action:String = _interactionLookup[str];
			
			//trace(defaultDragMode.value,'determineMouseAction',mouseEventType,'['+str+'] =>',action);
			return action;
		}
		
		/**
		 * Determine current mouse cursor mode from values in internal list of keyboard events
		 * @return returns a string representing which mouse cursor to use
		 */
		public function determineInteractionMode():String
		{
			if (!_interactionModeLookup)
				validate();
			
			var array:Array = getModifierSequence();
			
			// if no modifier keys are pressed and default mode is specified, use default mode
			if (array.length == 0 && defaultDragMode.value)
				return defaultDragMode.value;
			
			var str:String = array.sort().join(DELIM);
			var mode:String = _interactionModeLookup[str];
			
			//trace(defaultDragMode.value,'determineMouseMode','['+str+'] =>',mode);
			return mode;
		}
	}
}
