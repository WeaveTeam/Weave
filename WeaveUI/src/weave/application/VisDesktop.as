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

package weave.application
{
	import mx.containers.Canvas;
	
	import weave.api.WeaveAPI;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableHashMap;
	import weave.api.newLinkableChild;
	import weave.api.ui.ILinkableContainer;
	import weave.core.UIUtils;
	import weave.ui.BasicLinkableLayoutManager;
	
	internal class VisDesktop extends Canvas implements ILinkableContainer, IDisposableObject
	{
		public function VisDesktop()
		{
		}
		
		public var manager:BasicLinkableLayoutManager = null;
		override protected function createChildren():void
		{
			super.createChildren();
			
			manager = newLinkableChild(this, BasicLinkableLayoutManager);
			addElement(manager);
			
			manager.percentHeight = 100;
			manager.percentWidth = 100;
			
			UIUtils.linkLayoutManager(manager,getLinkableChildren());
		}
		
		private var _internalCanvas:Canvas = new Canvas();
		internal function get internalCanvas():Canvas
		{
			return _internalCanvas;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);

			// draw an empty rectangle so this can be the target of mouse events when no children are added.
			graphics.clear();
			graphics.lineStyle(0,0,0);
			graphics.beginFill(0,0);
			graphics.drawRect(0,0,unscaledWidth,unscaledHeight);
		}
		
		public function getLinkableChildren():ILinkableHashMap
		{
			return WeaveAPI.globalHashMap;
		}
		
		public function dispose():void
		{
			UIUtils.unlinkLayoutManager(manager,getLinkableChildren());
		}
	}
}
