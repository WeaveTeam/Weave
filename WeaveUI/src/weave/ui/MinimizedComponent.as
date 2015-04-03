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

package weave.ui
{
	import flash.display.BitmapData;
	import flash.events.MouseEvent;
	
	import mx.containers.Canvas;
	import mx.core.UIComponent;
	
	import weave.api.reportError;
	import weave.compiler.StandardLib;
	import weave.utils.BitmapUtils;
	
	public class MinimizedComponent extends Canvas
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
				var msg:String = StandardLib.substitute("Unable to update minimized icon for component {0} ({1} x {2})", debugId(_mainComponent), _mainComponent.width, _mainComponent.height);
				reportError(e, msg, _mainComponent);
			}
		}
	}
}