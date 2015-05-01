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
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	
	import mx.core.BitmapAsset;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.core.ILinkableObjectWithNewProperties;
	import weave.api.detectLinkableObjectChange;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.objectWasDisposed;
	import weave.api.primitives.IBounds2D;
	import weave.api.reportError;
	import weave.api.ui.IPlotter;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.primitives.Bounds2D;
	import weave.utils.BitmapText;

	/**
	 * A plotter for drawing a single image onto a tool.
	 *  
	 * @author skolman
	 * @author kmonico
	 */	
	public class SingleImagePlotter extends AbstractPlotter implements ILinkableObjectWithNewProperties
	{
		WeaveAPI.ClassRegistry.registerImplementation(IPlotter, SingleImagePlotter, "Single image");
		
		public function SingleImagePlotter()
		{
		}
		
		public function set defaultImage(value:BitmapData):void
		{
			if (_bitmapData == MISSING_IMAGE || _bitmapData == _defaultImage)
				_bitmapData = value;
			_defaultImage = value;
		}
		
		private var _defaultImage:BitmapData;
		
		// these vars store info on the image
		private var _bitmapData:BitmapData = MISSING_IMAGE;
		private var _imgScreenBounds:Bounds2D = new Bounds2D();
		private var _imgDataBounds:Bounds2D = new Bounds2D();
		
		private var _tempMatrix:Matrix = new Matrix();
		private var _tempPoint:Point = new Point();
		
		/**
		 * The URL of the image to download.
		 */
		public const imageURL:LinkableString = newLinkableChild(this, LinkableString);
		
		public const dataX:LinkableNumber = newSpatialProperty(LinkableNumber);
		public const dataY:LinkableNumber = newSpatialProperty(LinkableNumber);
		public const dataWidth:LinkableNumber = newSpatialProperty(LinkableNumber);
		public const dataHeight:LinkableNumber = newSpatialProperty(LinkableNumber);
		public const useImageSize:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(false));

		public const horizontalAlign:LinkableString = registerSpatialProperty(new LinkableString(BitmapText.HORIZONTAL_ALIGN_CENTER, verifyHAlign));
		public const verticalAlign:LinkableString = registerSpatialProperty(new LinkableString(BitmapText.VERTICAL_ALIGN_MIDDLE, verifyVAlign));
		
		private function verifyHAlign(value:String):Boolean
		{
			return value == BitmapText.HORIZONTAL_ALIGN_LEFT
				|| value == BitmapText.HORIZONTAL_ALIGN_CENTER
				|| value == BitmapText.HORIZONTAL_ALIGN_RIGHT;
		}
		private function verifyVAlign(value:String):Boolean
		{
			return value == BitmapText.VERTICAL_ALIGN_TOP
				|| value == BitmapText.VERTICAL_ALIGN_MIDDLE
				|| value == BitmapText.VERTICAL_ALIGN_BOTTOM;
		}
		
		private function getImageDataWidth():Number
		{
			if (useImageSize.value)
				return _bitmapData ? _bitmapData.width : 0;
			return dataWidth.value || 0
		}
		
		private function getImageDataHeight():Number
		{
			if (useImageSize.value)
				return _bitmapData ? _bitmapData.height : 0;
			return dataHeight.value || 0
		}
		
		override public function getBackgroundDataBounds(output:IBounds2D):void
		{
			var x:Number = dataX.value;
			var y:Number = dataY.value;
			var w:Number = getImageDataWidth();
			var h:Number = getImageDataHeight();
			
			if (horizontalAlign.value == BitmapText.HORIZONTAL_ALIGN_LEFT)
				output.setXRange(x, x + w);
			if (horizontalAlign.value == BitmapText.HORIZONTAL_ALIGN_CENTER)
				output.setCenteredXRange(x, w);
			if (horizontalAlign.value == BitmapText.HORIZONTAL_ALIGN_RIGHT)
				output.setXRange(x - w, x);
			
			if (verticalAlign.value == BitmapText.VERTICAL_ALIGN_TOP)
				output.setYRange(y - h, y);
			if (verticalAlign.value == BitmapText.VERTICAL_ALIGN_MIDDLE)
				output.setCenteredYRange(y, h);
			if (verticalAlign.value == BitmapText.VERTICAL_ALIGN_BOTTOM)
				output.setYRange(y, y + h);
		}
		
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			if (detectLinkableObjectChange(drawBackground, imageURL))
			{
				if (imageURL.value)
				{
					_bitmapData = null;
					WeaveAPI.URLRequestUtils.getContent(this, new URLRequest(imageURL.value), handleImage, handleImageFault, imageURL.value);
				}
				else
				{
					_bitmapData = _defaultImage || MISSING_IMAGE;
				}
			}
			
			if (!_bitmapData)
				return;
			
			var tempPoint:Point = new Point(dataX.value, dataY.value);
			dataBounds.projectPointTo(tempPoint, screenBounds);
			
			_tempMatrix.identity();
			
			var xOffset:Number = 0;
			var yOffset:Number = 0;
			
			switch (horizontalAlign.value)
			{
				case BitmapText.HORIZONTAL_ALIGN_LEFT: // x is aligned to left side of text
					xOffset = 0;
					break;
				case BitmapText.HORIZONTAL_ALIGN_CENTER: 
					xOffset = -_bitmapData.width / 2;
					break;
				case BitmapText.HORIZONTAL_ALIGN_RIGHT: // x is aligned to right side of text
					xOffset = -_bitmapData.width;
					break;
			}
			switch (verticalAlign.value)
			{
				case BitmapText.VERTICAL_ALIGN_TOP: 
					yOffset = 0;
					break;
				
				case BitmapText.VERTICAL_ALIGN_MIDDLE: 
					yOffset = -_bitmapData.height / 2;
					break;
				
				case BitmapText.VERTICAL_ALIGN_BOTTOM:
					yOffset = -_bitmapData.height;
					break;
			}
			_tempMatrix.translate(xOffset, yOffset);
			
			var w:Number = getImageDataWidth();
			var h:Number = getImageDataHeight();
			var scaleWidth:Number = w * screenBounds.getXCoverage() / dataBounds.getXCoverage() / _bitmapData.width;
			var scaleHeight:Number = h * screenBounds.getYCoverage() / dataBounds.getYCoverage() / _bitmapData.height;
			
			if (!isFinite(w))
			{
				scaleWidth = 1;
				tempPoint.x = Math.round(tempPoint.x);
			}
			
			if (!isFinite(h))
			{
				scaleHeight = 1;
				tempPoint.y = Math.round(tempPoint.y);
			}
			
			_tempMatrix.scale(scaleWidth, scaleHeight);
			
			_tempMatrix.translate(tempPoint.x, tempPoint.y);
			destination.draw(_bitmapData, _tempMatrix);
		}
		
		private function handleImage(event:ResultEvent, url:String):void
		{
			if (objectWasDisposed(this) || url != imageURL.value)
				return;
			
			try
			{
				_bitmapData = Bitmap(event.result).bitmapData;
				getCallbackCollection(this).triggerCallbacks();
			}
			catch (e:Error)
			{
				reportError(e);
			}
		}
		
		private function handleImageFault(event:FaultEvent, url:String):void
		{
			if (objectWasDisposed(this) || url != imageURL.value)
				return;
			
			_bitmapData = MISSING_IMAGE;
			reportError(event);
		}
		
		public function handleMissingSessionStateProperty(newState:Object, missingProperty:String):void
		{
			if (missingProperty == 'useImageSize')
			{
				if (!imageURL.value)
					imageURL.value = RED_CIRCLE_IMAGE_URL;
			}
		}
		
		
		
		
		[Embed(source="/weave/resources/images/missing.png")]
		private static var _missingImageClass:Class;
		private static var _missingImage:BitmapData;
		private static function get MISSING_IMAGE():BitmapData
		{
			if (!_missingImage)
				_missingImage = (new _missingImageClass() as BitmapAsset).bitmapData;
			return _missingImage;
		}
		
		[Embed(source='/weave/resources/images/red-circle.png')]
		private static var _redCircle:Class;
		private static var _redCircleUrl:String;
		public static function get RED_CIRCLE_IMAGE_URL():String
		{
			var name:String = 'red-circle.png';
			if (!WeaveAPI.URLRequestUtils.getLocalFile(name))
				_redCircleUrl = WeaveAPI.URLRequestUtils.saveLocalFile(name, new _redCircle())
			return _redCircleUrl;
		}
	}
}