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
package weave.ui
{
	import flash.display.BitmapData;
	import flash.events.MouseEvent;
	import flash.ui.Mouse;
	
	import mx.containers.Canvas;
	import mx.core.UIComponent;
	import mx.utils.StringUtil;
	
	import spark.components.Group;
	
	import weave.api.reportError;
	import weave.utils.BitmapUtils;
	
	public class MinimizedComponent extends Group
	{
		public var clickListener:Function = null;
		public var componentGroup:Array = null;
		private var _mainComponent:UIComponent = null;
		
		public function MinimizedComponent(componentGroup:Array, desiredWidth:int, desiredHeight:int, clickListener:Function)
		{
			addEventListener(MouseEvent.CLICK, clickListener);
			this.componentGroup = componentGroup.concat();
			
			var minimizedComponents:int = 0;
			for each (var component:UIComponent in componentGroup)
			{
				if (component.visible)
					minimizedComponents++;
			}
			
			_mainComponent = componentGroup[0];
			
			updateMinimizedIcon(desiredWidth, desiredHeight);	
			
			this.toolTip = '';
			if(_mainComponent.hasOwnProperty("title") )
				this.toolTip = _mainComponent["title"] || '';
		}	

		public function updateMinimizedIcon(desiredWidth:int, desiredHeight:int):void
		{
			try
			{
				graphics.clear();
				width  = desiredWidth;
				height = desiredHeight;
				var thumbnail:BitmapData = BitmapUtils.getBitmapDataFromComponent(_mainComponent, desiredWidth, desiredHeight);
				BitmapUtils.drawCenteredIcon(graphics, desiredWidth/2, desiredHeight/2, thumbnail);
			}
			catch (e:Error)
			{
				var msg:String = StringUtil.substitute("Unable to update minimized icon for component {0} ({1} x {2})", debugId(_mainComponent), _mainComponent.width, _mainComponent.height);
				reportError(e, msg, _mainComponent);
			}
		}
	}
}