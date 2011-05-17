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

package weave.services.wms
{
	import flash.display.BitmapData;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import weave.api.WeaveAPI;
	import weave.api.primitives.IBounds2D;
	import weave.api.services.IURLRequestToken;
	import weave.api.services.IURLRequestUtils;
	import weave.primitives.Bounds2D;

	/**
	 * This class describes a tile used by a WMS server.
	 * A tile is defined by its bounds and zoom level.
	 * 
	 * @author kmonico
	 */
	public class WMSTile 
	{
		/**
		 * @param newBounds The bounding box of the tile.
		 * @param imageWidth The width of the image in pixels.
		 * @param imageHeight The height of the image in pixels.
		 * @param request The URLRequest for the bitmap image.
		 * @param bitmapData The BitmapData for the image. This defaults to null.
		 */
		public function WMSTile(newBounds:IBounds2D, imageWidth:int, imageHeight:int, request:URLRequest, bitmapData:BitmapData = null)
		{
			_bounds.copyFrom(newBounds);
			_imageWidth = imageWidth;
			_imageHeight = imageHeight;
			_urlRequest = request;
			_bitmapData = bitmapData;
			_zoomLevel = bounds.getArea() / (_imageWidth * _imageHeight);
		}

		/**
		 * This is the zoom level of the tile. This defaults to 
		 * {area of bounds} / {area of image}
		 */
		private var _zoomLevel:Number = NaN;
		
		/**
		 * This is the bounding box of the tile.
		 */
		private const _bounds:IBounds2D = new Bounds2D();
		
		/**
		 * This is the height of the tile's bitmap.
		 */
		private var _imageHeight:int = 0;
		
		/**
		 * This is the width of the tile's bitmap.
		 */
		private var _imageWidth:int = 0;
		
		/**
		 * This is the URLRequest.
		 */
		private var _urlRequest:URLRequest = null;
		
		/**
		 * This is the token associated with the HTTP get request for this specific tile.
		 */
		private var _urlRequestToken:IURLRequestToken = null;
		
		/**
		 * This is the bitmap downloaded from the urlLoader.
		 */
		private var _bitmapData:BitmapData = null;
		

		/**
		 * Set the bitmapData for this WMSTile.
		 */
		public function set bitmapData(value:BitmapData):void
		{
			_bitmapData = value;
		}
		
		/**
		 * Get the URLRequest for this tile.
		 */
		public function get request():URLRequest
		{
			return _urlRequest;
		}
		
		/**
		 * Get the bitmap data downloaded from this tile's urlLoader.
		 */
		public function get bitmapData():BitmapData
		{
			return _bitmapData;
		}
		
		/**
		 * Return the bounds.
		 */
		public function get bounds():IBounds2D
		{
			return _bounds;
		}

		/**
		 * This function gets the zoom level of this tile. By default, the zoom level is 
		 * defined as the area of the bounding box divided by the pixel area 
		 * of the image. The zoom level may be manually set.
		 */
		public function get zoomLevel():Number
		{
			if (isNaN(_zoomLevel) == false)
				return _zoomLevel;
			
			return _bounds.getArea() / (_imageWidth * _imageHeight);
		}
		
		/**
		 * This function sets the zoom level for this tile.
		 */
		public function set zoomLevel(val:Number):void
		{
			_zoomLevel = val;
		}
		
		/**
		 * Return the width of the image for this tile.
		 */
		public function get imageWidth():int
		{
			return _imageWidth;
		}
		
		/**
		 * Return the height of the image for this tile.
		 */
		public function get imageHeight():int
		{
			return _imageHeight;
		}
		
		/**
		 * Cancel the URL request for this tile.
		 */
		public function cancelDownload():void
		{
			if (_urlRequestToken)
				_urlRequestToken.cancelRequest();
			_urlRequestToken = null;
		}
		
		/**
		 * This function downloads an image.
		 * 
		 * @param resultFunction The function to call on a download success. The signature is 
		 *        resultFunction(event:ResultEvent, token:Object):void
		 * @param faultFunction The function to call on an error. The signature is
		 *        faultFunction(event:FaultEvent, token:Object):void
		 */
		public function downloadImage(resultFunction:Function, faultFunction:Function, token:Object = null):void
		{
			cancelDownload();
			_urlRequestToken = _urlRequestUtils.getContent(_urlRequest, resultFunction, faultFunction, token);
		}
		
		private static const _urlRequestUtils:IURLRequestUtils = WeaveAPI.URLRequestUtils;
	}
}
