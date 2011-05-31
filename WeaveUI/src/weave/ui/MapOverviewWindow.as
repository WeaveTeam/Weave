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
	import flash.display.DisplayObject;
	
	import mx.containers.Canvas;
	import mx.events.FlexEvent;
	
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableHashMap;
	import weave.core.UIUtils;
	import weave.ui.DraggablePanel;

	/**
	 * @author kmanohar
	 */
	public class MapOverviewWindow extends DraggablePanel
	{
		public function MapOverviewWindow()
		{
			super();

			// Link to MapTool's children's session state
			UIUtils.linkDisplayObjects(visCanvas, children);

			// FIX: setting these variables to false does not work
			this.resizeable.value = false;
			this.draggable.value = false;
			this.enableBorders.value = false;
			
			//Temporary solution
			setStyle("headerHeight",0);
			setStyle("borderThickness",0);
			
			this.panelWidth.value = "25%";
			this.panelHeight.value = "25%";

			addChild(visCanvas);
			
			visCanvas.percentHeight = 100;
			visCanvas.percentWidth = 100;
		}
		
		override protected function childrenCreated():void
		{
			super.childrenCreated();
			enableBorders.value = false;
		}
		
		protected const visCanvas:Canvas = new Canvas();
		
		public const children:LinkableHashMap = newLinkableChild(this, LinkableHashMap);
	}
}
