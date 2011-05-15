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
	import flash.display.DisplayObject;
	
	import mx.containers.Canvas;
	
	import org.oicweave.core.LinkableHashMap;
	import org.oicweave.core.UIUtils;
	import org.oicweave.api.newLinkableChild;
	import org.oicweave.api.registerLinkableChild;

	/**
	 * FOR TESTING PURPOSES ONLY
	 * 
	 * @author adufilie
	 */
	public class UITest extends DraggablePanel
	{
		public function UITest()
		{
			super();

			// this is where the magic happens
			UIUtils.linkDisplayObjects(visCanvas, children);

			this.horizontalScrollPolicy = "off";
			this.verticalScrollPolicy = "off";

			this.autoLayout = true;
			
			addChild(visCanvas);
			
			visCanvas.percentHeight = 100;
			visCanvas.percentWidth = 100;
		}

		protected const visCanvas:Canvas = new Canvas();
		
		public const children:LinkableHashMap = newLinkableChild(this, LinkableHashMap);
	}
}
