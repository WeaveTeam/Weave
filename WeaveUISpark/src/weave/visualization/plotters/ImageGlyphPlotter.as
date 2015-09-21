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

package weave.visualization.plotters
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.Weave;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.api.setSessionState;
	import weave.api.data.IQualifiedKey;
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
		WeaveAPI.ClassRegistry.registerImplementation(IPlotter, ImageGlyphPlotter, "Image glyphs");
		
		public static var debug:Boolean = false;
		
		public function ImageGlyphPlotter()
		{
			color.internalDynamicColumn.target = Weave.defaultColorColumn;
		}
		
		public const color:AlwaysDefinedColumn = newLinkableChild(this, AlwaysDefinedColumn);
		public const alpha:AlwaysDefinedColumn = newLinkableChild(this, AlwaysDefinedColumn);
		
		public const imageURL:AlwaysDefinedColumn = newLinkableChild(this, AlwaysDefinedColumn);
		public const imageSize:AlwaysDefinedColumn = newLinkableChild(this, AlwaysDefinedColumn);
		
		public const rotation:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const rotationOffset:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0, isFinite));
		public const dataInDegrees:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		public const reverseRotation:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));

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
				
				// stop if there is no url
				if  (!_imageURL)
					return task.iteration / task.recordKeys.length;
				
				var image:BitmapData = _urlToImageMap[_imageURL] as BitmapData;
				if (!image) // if there is no image yet...
				{
					// set a placeholder so it doesn't get downloaded again
					_urlToImageMap[_imageURL] = image = _missingImage;
					
					// download the image - this triggers callbacks when download completes or fails
					WeaveAPI.URLRequestUtils.getContent(this, new URLRequest(_imageURL), handleImageDownload, handleImageFault, _imageURL);
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
				if (reverseRotation.value)
					direction = -direction;
				if (_rotation != 0)
					tempMatrix.rotate(_rotation * direction);
				
				// translate the image
				// if there is no rotation, adjust to pixel coordinates to get a sharper image
				getCoordsFromRecordKey(recordKey, tempPoint);
				task.dataBounds.projectPointTo(tempPoint, task.screenBounds);
				var dx:Number = Math.round(tempPoint.x) + (_rotation == 0 && image.width % 2 ? 0.5 : 0);
				var dy:Number = Math.round(tempPoint.y) + (_rotation == 0 && image.height % 2 ? 0.5 : 0);
				tempMatrix.translate(dx, dy);
				
				var ct:ColorTransform = tempColorTransform;
				var color:Number = this.color.getValueFromKey(recordKey, Number);
				if (isFinite(color))
				{
					const R:int = 0xFF0000;
					const G:int = 0x00FF00;
					const B:int = 0x0000FF;

					ct.redMultiplier = ((color & R) >> 16) / 255;
					ct.greenMultiplier = ((color & G) >> 8) / 255;
					ct.blueMultiplier = (color & B) / 255;
				}
				else
				{
					ct.redMultiplier = 1;
					ct.greenMultiplier = 1;
					ct.blueMultiplier = 1;
				}
				ct.alphaMultiplier = alpha.getValueFromKey(recordKey, Number);
				
				// draw image
				task.buffer.draw(image, tempMatrix, ct, null, null, true);
				
				return task.iteration / task.recordKeys.length;
			}
			return 1;
		}
		
		private const tempColorTransform:ColorTransform = new ColorTransform();
		
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
		private function handleImageFault(event:FaultEvent, url:String):void
		{
			event.fault.content = url;
			reportError(event);
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
