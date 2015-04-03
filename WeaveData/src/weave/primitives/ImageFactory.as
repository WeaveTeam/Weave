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
