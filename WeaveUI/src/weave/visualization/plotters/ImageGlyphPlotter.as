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

package weave.visualization.plotters
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IPlotTask;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	
	/**
	 * ImagePlotter
	 * 
	 * @author adufilie
	 * @author jfallon
	 * @author pstickney
	 */
	public class ImageGlyphPlotter extends AbstractGlyphPlotter
	{
		public function ImageGlyphPlotter()
		{
			init();
		}
		private function init():void
		{
		}
		
		public function get xColumn():DynamicColumn { return dataX; }
		public function get yColumn():DynamicColumn { return dataY; }
		
		public const imageURL:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn( "arrowRight.png" ));
		public const imageSize:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn( 32 ));
		private const tempPoint:Point = new Point(); // reusable object
		private const tempMatrix:Matrix = new Matrix(); // reusable object

		[Embed(source="/weave/resources/images/missing.png")]
		private static var _missingImageClass:Class;
		private static const _missingImage:BitmapData = Bitmap(new _missingImageClass()).bitmapData;

		/**
		 * Draws the graphics onto BitmapData.
		 */
		override public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			if (task.iteration < task.recordKeys.length)
			{
				var recordKey:IQualifiedKey = task.recordKeys[task.iteration] as IQualifiedKey;
				var _imageURL:String = imageURL.getValueFromKey(recordKey, String) as String;
				var _imageSize:Number = imageSize.getValueFromKey(recordKey, Number);
				if (isNaN(_imageSize))
					_imageSize = 32;
				tempPoint.x = dataX.getValueFromKey(recordKey, Number);
				tempPoint.y = dataY.getValueFromKey(recordKey, Number);
				task.dataBounds.projectPointTo(tempPoint, task.screenBounds);
				
				var image:BitmapData = _urlToImageMap[_imageURL] as BitmapData;
				if (image != null)
				{
					// translate image so it is centered on the screen coordinates of this record
					tempMatrix.identity();
					var sx:Number = 1 / image.width * _imageSize;
					var sy:Number = 1 / image.height * _imageSize;
					tempMatrix.scale(sx, sy);
					tempMatrix.translate(
							Math.round(tempPoint.x - _imageSize / 2),
							Math.round(tempPoint.y - _imageSize / 2)
						);
					// draw image
					task.buffer.draw(image, tempMatrix);
				}
				else if (_urlToImageMap[_imageURL] == undefined) // if the url hasn't started downloading yet...
				{
					// set a placeholder so it doesn't get downloaded again
					_urlToImageMap[_imageURL] = _missingImage;
					
					// download the image
//					WeaveAPI.URLRequestUtils.getContent(this, new URLRequest(_imageURL), handleImageDownload, handleFault, _imageURL);
					
					// get all images hack
					WeaveAPI.URLRequestUtils.getImage(this, new URLRequest(_imageURL), handleImageDownload, handleFault, _imageURL);
				}
				
				return task.iteration / task.recordKeys.length;
			}
			return 1;
		}
		
		/**
		 * This is the image cache.
		 */
		private static const _urlToImageMap:Object = new Object(); // maps a url to a BitmapData
		/**
		 * This function will save a downloaded image into the image cache.
		 */
		private function handleImageDownload(event:ResultEvent, token:Object = null):void
		{
			var bitmap:Bitmap = event.result as Bitmap;
			_urlToImageMap[token] = bitmap.bitmapData;
			getCallbackCollection(this).triggerCallbacks();
		}
		
		/**
		 * This function is called when there is an error downloading an image.
		 */
		private function handleFault(event:FaultEvent, token:Object=null):void
		{
			trace("Error downloading image:", ObjectUtil.toString(event.message), token);
			
			_urlToImageMap[token] = _missingImage;
			getCallbackCollection(this).triggerCallbacks();
		}
	}
}
