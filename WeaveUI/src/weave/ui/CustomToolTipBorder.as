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
	import flash.display.Graphics;
	
	import mx.skins.halo.ToolTipBorder;

	/**
	 * Modifies behavior of borderStyle="errorTipBelow" so the arrow appears close to the left side.
	 * 
	 * @author adufilie
	 */
	public class CustomToolTipBorder extends ToolTipBorder
	{
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);
			
			var borderStyle:String = getStyle("borderStyle");
			
			if (borderStyle == "errorTipBelow")
			{
				var backgroundColor:uint = getStyle("backgroundColor");
				var backgroundAlpha:Number= getStyle("backgroundAlpha");
				var borderColor:uint = getStyle("borderColor");
				var cornerRadius:Number = getStyle("cornerRadius");
				
				var g:Graphics = graphics;
				g.clear();
				var radius:int = 3;
				// border
				drawRoundRect(0, 11, w, h - 13, radius, borderColor, backgroundAlpha);
				// top pointer 
				g.beginFill(borderColor, backgroundAlpha);
				g.moveTo(radius + 0, 11);
				g.lineTo(radius + 6, 0);
				g.lineTo(radius + 12, 11);
				g.moveTo(radius, 11);
				g.endFill();
			}
		}
	}
}
