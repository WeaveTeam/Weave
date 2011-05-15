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

package org.oicweave.visualization.plotters
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import org.oicweave.api.primitives.IBounds2D;
	import org.oicweave.primitives.Bounds2D;
	
	/**
	 * RadVizPlotter
	 * 
	 * @author kmanohar
	 */
	public class RamachandranBackgroundPlotter extends AbstractPlotter
	{
		public function RamachandranBackgroundPlotter()
		{
		}
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			var g:Graphics = tempShape.graphics;
			g.clear();
			g.lineStyle(2, 0, 1);
			
			// project to screen bounds
			tempBounds.setBounds(-180,180,180,-180);
			dataBounds.projectCoordsTo(tempBounds, screenBounds);
			
			var matrix:Matrix = new Matrix();
			matrix.scale(tempBounds.getWidth() / _missingImage.width, tempBounds.getHeight() / _missingImage.height);
			matrix.translate(tempBounds.getXMin(), tempBounds.getYMin());
			destination.draw(_missingImage, matrix, null, null, null, true);
			
			// draw vertical line through x=0
			g.moveTo(tempBounds.getXCenter(), tempBounds.getYMin());
			g.lineTo(tempBounds.getXCenter(), tempBounds.getYMax());
				
			// draw horizontal line through y=0
			g.moveTo(tempBounds.getXMin(), tempBounds.getYCenter());
			g.lineTo(tempBounds.getXMax(), tempBounds.getYCenter());
			
			destination.draw(tempShape);
		}
		
		private const tempBounds:IBounds2D = new Bounds2D();
		private const tempPoint:Point = new Point();

		// background image
		[Embed(source="/org/oicweave/resources/images/RamaPlot.png")]
		private static var _missingImageClass:Class;
		private static const _missingImage:BitmapData = Bitmap(new _missingImageClass()).bitmapData;
	}
}