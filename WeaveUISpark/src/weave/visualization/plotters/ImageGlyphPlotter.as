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
	import mx.utils.StringUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IQualifiedKey;
	import weave.api.linkSessionState;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.setSessionState;
	import weave.api.ui.IPlotTask;
	import weave.api.ui.IPlotter;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.ImageColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.KeySets.FilteredKeySet;
	
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
		
		public const imageCol:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const imageURL:LinkableString = newLinkableChild(this, LinkableString);
		public const imageSize:LinkableNumber = registerLinkableChild(this, new LinkableNumber(100));
		
		public const rotationCol:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const rotationOffset:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0));
		public const dataInDegrees:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		
		private const tempMatrix:Matrix = new Matrix(); // reusable object
		private static const _urlToImageMap:Object = new Object();
		
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
				var _imageURLColVal:String = imageCol.getValueFromKey(recordKey, String);
				var _rotationColVal:Number = rotationCol.getValueFromKey(recordKey, Number);
				
				_imageURLColVal = ( _imageURLColVal == null || StringUtil.trim(_imageURLColVal).length == 0 ) ? imageURL.value : _imageURLColVal;
				_rotationColVal = isNaN(_rotationColVal) ? 0 : _rotationColVal;

				var _image:BitmapData = _urlToImageMap[_imageURLColVal] as BitmapData;
				if( _image )
				{
					getCoordsFromRecordKey(recordKey, tempPoint);
					task.dataBounds.projectPointTo(tempPoint, task.screenBounds);
				
					var scaleX:Number = imageSize.value / 100;
					var scaleY:Number = imageSize.value / 100;
					
					tempMatrix.identity();
					tempMatrix.translate(-_image.width/2, -_image.height/2);
	
					
					// Scale
					if( isFinite(scaleX) && isFinite(scaleY) )
						tempMatrix.scale(scaleX, scaleY);
					
					
					// Rotate
					_rotationColVal -= rotationOffset.value;
					if( dataInDegrees.value )
						_rotationColVal = Math.PI * _rotationColVal / 180;
					tempMatrix.rotate(_rotationColVal);
					
					
					// Reposition
					tempMatrix.translate(tempPoint.x, tempPoint.y);
					
					
					// Draw
					task.buffer.draw(_image, tempMatrix);
				}
				else
				{
					_urlToImageMap[_imageURLColVal] = _missingImage;
					
					WeaveAPI.URLRequestUtils.getContent(this, new URLRequest(_imageURLColVal), handleImageDownload, null, _imageURLColVal);
				}
				
				return task.iteration / task.recordKeys.length;
			}

			return 1;
		}
		
		private function handleImageDownload(event:ResultEvent, url:String):void
		{
			var bitmap:Bitmap = event.result as Bitmap;
			_urlToImageMap[url] = bitmap.bitmapData;
			if( debug )
				trace(debugId(this), "received", url, debugId(bitmap.bitmapData));
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
