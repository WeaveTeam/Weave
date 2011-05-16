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

package weave.utils
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import weave.api.primitives.IBounds2D;
	import weave.primitives.Bounds2D;
	
	/**
	 * all-static class containing functions to aid in performing zooming calculations
	 * 
	 * @author adufilie
	 */
	public class ZoomUtils
	{
		/**
		 * @param dataBounds The visible data coordinates.
		 * @param screenBounds The visible screen coordinates.
		 * @param fullDataBounds The full extent in data coordinates.
		 * @param minScreenSize The minimum size of the screen.
		 * @param useXCoordinates If this is true, X coordinates will be used to calculate zoom level.  If this is false, Y coordinates will be used.
		 * @return The zoom level, where the screen size of the full extent is 2^zoomLevel * minSize.
		 */
		public static function getZoomLevel(dataBounds:IBounds2D, screenBounds:IBounds2D, fullDataBounds:IBounds2D, minScreenSize:Number, useXCoordinates:Boolean):Number
		{
			fullDataBounds.getMinPoint(tempMinPoint)
			fullDataBounds.getMaxPoint(tempMaxPoint)
			// project fullDataBounds to screen coordinates 
			dataBounds.projectPointTo(tempMinPoint, screenBounds);
			dataBounds.projectPointTo(tempMaxPoint, screenBounds);
			// get screen size of fullDataBounds
			var screenSize:Number;
			if (useXCoordinates)
				screenSize = tempMaxPoint.x - tempMinPoint.x;
			else
				screenSize = tempMaxPoint.y - tempMinPoint.y;
			
			// calculate zoom level
			return Math.log(Math.abs(screenSize / minScreenSize)) / Math.LN2;
		}
		private static const tempMinPoint:Point = new Point(); // reusable temporary object
		private static const tempMaxPoint:Point = new Point(); // reusable temporary object
		
		/**
		 * This function generates a matrix for transforming points from one bounds to another.
		 */
		public static function generateTransformMatrix(outputMatrix:Matrix, fromBounds:IBounds2D, toBounds:IBounds2D):void
		{
			outputMatrix.identity();
			outputMatrix.translate(-fromBounds.getXMin(), -fromBounds.getYMin());

			var fromWidth:Number = fromBounds.getWidth();
			var fromHeight:Number = fromBounds.getHeight();
			var toWidth:Number = toBounds.getWidth();
			var toHeight:Number = toBounds.getHeight();

			outputMatrix.scale(toWidth / fromWidth, toHeight / fromHeight);
			outputMatrix.translate(toBounds.getXMin(), toBounds.getYMin());
		}
		
		
		/**
		 * conformDataBoundsToAspectRatio
		 * Enforce an aspect ratio on xDataUnitsPerPixel to yDataUnitsPerPixel.
		 * This will increase the size of the given dataBounds either vertically or horizontally if necessary.
		 * @param dataBounds The Bounds2D object to enforce an aspectRatio on.
		 * @param screenBounds The Bounds2D object the dataBounds will be mapped to.
		 * @param aspectRatio The aspect ratio to enforce (absolute value will be used).
		 */
		public static function conformDataBoundsToAspectRatio(dataBoundsToModify:IBounds2D, screenBounds:IBounds2D, aspectRatio:Number):void
		{
			// do nothing if aspectRatio is NaN or screenBounds is empty
			if (isNaN(aspectRatio) || screenBounds.isEmpty())
				return;
			
			var xPixels:Number = screenBounds.getXCoverage();
			var yPixels:Number = screenBounds.getYCoverage();
			var xSignedDataUnitsPerPixel:Number = dataBoundsToModify.getWidth() / xPixels;
			var ySignedDataUnitsPerPixel:Number = dataBoundsToModify.getHeight() / yPixels;
			if (Math.abs(xSignedDataUnitsPerPixel / ySignedDataUnitsPerPixel) < Math.abs(aspectRatio))
			{
				// dataBounds is too wide
				// expand horizontally to conform to desired aspect ratio
				var widthSign:Number = dataBoundsToModify.getXDirection();
				xSignedDataUnitsPerPixel = widthSign * Math.abs(ySignedDataUnitsPerPixel * aspectRatio);
				dataBoundsToModify.setWidth(xSignedDataUnitsPerPixel * xPixels);
			}
			else if (Math.abs(xSignedDataUnitsPerPixel / ySignedDataUnitsPerPixel) > Math.abs(aspectRatio))
			{
				// dataBounds is too tall
				// expand vertically to conform to desired aspect ratio
				var heightSign:Number = dataBoundsToModify.getYDirection();
				ySignedDataUnitsPerPixel = heightSign * Math.abs(xSignedDataUnitsPerPixel / aspectRatio);
				dataBoundsToModify.setHeight(ySignedDataUnitsPerPixel * yPixels);
			}
		}
		
		private static var tempBounds:IBounds2D = new Bounds2D(); // reusable temporary object
		
		// panSpecifiedDataBoundsByScreenCoordinates: pans specified dataBounds by the specified screen coordinates
		private static function panSpecifiedDataBoundsByScreenCoordinates(dataBounds:IBounds2D,screenBounds:IBounds2D, deltaScreenX:Number, deltaScreenY:Number):void
		{
			// project offset min screen point to data point
			screenBounds.getMinPoint(tempMinPoint);
			tempMinPoint.x -= deltaScreenX;
			tempMinPoint.y -= deltaScreenY;
			screenBounds.projectPointTo(tempMinPoint, dataBounds);
			
			// project offset max screen point to data point
			screenBounds.getMaxPoint(tempMaxPoint);
			tempMaxPoint.x -= deltaScreenX;
			tempMaxPoint.y -= deltaScreenY;
			screenBounds.projectPointTo(tempMaxPoint, dataBounds);
			
			// save min,max data points
			dataBounds.setBounds(tempMinPoint.x, tempMinPoint.y, tempMaxPoint.x, tempMaxPoint.y);
		}
		
		
		// zoomDataBoundsByRelativeScreenScale: scale greater than 1 will zoom in, scale less than 1 will zoom out
		public static function zoomDataBoundsByRelativeScreenScale(dataBounds:IBounds2D,screenBounds:IBounds2D,xScreenOrigin:Number, yScreenOrigin:Number, relativeScale:Number, repositionCenter:Boolean):void
		{
			// copy dataBounds to tempBounds
			tempBounds.copyFrom(dataBounds);
			
			// stop if values are undefined/empty
			if (tempBounds.isUndefined() || tempBounds.isEmpty() || screenBounds.isEmpty())
				return;
			
			// the dataBounds width,height will change by a factor of (1 / relativeScale) because scale is data coords per screen coords
			var dataBoundsSizeChange:Number = 1 / relativeScale;
			
			var deltaScreenX:Number = xScreenOrigin - screenBounds.getXCenter();
			var deltaScreenY:Number = yScreenOrigin - screenBounds.getYCenter();
			
			// pan the tempBounds origin to the center of the screenBounds
			panSpecifiedDataBoundsByScreenCoordinates(tempBounds, screenBounds,-deltaScreenX, -deltaScreenY);
			
			// constrain width,height independently
			tempBounds.setWidth(tempBounds.getWidth() * dataBoundsSizeChange);
			tempBounds.setHeight(tempBounds.getHeight() * dataBoundsSizeChange);
			
			if (!repositionCenter)
			{
				// pan the tempBounds origin back to its original screen position
				panSpecifiedDataBoundsByScreenCoordinates(tempBounds,screenBounds, deltaScreenX, deltaScreenY);
			}
			
			dataBounds.copyFrom(tempBounds);
		}
		
	}
}
