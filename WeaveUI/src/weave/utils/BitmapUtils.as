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
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	import flash.utils.ByteArray;
	
	import mx.core.UIComponent;
	import mx.graphics.ImageSnapshot;
	import mx.graphics.codec.JPEGEncoder;
	import mx.graphics.codec.PNGEncoder;
	import mx.utils.Base64Encoder;
	
	import weave.api.copySessionState;
	
	/**
	 * BitmapUtils
	 * Functions for working with bitmaps.
	 * 
	 * @author adufilie
	 */
	public class BitmapUtils
	{
		// reusable temporary objects
		private static var tempMatrix:Matrix = new Matrix();
		
		/**
		 * This function will draw an image centered on an x,y coordinate.
		 * @param graphics The Graphics object where the icon should be drawn.
		 * @param x The center x coordinate used to draw the icon.
		 * @param y The center y coordinate used to draw the icon.
		 * @param source The icon image.
		 * @param fillColor A background fill color.
		 * @param fillAlpha A background fill alpha.
		 * @param scale A scale value used to resize the source image.
		 */
		public static function drawCenteredIcon(graphics:Graphics, x:Number, y:Number, source:BitmapData, fillColor:Number = NaN, fillAlpha:Number = 1.0, scale:Number = 1.0):void
		{
			// don't draw if we don't have valid coordinates
			if (isNaN(x) || isNaN(y))
				return;
			
			var scaledWidth:Number = scale * source.width;
			var scaledHeight:Number = scale * source.height;
			var floorX:Number = Math.floor(x) - int(scaledWidth / 2);
			var floorY:Number = Math.floor(y) - int(scaledHeight / 2);

			if (!isNaN(fillColor))
			{
				graphics.beginFill(fillColor, fillAlpha);
				graphics.drawRect(floorX, floorY, scaledWidth, scaledHeight);
				graphics.endFill();
			}
			
			tempMatrix.identity();
			tempMatrix.scale(scale, scale);
			tempMatrix.translate(floorX, floorY);
			
			graphics.beginBitmapFill(source, tempMatrix, false, true);
			graphics.drawRect(floorX, floorY, scaledWidth, scaledHeight);
			graphics.endFill();
		}
		
		/**
		 * This function will create a high quality thumbnail for a BitmapData.
		 * @param source A BitmapData to create a thumbnail for.
		 * @param width The maximum desired width of the result.
		 * @param height The maximum desired height of the result.
		 * @return A thumbnail version of the source BitmapData that fits within the specified width and height.
		 */
		public static function resizeBitmapData(source:BitmapData, width:uint, height:uint):BitmapData
		{
			// find target w,h with proper aspect ratio
			var scale:Number = Math.min(width/source.width, height/source.height);
			var w:int = Math.round(source.width * scale);
			var h:int = Math.round(source.height * scale);
			
			if (w <= 0 || h <= 0)
				return new BitmapData(0, 0);
			
			// upscale source width,height to the target w,h times a power of 2
			while (w < source.width || h < source.height)
				w *= 2, h *= 2;
			var result:BitmapData = new BitmapData(w, h);
			tempMatrix.identity();
			tempMatrix.scale(w/source.width, h/source.height);
			result.draw(source, tempMatrix, null, null, null, true);
			
			// scale down step by step with 0.5 scale to get the highest quality thumbnail possible
			tempMatrix.identity();
			tempMatrix.scale(0.5, 0.5);
			while (w > width || h > height)
			{
				var temp:BitmapData = new BitmapData(w/=2, h/=2);
				temp.draw(result, tempMatrix, null, null, null, true);
				result.dispose();
				result = temp;
			}

			return result;
		}
		/**
		 * This function gets a screenshot of a UIComponent and optionally creates a thumbnail version.
		 * @param component A component from which to get a screenshot.
		 * @param desiredWidth If > 0, the width of the thumbnail version.
		 * @param desiredHeight If > 0, the height of the thumbnail version.
		 * @return A screenshot of the component. If desired width or height is specified, a thumbnail version is returned.
		 */
		public static function getBitmapDataFromComponent(component:UIComponent, desiredWidth:int = 0, desiredHeight:int = 0):BitmapData
		{
			var screenshot:BitmapData = new BitmapData(component.width, component.height, true, 0x00000000);
			screenshot.draw(component);
			
			if (desiredWidth > 0 && desiredHeight > 0)
			{
				var result:BitmapData = resizeBitmapData(screenshot, desiredWidth, desiredHeight);
				screenshot.dispose();
				return result;
			}
			
			return screenshot;
		}
		
		/**
		 * This function accepts a component, gets its corresponding bitmap, and encodes the image as
		 * a base 64 string.
		 * @param component The component for which to get the string encoding.
		 * @return A base 64 encoding of the image.
		 */		
		public static function getBase64Image(component:UIComponent):String
		{
			// getBitmapDataFromComponent doesn't give a valid image that can be saved to disk
//			var data:BitmapData = getBitmapDataFromComponent(component);
//			var byteArray:ByteArray = new ByteArray();
//			byteArray.writeObject(data.getPixels(data.rect));
			
			var byteArray:ByteArray = ImageSnapshot.captureImage(component).data; 
			var encoder:Base64Encoder = new Base64Encoder();
			encoder.encodeBytes(byteArray);
			
			return encoder.drain();
		}
		
//		/**
//		 * This generates a JPEG screenshot of a component.
//		 * @param component The component from which to get a screenshot.
//		 * @param quality A quality value between 0 and 100.
//		 * @return A JPEG version of the screenshot, stored in a ByteArray.
//		 * @see mx.graphics.codec.JPEGEncoder
//		 */
//		public static function getJPEGFromComponent(component:UIComponent, quality:int = 100):ByteArray
//		{		
//			var bitmap:BitmapData = getBitmapDataFromComponent(component);
//			return new JPEGEncoder(quality).encode(bitmap);
//		}
		
		/**
		 * This generates a PNG screenshot of a component.
		 * @param component The component from which to get a screenshot.
		 * @return A PNG version of the screenshot, stored in a ByteArray.
		 */
		public static function getPNGFromComponent(component:UIComponent):ByteArray
		{		
			var bitmap:BitmapData = getBitmapDataFromComponent(component);
			return new PNGEncoder().encode(bitmap);
		}
	}
}
