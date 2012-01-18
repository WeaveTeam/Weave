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
	 * A static library containing functions to aid in performing zooming calculations
	 * 
	 * @author adufilie
	 */
	public class ZoomUtils
	{
		/**
		 * This function calculates the zoom level.  If dataBounds is scaled to fit into screenBounds,
		 * the screen size of fullDataBounds would be 2^zoomLevel * minSize.  Zoom level is defined this way
		 * to be compatible with the zoom level used by Google Maps and other tiled WMS services.
		 * @param dataBounds The visible data coordinates.
		 * @param screenBounds The visible screen coordinates.
		 * @param fullDataBounds The full extent in data coordinates.
		 * @param minScreenSize The minimum size that the fullDataBounds can appear as on the screen (the screen size of zoom level zero).
		 * @return The zoom level, where the screen size of the full extent is 2^zoomLevel * minSize.
		 */
		public static function getZoomLevel(dataBounds:IBounds2D, screenBounds:IBounds2D, fullDataBounds:IBounds2D, minScreenSize:Number):Number
		{
			tempBounds.copyFrom(fullDataBounds);
			
			// project fullDataBounds to screen coordinates
			dataBounds.projectCoordsTo(tempBounds, screenBounds);
			
			// get screen size of fullDataBounds
			var screenSize:Number;
			//If this is true, X coordinates will be used to calculate zoom level.  If this is false, Y coordinates will be used.
			var useXCoordinates:Boolean = (fullDataBounds.getXCoverage() > fullDataBounds.getYCoverage()); // fit full extent inside min screen size
			if (useXCoordinates)
				screenSize = tempBounds.getWidth();
			else
				screenSize = tempBounds.getHeight();
			
			// calculate zoom level
			return Math.log(Math.abs(screenSize / minScreenSize)) / Math.LN2;
		}

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
		
		/**
		 * pans specified dataBounds by the specified screen coordinates
		 * @param dataBounds The visible data bounds
		 * @param screenBounds The screen bounds that the data bounds is scaled to fit in
		 * @param deltaScreenX The screen distance to pan the data bounds along the x axis
		 * @param deltaScreenY The screen distance to pan the data bounds along the y axis
		 */
		private static function panDataBoundsByScreenCoordinates(dataBounds:IBounds2D, screenBounds:IBounds2D, deltaScreenX:Number, deltaScreenY:Number):void
		{
			// get offset screen bounds
			tempPanBounds.copyFrom(screenBounds);
			tempPanBounds.offset(-deltaScreenX, -deltaScreenY);
			// project to data coordinates
			screenBounds.projectCoordsTo(tempPanBounds, dataBounds);
			// overwrite dataBounds
			dataBounds.copyFrom(tempPanBounds);
		}
		
		private static var tempPanBounds:IBounds2D = new Bounds2D(); // reusable temporary object used only by panDataBoundsByScreenCoordinates
		private static var tempBounds:IBounds2D = new Bounds2D(); // reusable temporary object
		
		/**
		 * scale greater than 1 will zoom in, scale less than 1 will zoom out
		 * @param dataBounds The visible data bounds
		 * @param screenBounds The screen bounds that the data bounds is scaled to fit in
		 * @param xScreenOrigin The x screen coordinate used as the scale origin
		 * @param yScreenOrigin The y screen coordinate used as the scale origin
		 * @param relativeScale The relative scale value used to scale the data bounds
		 * @param repositionCenter If true, this causes the data coordinates to be associated with the screen origin to be moved to the center of the screen bounds after scaling.
		 */
		public static function zoomDataBoundsByRelativeScreenScale(dataBounds:IBounds2D, screenBounds:IBounds2D, xScreenOrigin:Number, yScreenOrigin:Number, relativeScale:Number, repositionCenter:Boolean):void
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
			panDataBoundsByScreenCoordinates(tempBounds, screenBounds, -deltaScreenX, -deltaScreenY);
			
			// constrain width,height independently
			tempBounds.setWidth(tempBounds.getWidth() * dataBoundsSizeChange);
			tempBounds.setHeight(tempBounds.getHeight() * dataBoundsSizeChange);
			
			if (!repositionCenter)
			{
				// pan the tempBounds origin back to its original screen position
				panDataBoundsByScreenCoordinates(tempBounds, screenBounds, deltaScreenX, deltaScreenY);
			}
			
			dataBounds.copyFrom(tempBounds);
		}
		
	}
}
