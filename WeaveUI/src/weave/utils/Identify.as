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

package weave.utils
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import mx.core.UIComponent;

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
				var styles:Array = [
					[2, 0xFF0000, 0.65],
					[1, 0xFF0000, 0.25]
				];
				while (target)
				{
					var r:Rectangle = target.getRect(tip);
					tip.graphics.lineStyle(styles[0][0], styles[0][1], styles[0][2], true);
					tip.graphics.drawRect(r.x, r.y, r.width, r.height);

					target = target.parent;
					if (styles.length > 1)
						styles.shift();
				}
			}
		}
	}
}
