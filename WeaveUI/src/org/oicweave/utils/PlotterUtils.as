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

package org.oicweave.utils
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	
	import org.oicweave.primitives.Bounds2D;
	import org.oicweave.api.ui.IPlotter;

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
		 * This function updates the size of the BitmapData inside a Bitmap.
		 * If the BitmapData inside the Bitmap is already the right size, this function has no effect.
		 * @param bitmap A Bitmap object to alter.
		 * @param unscaledWidth The desired width of the BitmapData.
		 * @param unscaledHeight The desired height of the BitmapData.
		 * @return true if the BitmapData was replaced with a new one having the new size, false if the size was not changed.
		 */
		public static function setBitmapDataSize(bitmap:Bitmap, unscaledWidth:Number, unscaledHeight:Number):Boolean
		{
			unscaledWidth = Math.round(unscaledWidth);
			unscaledHeight = Math.round(unscaledHeight);
			
			var result:Boolean = false;
			var oldBitmapData:BitmapData = bitmap.bitmapData;
			// update size of internal BitmapData if necessary
			if (oldBitmapData == null || oldBitmapData.width != unscaledWidth || oldBitmapData.height != unscaledHeight)
			{
				try
				{
					var newBitmapData:BitmapData = new BitmapData(unscaledWidth, unscaledHeight, true, 0x00000000);
					//trace("new BitmapData(",[unscaledWidth, unscaledHeight, true, 0x00000000],");");
					// dispose of oldBitmapData, if any exists
					if (oldBitmapData != null)
						oldBitmapData.dispose();
					// connect Bitmap to newBitmapData
					bitmap.bitmapData = newBitmapData;
					result = true;
				}
				catch (e:Error)
				{
					if (unscaledWidth >= 1 && unscaledHeight >= 1)
						trace("Warning! Unscaled area too large to store in a Bitmap: "+[unscaledWidth, unscaledHeight]);
				}
			}
			return result;
		}
		
		/**
		 * This function will make reset all the pixels in a BitmapData object to be transparent.
		 * @param destination A BitmapData object to clear.
		 */
		public static function clear(destination:BitmapData):void
		{
			if (destination == null || destination.width == 0 || destination.height == 0)
				return;
			// clear the graphics
			destination.fillRect(destination.rect, 0x00000000); // transparent
		}
	}
}
