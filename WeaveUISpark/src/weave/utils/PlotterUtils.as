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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	
	import weave.api.disposeObjects;

	/**
	 * PlotterUtils
	 * This is an all-static class containing functions that are useful when working with IPlotter objects.
	 * 
	 * @author adufilie
	 */
	public class PlotterUtils
	{
		/**
		 * @param bitmap A Bitmap to check.
		 * @return true if the BitmapData of the given bitmap is empty.
		 */
		public static function bitmapDataIsEmpty(bitmap:Bitmap):Boolean
		{
			var bitmapData:BitmapData = bitmap.bitmapData;
			try
			{
				// this may throw an error if bitmapData.dispose() was called.
				return bitmapData.width == 0 || bitmapData.height == 0;
			}
			catch (e:Error) { }
			return true; // error == empty
		}
		
		/**
		 * This will dispose of any existing BitmapData inside a Bitmap and set it to null.
		 * @param bitmap The Bitmap to empty.
		 */
		public static function emptyBitmapData(bitmap:Bitmap):void
		{
			if (bitmap.bitmapData)
			{
				disposeObjects(bitmap.bitmapData);
				bitmap.bitmapData = null;
			}
		}
		
		/**
		 * This will compare width and height values with the width and height of a BitmapData object inside a Bitmap.
		 * @param bitmap
		 * @param unscaledWidth
		 * @param unscaledHeight
		 * @return true if the width and height of bitmap.bitmapData equal the unscaledWidth and unscaledHeight parameters. 
		 */		
		public static function bitmapDataSizeEquals(bitmap:Bitmap, unscaledWidth:Number, unscaledHeight:Number):Boolean
		{
			var bd:BitmapData = bitmap.bitmapData;
			return bd && bd.width == Math.round(unscaledWidth) && bd.height == Math.round(unscaledHeight);
		}
		
		/**
		 * This function updates the size of the BitmapData inside a Bitmap.
		 * The new or existing BitmapData will be filled with the specified fill color.
		 * @param bitmap A Bitmap object to alter.
		 * @param unscaledWidth The desired width of the BitmapData.
		 * @param unscaledHeight The desired height of the BitmapData.
		 * @param fillColor The BitmapData will be filled with this color.
		 * @return true if the BitmapData was replaced with a new one having the new size, false if the size was not changed.
		 */
		public static function setBitmapDataSize(bitmap:Bitmap, unscaledWidth:Number, unscaledHeight:Number, fillColor:uint = 0x00000000):Boolean
		{
			unscaledWidth = Math.round(unscaledWidth);
			unscaledHeight = Math.round(unscaledHeight);
			
			var result:Boolean = false;
			var oldBitmapData:BitmapData = bitmap.bitmapData;
			var sizeChanged:Boolean = true;
			try
			{
				// this may crash if the BitmapData is invalid.
				sizeChanged = (oldBitmapData == null || oldBitmapData.width != unscaledWidth || oldBitmapData.height != unscaledHeight);
			}
			catch (e:Error)
			{
				// invalid BitmapData, ignore error
			}
			// update size of internal BitmapData if necessary
			if (sizeChanged)
			{
				try
				{
					var newBitmapData:BitmapData = new BitmapData(unscaledWidth, unscaledHeight, true, fillColor);
					//trace("new BitmapData(",[unscaledWidth, unscaledHeight, true, 0x00000000],");");
					// dispose of oldBitmapData, if any exists
					if (oldBitmapData != null)
						disposeObjects(oldBitmapData);
					// connect Bitmap to newBitmapData
					bitmap.bitmapData = newBitmapData;
					result = true;
				}
				catch (e:Error)
				{
					if (unscaledWidth >= 1 && unscaledHeight >= 1)
						trace("PlotterUtils: Warning! Unscaled area too large to store in a Bitmap: "+[unscaledWidth, unscaledHeight]);
				}
			}
			else
			{
				_tempRect.x = 0;
				_tempRect.y = 0;
				_tempRect.width = unscaledWidth;
				_tempRect.height = unscaledHeight;
				bitmap.bitmapData.fillRect(_tempRect, fillColor);
			}
			return result;
		}
		
		private static const _tempRect:Rectangle = new Rectangle();
		
		/**
		 * This function will make reset all the pixels in a BitmapData object to be transparent.
		 * @param bitmapOrBitmapData A Bitmap or BitmapData object to clear.
		 */
		public static function clearBitmapData(bitmapOrBitmapData:Object):void
		{
			var bd:BitmapData = (bitmapOrBitmapData is Bitmap) ? (bitmapOrBitmapData as Bitmap).bitmapData : (bitmapOrBitmapData as BitmapData);
			if (bd == null || bd.width == 0 || bd.height == 0)
				return;
			// clear the graphics
			bd.fillRect(bd.rect, 0x00000000); // transparent
		}
		
		public static function alphaSliderFormatFunction(value:Number):String
		{
			return lang("{0}% Opaque", int(value * 100)) + "\n" + lang("{0}% Transparent", int(100 - value * 100));
		}
	}
}
