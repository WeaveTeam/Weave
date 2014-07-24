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
	import flash.display.DisplayObject;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import weave.api.core.IDisposableObject;
	import weave.compiler.Compiler;

	public dynamic class GlyphCache implements IDisposableObject
	{
		/**
		 * The name of the property of a cache entry which contains the BitmapData.
		 */
		public static const BITMAP:String = 'bitmap';
		/**
		 * The name of the property of a cache entry which contains the Matrix that
		 * will position the glyph BitmapData appropriately.
		 */
		public static const MATRIX:String = 'matrix';
		
		public function GlyphCache()
		{
		}
		
		/**
		 * method -> Object(stringified_params -> Glyph)
		 */
		private var cache:Dictionary = new Dictionary();
		
		/**
		 * Calls a method with the given parameters, unless there is already a cached result for those parameters.
		 * @param method The method to call, which must return a DisplayObject.
		 *               The glyph should be rendered on the DisplayObject at coordinates (0, 0).
		 * @param methodParams Parameters to pass to the method given in the constructor.
		 *                     The parameters must consist of values that can stringified to JSON.
		 * @return A cache entry containing a BitmapData and Matrix generated from result of the method.
		 */
		public function getCacheEntry(method:Function, methodParams:Array):Glyph
		{
			// get the Glyph cache corresponding to the method
			var glyphCache:Object = cache[method];
			if (!glyphCache)
				cache[method] = glyphCache = {};
			
			// get the Glyph corresponding to the methodParams
			var str:String = Compiler.stringify(methodParams)
			var glyph:Glyph = glyphCache[str];
			if (!glyph)
			{
				glyphCache[str] = glyph = new Glyph();
				
				var obj:DisplayObject = method.apply(null, methodParams);
				var rect:Rectangle = obj.getBounds(obj);
				// expand rectangle to use integer boundaries.
				rect.width = Math.ceil(rect.width + rect.x - Math.floor(rect.x));
				rect.height = Math.ceil(rect.height + rect.y - Math.floor(rect.y));
				rect.x = Math.floor(rect.x);
				rect.y = Math.floor(rect.y);
				// create a transparent bitmap to contain the graphics
				glyph.bitmap = new BitmapData(rect.width, rect.height, true, 0x00000000);
				// adjust matrix so the graphics will fit completely on the bitmap
				glyph.dx = rect.x;
				glyph.dy = rect.y;
				glyph.rect = glyph.bitmap.rect;
				tempMatrix.identity();
				tempMatrix.translate(-glyph.dx, -glyph.dy);
				glyph.bitmap.draw(obj, tempMatrix);
			}
			
			return glyph;
		}
		
		private var tempMatrix:Matrix = new Matrix();
		private var tempPoint:Point = new Point();
		
		/**
		 * @param cacheEntry The cache entry to draw.
		 */
		public function drawGlyph(cacheEntry:*, destination:BitmapData, x:Number, y:Number):void
		{
			var glyph:Glyph = cacheEntry;
			tempPoint.x = glyph.dx + x;
			tempPoint.y = glyph.dy + y;
			destination.copyPixels(glyph.bitmap, glyph.rect, tempPoint, null, null, true);
		}
		
		public function dispose():void
		{
			for (var key:* in cache)
				for each (var glyph:Glyph in cache[key])
					(glyph[BITMAP] as BitmapData).dispose();
			cache = null;
		}
	}
}

import flash.display.BitmapData;
import flash.geom.Rectangle;

internal class Glyph
{
	public var bitmap:BitmapData;
	public var dx:int;
	public var dy:int;
	public var rect:Rectangle;
}
