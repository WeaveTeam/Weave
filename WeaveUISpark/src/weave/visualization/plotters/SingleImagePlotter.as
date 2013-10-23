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
	
	import mx.core.BitmapAsset;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ICallbackCollection;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.ISimpleGeometry;
	import weave.api.detectLinkableObjectChange;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.objectWasDisposed;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.api.ui.IPlotter;
	import weave.api.ui.IPlotterWithGeometries;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.SessionManager;
	import weave.primitives.Bounds2D;
	import weave.primitives.GeometryType;
	import weave.primitives.SimpleGeometry;
	import weave.utils.BitmapText;

	/**
	 * A plotter for drawing a single image onto a tool.
	 *  
	 * @author skolman
	 * @author kmonico
	 */	
	public class SingleImagePlotter extends AbstractPlotter
	{
		WeaveAPI.registerImplementation(IPlotter, SingleImagePlotter, "Single image");
		
		public function SingleImagePlotter()
		{
		}
		
		// these vars store info on the image
		private var _bitmapData:BitmapData = null;
		private var _imgScreenBounds:Bounds2D = new Bounds2D();
		private var _imgDataBounds:Bounds2D = new Bounds2D();
		
		private var _tempMatrix:Matrix = new Matrix();
		private var _tempPoint:Point = new Point();
		
		[Embed(source='/weave/resources/images/red-circle.png')]
		private var defaultImageSource:Class;
		
		/**
		 * The URL of the image to download.
		 */		
		public const imageURL:LinkableString = newLinkableChild(this, LinkableString);
		
		public const dataX:LinkableNumber = newSpatialProperty(LinkableNumber);
		public const dataY:LinkableNumber = newSpatialProperty(LinkableNumber);
		public const dataWidth:LinkableNumber = newSpatialProperty(LinkableNumber);
		public const dataHeight:LinkableNumber = newSpatialProperty(LinkableNumber);

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
		
		override public function getBackgroundDataBounds(output:IBounds2D):void
		{
			var x:Number = dataX.value;
			var y:Number = dataY.value;
			var w:Number = dataWidth.value || 0;
			var h:Number = dataHeight.value || 0;
			
			if (horizontalAlign.value == BitmapText.HORIZONTAL_ALIGN_LEFT)
				output.setXRange(x, x + w);
			if (horizontalAlign.value == BitmapText.HORIZONTAL_ALIGN_CENTER)
				output.setCenteredXRange(x, w);
			if (horizontalAlign.value == BitmapText.HORIZONTAL_ALIGN_RIGHT)
				output.setXRange(x - w, x);
			
			if (verticalAlign.value == BitmapText.VERTICAL_ALIGN_TOP)
				output.setYRange(y, y + h);
			if (verticalAlign.value == BitmapText.VERTICAL_ALIGN_MIDDLE)
				output.setCenteredYRange(y, h);
			if (verticalAlign.value == BitmapText.VERTICAL_ALIGN_BOTTOM)
				output.setYRange(y - h, y);
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
					var image:BitmapAsset = new defaultImageSource() as BitmapAsset;
					_bitmapData = image.bitmapData;
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
			
			var scaleWidth:Number = dataWidth.value * screenBounds.getXCoverage() / dataBounds.getXCoverage() / _bitmapData.width;
			var scaleHeight:Number = dataHeight.value * screenBounds.getYCoverage() / dataBounds.getYCoverage() / _bitmapData.height;
			
			if (!isFinite(dataWidth.value))
				scaleWidth = 1;
			
			if (!isFinite(dataHeight.value))
				scaleHeight = 1;
			
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
			
			reportError(event);
		}
	}
}