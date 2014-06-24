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
	
	import mx.rpc.events.ResultEvent;
	
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.setSessionState;
	import weave.api.ui.IPlotTask;
	import weave.api.ui.IPlotter;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
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
		WeaveAPI.registerImplementation(IPlotter, ImageGlyphPlotter, "Image glyphs");
		
		public static var debug:Boolean = false;
		
		public function ImageGlyphPlotter()
		{
		}
		
		public const imageURL:AlwaysDefinedColumn = newLinkableChild(this, AlwaysDefinedColumn);
		public const imageSize:AlwaysDefinedColumn = newLinkableChild(this, AlwaysDefinedColumn);
		
		public const rotation:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const rotationOffset:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0, isFinite));
		public const dataInDegrees:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));

		private static const _urlToImageMap:Object = new Object(); // maps a url to a BitmapData
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
				var image:BitmapData = _urlToImageMap[_imageURL] as BitmapData;
				if (!image) // if there is no image yet...
				{
					// set a placeholder so it doesn't get downloaded again
					_urlToImageMap[_imageURL] = image = _missingImage;
					
					// download the image - this triggers callbacks when download completes or fails
					WeaveAPI.URLRequestUtils.getContent(this, new URLRequest(_imageURL), handleImageDownload, null, _imageURL);
				}
				
				// center the image at 0,0
				tempMatrix.identity();
				tempMatrix.translate(-image.width / 2, -image.height / 2);
				
				// scale the image
				var _imageSize:Number = imageSize.getValueFromKey(recordKey, Number);
				if (isFinite(_imageSize))
				{
					var _scale:Number = _imageSize / Math.max(image.width, image.height);
					if (isFinite(_scale))
						tempMatrix.scale(_scale, _scale);
					else
						_scale = 1;
				}
				
				// rotate the image around 0,0
				// undefined rotation = no rotation
				var _rotation:Number = rotation.getValueFromKey(recordKey, Number);
				if (!isFinite(_rotation))
					_rotation = 0;
				_rotation += rotationOffset.value;
				if (dataInDegrees.value)
					_rotation = _rotation * Math.PI / 180;
				var direction:Number = task.screenBounds.getYDirection() < 0 ? -1 : 1;
				if (_rotation != 0)
					tempMatrix.rotate(_rotation * direction);
				
				// translate the image
				// if there is no rotation, adjust to pixel coordinates to get a sharper image
				getCoordsFromRecordKey(recordKey, tempPoint);
				task.dataBounds.projectPointTo(tempPoint, task.screenBounds);
				var dx:Number = Math.round(tempPoint.x) + (_rotation == 0 && image.width % 2 ? 0.5 : 0);
				var dy:Number = Math.round(tempPoint.y) + (_rotation == 0 && image.height % 2 ? 0.5 : 0);
				tempMatrix.translate(dx, dy);
				
				// draw image
				task.buffer.draw(image, tempMatrix);
				
				return task.iteration / task.recordKeys.length;
			}
			return 1;
		}
		
		/**
		 * This function will save a downloaded image into the image cache.
		 */
		private function handleImageDownload(event:ResultEvent, url:String):void
		{
			var bitmap:Bitmap = event.result as Bitmap;
			_urlToImageMap[url] = bitmap.bitmapData;
			if (debug)
				trace(debugId(this), 'received', url, debugId(bitmap.bitmapData));
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
