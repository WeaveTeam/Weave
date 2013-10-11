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
	import flash.net.URLRequest;
	
	import mx.rpc.events.ResultEvent;
	
	import weave.api.WeaveAPI;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.setSessionState;
	import weave.api.ui.IPlotTask;
	import weave.api.ui.IPlotter;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	
	/**
	 * ImagePlotter
	 * 
	 * @author adufilie
	 * @author jfallon
	 * @author pstickney
	 */
	public class ImageGlyphPlotter extends AbstractGlyphPlotter
	{
		WeaveAPI.registerImplementation(IPlotter, ImageGlyphPlotter, "Image glyphs");
		
		public function ImageGlyphPlotter()
		{
		}
		
		public const imageURL:AlwaysDefinedColumn = newLinkableChild(this, AlwaysDefinedColumn);
		public const imageSize:AlwaysDefinedColumn = newLinkableChild(this, AlwaysDefinedColumn);
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
				getCoordsFromRecordKey(recordKey, tempPoint);
				task.dataBounds.projectPointTo(tempPoint, task.screenBounds);
				
				var image:BitmapData = _urlToImageMap[_imageURL] as BitmapData;
				if (image)
				{
					// translate image so it is centered on the screen coordinates of this record
					tempMatrix.identity();
					var sx:Number = 1 / image.width * _imageSize;
					var sy:Number = 1 / image.height * _imageSize;
					if (isFinite(sx) && isFinite(sy))
						tempMatrix.scale(sx, sy);
					else
						sx = 1, sy = 1;
					tempMatrix.translate(
							Math.round(tempPoint.x - sx * image.width / 2),
							Math.round(tempPoint.y - sy * image.height / 2)
						);
					// draw image
					task.buffer.draw(image, tempMatrix);
				}
				else // if the url hasn't started downloading yet...
				{
					// set a placeholder so it doesn't get downloaded again
					_urlToImageMap[_imageURL] = _missingImage;
					
					// download the image - this triggers callbacks when download completes or fails
					WeaveAPI.URLRequestUtils.getContent(this, new URLRequest(_imageURL), handleImageDownload, null, _imageURL);
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
		private function handleImageDownload(event:ResultEvent, url:String):void
		{
			var bitmap:Bitmap = event.result as Bitmap;
			_urlToImageMap[url] = bitmap.bitmapData;
		}
		
		[Deprecated] public function set xColumn(value:Object):void
		{
			setSessionState(dataX, value);
		}
		[Deprecated] public function set yColumn(value:Object):void
		{
			setSessionState(dataY, value);
		}
	}
}
