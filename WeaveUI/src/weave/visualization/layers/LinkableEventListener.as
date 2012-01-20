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
	import flash.events.MouseEvent;
	
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.getLinkableRoot;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.core.CallbackCollection;
	import weave.core.LinkableFunction;
	import weave.core.LinkableString;
	import weave.core.StageUtils;

	/**
	 * A LinkableEventListener is a sessioned eventLinster which is added to the stage. The action is specified by
	 * <code>event.value</code> and the listener function specified by the LinkableFunction <code>script.value</code>.
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
		 * The name of the component in the session state which owns the event.
		 * If this is empty, the event applies across the stage.
		 */		
		public const target:LinkableString = registerLinkableChild(this, new LinkableString());
		
		
		/**
		 * The event which triggers this interaction.
		 */		
		public const event:LinkableString = registerLinkableChild(this, new LinkableString(MouseEvent.DOUBLE_CLICK, verifyAction), handleMouseActionChange);
		
		/**
		 * The function to call when the event occurs.<br>
		 * The compiled function has one argument named "event" which specifies the target. 
		 */		
		public const script:LinkableFunction = registerLinkableChild(this, new LinkableFunction('', true, true, ["event"]));

		
		private var _lastEvent:String = null; 
		private var _lastFunction:Function = null;
		private function handleMouseActionChange():void
		{
			var self:LinkableEventListener = this;
			var func:Function = function():void
			{
				try
				{
					var thisPointer:* = null;
					var stageEvent:Event = StageUtils.event;
					
					// if a target is specified, check that the event occurred on the target
					if (target.value)
					{
						var root:ILinkableHashMap = getLinkableRoot(self) as ILinkableHashMap;
						var globalObject:* = root.getObject(target.value);
						var component:* = stageEvent.target;
						
						while (component)
						{
							if (component == globalObject)
								break;
							component = component.parent;
						}
						
						if (component == null)
							return;
						
						// set the thisPointer 
						thisPointer = component;
						
						// fall through
					}
					
					script.apply(thisPointer, [ stageEvent ] );
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
			StageUtils.addEventCallback(event.value, this, func);
			_lastEvent = event.value;
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