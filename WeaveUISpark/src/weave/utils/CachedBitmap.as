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
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	/**
	 * A structure containing a cached BitmapData rendering of a DisplayObject.
	 */
	public class CachedBitmap
	{
		/**
		 * Renders the supplied DisplayObject to a BitmapData and saves it.
		 * @param obj The object to render.
		 */
		public function CachedBitmap(obj:DisplayObject)
		{
			var bounds:Rectangle = obj.getBounds(obj);
			// expand rectangle to use integer boundaries.
			bounds.width = Math.ceil(bounds.width + bounds.x - Math.floor(bounds.x));
			bounds.height = Math.ceil(bounds.height + bounds.y - Math.floor(bounds.y));
			bounds.x = Math.floor(bounds.x);
			bounds.y = Math.floor(bounds.y);
			// create a transparent bitmap to contain the graphics
			bitmapData = new BitmapData(bounds.width, bounds.height, true, 0x00000000);
			// adjust matrix so the graphics will fit completely on the bitmap
			xOffset = bounds.x;
			yOffset = bounds.y;
			bitmapRect = bitmapData.rect;
			tempMatrix.identity();
			tempMatrix.translate(-xOffset, -yOffset);
			bitmapData.draw(obj, tempMatrix);
		}
		
		/**
		 * The cached BitmapData.
		 */
		public var bitmapData:BitmapData;
		
		/**
		 * A cached Rectangle derived from bitmapData.rect.
		 */
		public var bitmapRect:Rectangle;
		
		/**
		 * The X offset in pixels which is required to render the cached image at the correct location.
		 */
		public var xOffset:int;
		
		/**
		 * The X offset in pixels which is required to render the cached image at the correct location.
		 */
		public var yOffset:int;
		
		/**
		 * Copies the pixels from the cached BitmapData onto a destination BitmapData.
		 * @param destination The BitmapData onto which the cached BitmapData will be copied.
		 * @param x The X position at which the cached BitmapData should be rendered.
		 * @param y The Y position at which the cached BitmapData should be rendered.
		 */
		public function drawTo(destination:BitmapData, x:Number, y:Number):void
		{
			tempPoint.x = x + xOffset;
			tempPoint.y = y + yOffset;
			destination.copyPixels(bitmapData, bitmapRect, tempPoint, null, null, true);
		}
		
		/**
		 * This function should be called when the CachedBitmap is no longer needed.
		 */
		public function dispose():void
		{
			if (bitmapData)
				bitmapData.dispose();
			bitmapData = null;
			bitmapRect = null;
		}
		
		private static const tempMatrix:Matrix = new Matrix();
		private static const tempPoint:Point = new Point();
	}
}
