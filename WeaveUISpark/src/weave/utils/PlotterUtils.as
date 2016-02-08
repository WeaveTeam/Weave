/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.utils
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	
	import weave.api.disposeObject;

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
		 * This will dispose any existing BitmapData inside a Bitmap and set it to null.
		 * @param bitmap The Bitmap to empty.
		 */
		public static function emptyBitmapData(bitmap:Bitmap):void
		{
			if (bitmap.bitmapData)
			{
				disposeObject(bitmap.bitmapData);
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
			try
			{
				// accessing width/height may crash if the BitmapData is invalid.
				var bd:BitmapData = bitmap.bitmapData;
				return bd
					&& bd.width == Math.round(unscaledWidth)
					&& bd.height == Math.round(unscaledHeight);
			}
			catch (e:Error)
			{
				// invalid BitmapData, ignore error
			}
			return false;
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
			// avoid comparing integers to non-integers
			unscaledWidth = Math.round(unscaledWidth);
			unscaledHeight = Math.round(unscaledHeight);
			
			var result:Boolean = false;
			var oldBitmapData:BitmapData = bitmap.bitmapData;
			var sizeChanged:Boolean = true;
			try
			{
				// this may crash if the BitmapData is invalid.
				sizeChanged = (
					oldBitmapData == null
					|| oldBitmapData.width != unscaledWidth
					|| oldBitmapData.height != unscaledHeight
				);
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
					// dispose oldBitmapData, if any exists
					if (oldBitmapData != null)
						disposeObject(oldBitmapData);
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
			return lang("{0}% Opaque", Math.round(value * 100)) + "\n" + lang("{0}% Transparent", Math.round(100 - value * 100));
		}
	}
}
