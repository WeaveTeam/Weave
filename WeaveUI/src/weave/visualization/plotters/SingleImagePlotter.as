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
	import weave.api.data.IQualifiedKey;
	import weave.api.data.ISimpleGeometry;
	import weave.api.getCallbackCollection;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.api.ui.IPlotterWithGeometries;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.SessionManager;
	import weave.primitives.SimpleGeometry;
	import weave.utils.BitmapText;

	/**
	 * A plotter for drawing a single image onto a tool.
	 *  
	 * @author skolman
	 * @author kmonico
	 */	
	public class SingleImagePlotter extends AbstractPlotter implements IPlotterWithGeometries
	{
		public function SingleImagePlotter()
		{
		}
		
		/**
		 * The horizontal alignment used for any text.
		 */		
		public const horizontalAlign:LinkableString =  registerLinkableChild(this, new LinkableString(BitmapText.HORIZONTAL_ALIGN_LEFT));
		/**
		 * The vertical alignment used for any text. 
		 */		
		public const verticalAlign:LinkableString = registerLinkableChild(this, new LinkableString(BitmapText.VERTICAL_ALIGN_TOP));		
		
		/**
		 * The X coordinate in original unprojected data coordinates.
		 */		
		public const dataX:LinkableNumber = registerLinkableChild(this, new LinkableNumber());
		/**
		 * The Y coordinate in original unprojected data coordinates. 
		 */		
		public const dataY:LinkableNumber = registerLinkableChild(this, new LinkableNumber());
		
		/**
		 * The width of the image in unprojected data coordinates. 
		 */		
		public const dataWidth:LinkableNumber = registerLinkableChild(this, new LinkableNumber());
		/**
		 * The height of the image in unprojected data coordinates. 
		 */		
		public const dataHeight:LinkableNumber = registerLinkableChild(this, new LinkableNumber());
		
		/**
		 * The URL of the image to download.
		 */		
		public const imageURL:LinkableString = registerLinkableChild(this, new LinkableString(), handleImageURLChange);
		
		[Embed(source='/weave/resources/images/red-circle.png')]
		private var defaultImageSource:Class;
		
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			_tempDataBounds = dataBounds;
			_tempScreenBounds = screenBounds;
			
			if(isNaN(dataX.value) || isNaN(dataY.value))
				return;
			
			if(imageBitmapData == null)
			{
				if(imageURL.value)
					WeaveAPI.URLRequestUtils.getContent(new URLRequest(imageURL.value), handleImageRequest, handleImageFaultRequest, imageURL.value);
				else
				{
					var image:BitmapAsset = new defaultImageSource() as BitmapAsset;
					
					imageBitmapData = image.bitmapData;
					plotBitmapData(destination);
				}
			}
			else
			{
				plotBitmapData(destination);
			}
		}
		
		private function plotBitmapData(destination:BitmapData):void
		{
			var tempPoint:Point = new Point(dataX.value, dataY.value);
			_tempDataBounds.projectPointTo(tempPoint, _tempScreenBounds);
			
			translationMatrix.identity();
			
			var xOffset:Number=0;
			var yOffset:Number=0;
			
			switch (verticalAlign.value)
			{
				default: // default vertical align: top
				case BitmapText.VERTICAL_ALIGN_TOP: 
					yOffset = 0;
					break;
				case BitmapText.VERTICAL_ALIGN_MIDDLE: 
					yOffset = -imageBitmapData.height / 2;
					break;
				case BitmapText.VERTICAL_ALIGN_BOTTOM:
					yOffset = -imageBitmapData.height;
					break;
			}
			
			switch (horizontalAlign.value)
			{
				default: // default horizontal align: left
				case BitmapText.HORIZONTAL_ALIGN_LEFT: // x is aligned to left side of text
					xOffset = 0;
					break;
				case BitmapText.HORIZONTAL_ALIGN_CENTER: 
					xOffset = -imageBitmapData.width / 2;
					break;
				case BitmapText.HORIZONTAL_ALIGN_RIGHT: // x is aligned to right side of text
					xOffset = -imageBitmapData.width;
					break;
			}
			translationMatrix.translate(xOffset,yOffset);
			
			var scaleWidth:Number = dataWidth.value * _tempScreenBounds.getWidth() / _tempDataBounds.getWidth() / imageBitmapData.width;
			var scaleHeight:Number = dataHeight.value * -_tempScreenBounds.getHeight() / _tempDataBounds.getHeight() / imageBitmapData.height;

			if(isNaN(dataWidth.value))
			{
				scaleWidth = 1;
			}

			if(isNaN(dataHeight.value))
			{
				scaleHeight = 1;
			}
			
			translationMatrix.scale(scaleWidth, scaleHeight);
			
			translationMatrix.translate(tempPoint.x, tempPoint.y);
			destination.draw(imageBitmapData, translationMatrix);
		}
		
		public function getGeometriesFromRecordKey(recordKey:IQualifiedKey, minImportance:Number = 0, bounds:IBounds2D = null):Array
		{
			// there are no keys in this plotter
			return [];
		}

		public function getBackgroundGeometries():Array
		{
			var simpleGeom:ISimpleGeometry = new SimpleGeometry(SimpleGeometry.POINT);
			var p1:Point = new Point(dataX.value, dataY.value);
			_tempArray.length = 0;
			_tempArray.push(p1);
			(simpleGeom as SimpleGeometry).setVertices(_tempArray);
			
			return [simpleGeom];
		}

		private function handleImageRequest(event:ResultEvent,token:Object=null):void
		{
			if((WeaveAPI.SessionManager as SessionManager).objectWasDisposed(this))
				return;
			if((token as String)== imageURL.value)
			{
				imageBitmapData = (event.result as Bitmap).bitmapData;
				getCallbackCollection(this).triggerCallbacks();
			}
		}
		
		private function handleImageFaultRequest(event:FaultEvent,token:Object=null):void
		{
			reportError(event);
		}
		
		private function handleImageURLChange():void
		{
			imageBitmapData = null;
		}

		// temporary objects
		private var _tempDataBounds:IBounds2D;
		private var _tempScreenBounds:IBounds2D;
		private const _tempArray:Array = [];
		private var imageBitmapData:BitmapData;
		private var translationMatrix:Matrix = new Matrix();
	}
}