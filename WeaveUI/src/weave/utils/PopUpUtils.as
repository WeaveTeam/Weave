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
package weave.utils
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	import mx.controls.Alert;
	import mx.controls.ToolTip;
	import mx.core.IFlexDisplayObject;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import weave.api.WeaveAPI;
	
	public class PopUpUtils
	{
		public static function createDisplayObjectAsPopUp(destination:DisplayObject, classType:Class):IFlexDisplayObject
		{
			var popup:IFlexDisplayObject = PopUpManager.createPopUp(destination, classType);	
			PopUpManager.centerPopUp(popup);
			popup.visible = true;
			
			return popup;
		}
		
		/**
		 * Confirms a user action with a yes/no alert box.
		 * @param parent The parent of the alert box.
		 * @param title The title of the alert box.
		 * @param question A yes/no question to ask the user.
		 * @param yesVoidFunction A function with no parameters to call when 'yes' is clicked.
		 * @param noVoidFunction A function with no parameters to call when 'no' is clicked.
		 */
		public static function confirm(parent:Sprite, title:String, question:String, yesVoidFunction:Function, noVoidFunction:Function = null, yesLabel:String = null, noLabel:String = null, buttonWidth:int = 85):void
		{
			var prevButtonWidth:int = Alert.buttonWidth;
			Alert.yesLabel = yesLabel;
			Alert.noLabel = noLabel;
			Alert.buttonWidth = buttonWidth;
			Alert.show(
					question,
					title,
					Alert.YES|Alert.NO,
					parent,
					function(event:CloseEvent):void
					{
						if (event.detail == Alert.YES)
						{
							if (yesVoidFunction != null)
								yesVoidFunction();
						}
						else
						{
							if (noVoidFunction != null)
								noVoidFunction();
						}
					}
				);
			Alert.yesLabel = null;
			Alert.noLabel = null;
			Alert.buttonWidth = prevButtonWidth;
		}

		
		/**
		 * This will show a tooltip below a component that will disappear after a set duration.
		 * @param component The component below which a tooltip should be placed.
		 * @param text The text to display in the tooltip.
		 * @param duration The amount of time the tooltip will be displayed.
		 * @return A function that will hide the tooltip.
		 */
		public static function showTemporaryTooltip(component:DisplayObject, text:String, duration:int = 1500):Function
		{
			// create tooltip underneath editor
			var tip:ToolTip = PopUpManager.createPopUp(WeaveAPI.topLevelApplication as DisplayObject, ToolTip) as ToolTip;
			tip.mouseChildren = false;
			tip.text = text;
			tip.validateNow();
			show();
			
			// Periodically bring tooltip to front so user sees it.
			// This is required in case the user clicks on another popup that obscures the tooltip.
			var interval:int = 200;
			var timer:Timer = new Timer(interval, duration / interval);
			timer.addEventListener(TimerEvent.TIMER, show);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE, hide);
			timer.start();
			
			function show(_:* = null):void
			{
				if (tip && component.parent)
				{
					var coords:Point = component.localToGlobal(new Point(0, component.height));
					tip.x = Math.max(0, coords.x);
					tip.y = Math.max(0, coords.y);
					if (component.stage)
					{
						tip.x = Math.min(tip.x, component.stage.stageWidth - tip.width);
						tip.y = Math.min(tip.y, component.stage.stageHeight - tip.height);
					}
					PopUpManager.bringToFront(tip);
				}
				else
					hide();
			}
			function hide(_:* = null):void
			{
				if (tip)
				{
					PopUpManager.removePopUp(tip);
					timer.stop();
					tip = null;
				}
			}
			
			return hide;
		}
	}
}