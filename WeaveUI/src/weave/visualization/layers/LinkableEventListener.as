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
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	
	import weave.Weave;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IKeySet;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.core.CallbackCollection;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableFunction;
	import weave.core.LinkableString;
	import weave.core.StageUtils;
	import weave.ui.DraggablePanel;

	/**
	 * A LinkableEventListener is a sessioned eventLinster which is added to the stage. The action is specified by
	 * <code>action.value</code> and the listener function specified by the LinkableFunction <code>listener.value</code>.
	 * 
	 * @author kmonico
	 */	
	public class LinkableEventListener extends CallbackCollection implements ILinkableObject, IDisposableObject
	{
		public function LinkableEventListener()
		{
			super();
		}

		/**
		 * A boolean indicating whether this interaction event is enabled.
		 * @default true 
		 */		
		public const enabled:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		
		/**
		 * The action which triggers this interaction.
		 */		
		public const action:LinkableString = registerLinkableChild(this, new LinkableString(MouseEvent.DOUBLE_CLICK, verifyAction), handleMouseActionChange);
		
		/**
		 * The function to call when the event occurs.<br>
		 * The compiled function has one argument named "event" which specifies the target. 
		 */		
		public const listener:LinkableFunction = registerLinkableChild(this, new LinkableFunction('', true, true, ["event", "panel"]));

		
		private var _lastEvent:String = null; 
		private var _lastFunction:Function = null;
		private function handleMouseActionChange():void
		{
			var func:Function = function():void
			{
				try
				{
					listener.apply(this, [ StageUtils.event, DraggablePanel.activePanel ] );
				} 
				catch (e:Error)
				{
					reportError(e);
				}
			}
			
			// If there was an event listener added, we need to remove it now
			if (_lastFunction != null && _lastEvent != null)
				StageUtils.removeEventCallback(_lastEvent, _lastFunction);
			
			// Always add the new event and save the event and function
			StageUtils.addEventCallback(action.value, this, func);
			_lastEvent = action.value;
			_lastFunction = func;
		}
		
		private var supportedEvents:Array = null;
		private function verifyAction(value:String):Boolean
		{
			// This function is called before the member initializer for supportedEvents
			if (!supportedEvents)
				supportedEvents = StageUtils.getSupportedEventTypes();
			
			for each (var event:String in supportedEvents)
			{
				if (event == value)
					return true;
			}
			return false;
		}
	}
}