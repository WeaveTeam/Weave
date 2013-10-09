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

package weave.visualization.plotters
{
	import flash.display.BitmapData;
	import flash.display.CapsStyle;
	import flash.display.Graphics;
	import flash.geom.Point;
	
	import weave.api.WeaveAPI;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.ui.IPlotter;
	import weave.compiler.StandardLib;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * This plotter displays externally specified grid lines
	 * 
	 * @author kmanohar
	 */
	public class GridLinePlotter extends AbstractPlotter
	{
		WeaveAPI.registerImplementation(IPlotter, GridLinePlotter, "Grid lines");
		
		public function GridLinePlotter()
		{
			lineStyle.caps.defaultValue.value = CapsStyle.NONE;
		}
		
		public const lineStyle:SolidLineStyle = newLinkableChild(this, SolidLineStyle);
		public const horizontal:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(false));
		
		public const start:LinkableNumber = newSpatialProperty(LinkableNumber);
		public const end:LinkableNumber = newSpatialProperty(LinkableNumber);
		public const interval:LinkableNumber = newLinkableChild(this, LinkableNumber);
		
		override public function getBackgroundDataBounds(output:IBounds2D):void
		{
			output.reset();
			if (horizontal.value)
				output.setYRange(start.value, end.value);
			else
				output.setXRange(start.value, end.value);
		}
		
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			var graphics:Graphics = tempShape.graphics;
			graphics.clear();
			
			var _start:Number = start.value;
			var _end:Number = end.value;
			
			if (isNaN(_start))
				_start = horizontal.value ? dataBounds.getYMin() : dataBounds.getXMin();
			if (isNaN(_end))
				_end = horizontal.value ? dataBounds.getYMax() : dataBounds.getXMax();
			
			var _interval:Number = Math.abs(interval.value) * StandardLib.sign(_end - _start);
			
			lineStyle.beginLineStyle(null, graphics);
			
			var i:int;
			var numLines:Number = Math.abs((_end - _start) / _interval);
			if (horizontal.value)
			{
				// if there will be more grid lines than pixels, don't bother drawing anything
				if (numLines > screenBounds.getYCoverage())
					return;
				
				for (i = 0; i <= numLines; i++)
				{
					tempPoint.x = dataBounds.getXMin();
					tempPoint.y = _start + _interval * i;
					dataBounds.projectPointTo(tempPoint, screenBounds);
					graphics.moveTo(tempPoint.x, tempPoint.y);
					
					tempPoint.x = dataBounds.getXMax();
					tempPoint.y = _start + _interval * i;
					dataBounds.projectPointTo(tempPoint, screenBounds);
					graphics.lineTo(tempPoint.x, tempPoint.y);
				}
			}
			else
			{										
				// if there will be more grid lines than pixels, don't bother drawing anything
				if (numLines > screenBounds.getXCoverage())
					return;
				for (i = 0; i <= numLines; i++)
				{
					tempPoint.x = _start + _interval * i;
					tempPoint.y = dataBounds.getYMin();
					dataBounds.projectPointTo(tempPoint, screenBounds);
					graphics.moveTo(tempPoint.x, tempPoint.y);
					
					tempPoint.x = _start + _interval * i;
					tempPoint.y = dataBounds.getYMax();
					dataBounds.projectPointTo(tempPoint, screenBounds);
					graphics.lineTo(tempPoint.x, tempPoint.y);
				}
			}
			
			destination.draw(tempShape);
		}
		
		private const tempPoint:Point = new Point();
	}
}
