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

package weave.primitives
{
	import flash.display.BitmapData;
	
	import mx.core.BitmapAsset;
	
	/**
	 * ImageFactory
	 * Use this class when you need an image Class but all you have is a BitmapData object.
	 * 
	 * @author adufilie
	 */
	public class ImageFactory extends BitmapAsset
	{
		public function ImageFactory()
		{
			super(
				_ImageFactoryCloneBitmapData ? _ImageFactoryBitmapData.clone() : _ImageFactoryBitmapData,
				_ImageFactoryPixelSnapping,
				_ImageFactorySmoothing
			);
		}
		
		// parameters for BitmapAsset constructor
		private static var _ImageFactoryBitmapData:BitmapData = null;
		private static var _ImageFactoryPixelSnapping:String = "auto";
		private static var _ImageFactorySmoothing:Boolean = false;

		// if true, constructor will clone _ImageFactoryBitmapData
		private static var _ImageFactoryCloneBitmapData:Boolean = false;

		/**
		 * getImageClass
		 * @param bitmapData Parameter for BitmapAsset constructor.
		 * @param pixelSnapping Parameter for BitmapAsset constructor.
		 * @param smoothing Parameter for BitmapAsset constructor.
		 * @param cloneBitmapData Set this to true if you want the ImageFactory class constructor to clone the bitmapData.
		 * @return The ImageFactory class, with its static parameters set.
		 */
		public static function getImageClass(bitmapData:BitmapData, pixelSnapping:String = "auto", smoothing:Boolean = false, cloneBitmapData:Boolean = false):Class
		{
			_ImageFactoryBitmapData = bitmapData;
			_ImageFactoryPixelSnapping = pixelSnapping;
			_ImageFactorySmoothing = smoothing;
			_ImageFactoryCloneBitmapData = cloneBitmapData;
			return ImageFactory;
		}
	}
}
