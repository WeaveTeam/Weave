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
package org.oicweave.ui
{
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	
	import mx.containers.Canvas;
	import mx.core.UIComponent;
	
	import org.oicweave.utils.BitmapUtils;
	
	public class MinimizedComponent extends Canvas
	{
		public var restoreFunction:Function = null;
		
		public var componentGroup:Array = null;

		private var _mainComponent:UIComponent = null;
		
		public static const MINIMIZED_COMPONENT_ALPHA:Number = 1;
		
		public function MinimizedComponent(componentGroup:Array, desiredWidth:int, desiredHeight:int, restoreFunction:Function)
		{
			this.toolTip = "";
			
			this.restoreFunction = restoreFunction;

			
			this.componentGroup = componentGroup.concat();
			
			var minimizedComponents:int = 0;
			for each(var component:UIComponent in componentGroup)
			{
				if(component.visible)
					minimizedComponents++;
			}
			
			_mainComponent = componentGroup[0];
			
			if(_mainComponent.hasOwnProperty("title") )
				this.toolTip = (_mainComponent["title"].toString().length > 0) ? _mainComponent["title"] : "untitled window";
				
			updateMinimizedIcon(desiredWidth, desiredHeight);	
			
			this.toolTip += (minimizedComponents > 1 ? "\n (" + minimizedComponents + "items minimized)" : "");
		}	
		

		public function updateMinimizedIcon(desiredWidth:int, desiredHeight:int):void
		{
			this.graphics.clear();
			this.width  = desiredWidth;
			this.height = desiredHeight;
			var thumbnail:BitmapData = BitmapUtils.getBitmapDataFromComponent(_mainComponent, desiredWidth, desiredHeight);
			BitmapUtils.drawCenteredIcon(this.graphics, desiredWidth/2, desiredHeight/2, thumbnail);
		}
	}
}