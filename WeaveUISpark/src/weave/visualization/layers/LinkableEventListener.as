/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.visualization.layers
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.getLinkableRoot;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.core.LinkableFunction;
	import weave.core.LinkableString;

	/**
	 * A LinkableEventListener is a sessioned event listener which is added to the stage. The event type is specified by
	 * <code>event.value</code> and the listener function specified by the LinkableFunction <code>script.value</code>.
	 * 
	 * @author kmonico
	 */	
	public class LinkableEventListener implements ILinkableObject
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
					var stageEvent:Event = WeaveAPI.StageUtils.event;
					
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
				WeaveAPI.StageUtils.removeEventCallback(_lastEvent, _lastFunction);
			
			// Always add the new event and save the event and function
			WeaveAPI.StageUtils.addEventCallback(event.value, this, func);
			_lastEvent = event.value;
			_lastFunction = func;
		}
		
		private var supportedEvents:Array = null;
		private function verifyAction(value:String):Boolean
		{
			// This function is called before the member initializer for supportedEvents
			if (!supportedEvents)
				supportedEvents = WeaveAPI.StageUtils.getSupportedEventTypes();
			
			for each (var event:String in supportedEvents)
			{
				if (event == value)
					return true;
			}
			return false;
		}
	}
}