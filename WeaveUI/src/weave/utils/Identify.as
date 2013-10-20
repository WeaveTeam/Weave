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
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.core.UIComponent;
	
	import weave.api.WeaveAPI;

	/**
	 * This contains a static function, identify(), which will display tooltips for every DisplayObject you mouse over.
	 * 
	 * @author adufilie
	 */	
	public class Identify
	{
		private static var _identifyDefaults:Array = ['x','y','width','height','percentWidth','percentHeight','minWidth','minHeight','maxWidth','maxHeight'];
		private static var _identifyTarget:DisplayObject = null;
		private static var _identifyPropertyNames:Array = null;
		private static var _identifyHide:Function = null;
		
		/**
		 * This will be true while identify() is active.
		 */
		public static function get enabled():Boolean
		{
			return !!_identifyPropertyNames;
		}
		
		/**
		 * Enables (or disables) tooltips on every DisplayObject, showing properties and debugIds.
		 * @param propertyNames An optional list of property names to display in the tooltips.
		 *        If none specified, tooltips will be toggled with default properties.
		 *        To disable tooltips, pass a single parameter: <code>false</code>.
		 * @see weave.utils.DebugUtils#debugId()
		 */		
		public static function identify(...propertyNames):void
		{
			if (propertyNames.length == 1 && !propertyNames[0])
				propertyNames = null;
			else if (propertyNames.length == 0)
				propertyNames = _identifyDefaults;
			
			if (propertyNames && _identifyPropertyNames != _identifyDefaults)
			{
				_identifyPropertyNames = propertyNames;
				_identifyTarget = null;
				WeaveAPI.StageUtils.addEventCallback(MouseEvent.MOUSE_OVER, null, _identify, true);
			}
			else
			{
				_identifyPropertyNames = null;
				WeaveAPI.StageUtils.removeEventCallback(MouseEvent.MOUSE_OVER, _identify);
				if (_identifyHide != null)
					_identifyHide();
			}
		}
		private static function _identify():void
		{
			var event:Event = WeaveAPI.StageUtils.event;
			if (!event)
				return;
			
			var target:DisplayObject = event.target as DisplayObject;
			if (!target)
				return;
			
			if (!_identifyPropertyNames || _identifyTarget == target)
				return;
			
			if (_identifyHide != null)
				_identifyHide();
			
			var strings:Array = [];
			for each (var name:String in _identifyPropertyNames)
			if (target.hasOwnProperty(name))
				strings.push(name + '=' + target[name]);
			
			var text:String = debugId(target) + '\n' + strings.join(', ');
			_identifyHide = PopUpUtils.showTemporaryTooltip(target, text, int.MAX_VALUE, drawBorder);
			
			function drawBorder(tip:UIComponent):void
			{
				var tipxy:Point = tip.globalToLocal(new Point(0, 0));
				var targetxy:Point = target.globalToLocal(new Point(0, 0));
				var offset:Point = targetxy.subtract(tipxy);
				var g:Graphics = tip.graphics;
				
				g.lineStyle(2, 0xFF0000, 0.5, true);
				g.drawRect(-offset.x, -offset.y, target.width, target.height);
			}
		}
	}
}
