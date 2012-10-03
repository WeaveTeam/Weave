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
		// input types
		public static const INPUT_MOVE:String = "move";
		public static const INPUT_DRAG:String = "drag";
		public static const INPUT_CLICK:String = "click";
		public static const INPUT_DCLICK:String = "dclick";
		public static const INPUT_WHEEL:String = "wheel";
		public static const INPUT_PAN:String = "pan"; // gesture
		public static const INPUT_ZOOM:String = "zoom"; // gesture
		
		private static const ALL_INPUT_TYPES:Array = [INPUT_MOVE, INPUT_DRAG, INPUT_CLICK, INPUT_DCLICK, INPUT_WHEEL, INPUT_PAN, INPUT_ZOOM];
		
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
		
		public static const SELECTION_MODE_RECTANGLE:String = "rectangle";
		public static const SELECTION_MODE_CIRCLE:String = "circle";
		public static const SELECTION_MODE_LASSO:String = "lasso";
		public static function enumSelectionMode():Array
		{
			return [SELECTION_MODE_RECTANGLE, SELECTION_MODE_CIRCLE, SELECTION_MODE_LASSO];
		}
		
		/**
		 * This is a list of what are considered "modes" that affect what moving the mouse does.
		 * This does not include one-time actions not affected by mouse movements.
		 */		
		private static const INTERACTION_MODES:Array = [PAN, SELECT, SELECT_ADD, SELECT_REMOVE, ZOOM, PROBE];
	
		public function InteractionController()			
		{
			super();
			
			// default session state
			probe.value = INPUT_MOVE;
			select.value = [INPUT_DRAG].join(DELIM);
			selectAdd.value = [CTRL, INPUT_DRAG].join(DELIM);
			selectRemove.value = [CTRL, SHIFT, INPUT_DRAG].join(DELIM);
			selectAll.value = [CTRL, INPUT_DCLICK].join(DELIM);
			
			pan.value = WeaveAPI.CSVParser.createCSV([[ALT, INPUT_DRAG], [INPUT_PAN]]);
			zoom.value = WeaveAPI.CSVParser.createCSV([[SHIFT, INPUT_DRAG], [INPUT_WHEEL], [INPUT_ZOOM]]);
			zoomIn.value = INPUT_DCLICK;
			zoomOut.value = [SHIFT, INPUT_DCLICK].join(DELIM);
			zoomToExtent.value = [CTRL, ALT, SHIFT, INPUT_DCLICK].join(DELIM);
			
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
		
		public const probe:LinkableString = newLinkableChild(this, LinkableString);
		public const select:LinkableString = newLinkableChild(this, LinkableString);
		public const selectRemove:LinkableString = newLinkableChild(this, LinkableString);
		public const selectAdd:LinkableString = newLinkableChild(this, LinkableString);
		public const selectAll:LinkableString = newLinkableChild(this, LinkableString);
		public const pan:LinkableString = newLinkableChild(this, LinkableString);
		public const zoom:LinkableString = newLinkableChild(this, LinkableString);
		public const zoomIn:LinkableString = newLinkableChild(this, LinkableString);
		public const zoomOut:LinkableString = newLinkableChild(this, LinkableString);
		public const zoomToExtent:LinkableString = newLinkableChild(this, LinkableString);
		
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
					for each (var inputType:String in ALL_INPUT_TYPES)
					{
						var index:int = row.indexOf(inputType);
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
		 * Determine current mouse action from modifier keys and input type.
		 * @param mouseEventType A mouse event type such as move, drag, click, or dclick.
		 * @return A string representing current mouse action to execute such as pan, zoom, or select.
		 */
		public function determineInteraction(inputType:String = null):String
		{
			if (!_interactionLookup)
				validate();
			
			var array:Array = getModifierSequence();
			
			// if no modifier keys are pressed, default mode is specified, and this is a drag input or no input... use default drag mode
			if (array.length == 0 && defaultDragMode.value && (!inputType || inputType == INPUT_DRAG))
				return defaultDragMode.value;
			
			var str:String;
			if (inputType)
			{
				array.push(inputType);
				str = array.sort().join(DELIM);
				var action:String = _interactionLookup[str];
				
				//trace(defaultDragMode.value,'determineMouseAction',mouseEventType,'['+str+'] =>',action);
				return action;
			}
			else
			{
				str = array.sort().join(DELIM);
				var mode:String = _interactionModeLookup[str];
				
				//trace(defaultDragMode.value,'determineMouseMode','['+str+'] =>',mode);
				return mode;
			}
			
			return action;
		}
	}
}
