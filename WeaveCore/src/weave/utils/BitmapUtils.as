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

package weave.utils
{
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.IBitmapDrawable;
	import flash.display.Stage;
	import flash.external.ExternalInterface;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	
	import mx.core.BitmapAsset;
	import mx.core.IFlexDisplayObject;
	import mx.core.UIComponent;
	import mx.events.ToolTipEvent;
	import mx.graphics.ImageSnapshot;
	import mx.graphics.codec.PNGEncoder;
	
	import spark.components.BorderContainer;
	import spark.primitives.BitmapImage;
	
	import weave.compiler.StandardLib;
	
	/**
	 * BitmapUtils
	 * Functions for working with bitmaps.
	 * 
	 * @author adufilie
	 */
	public class BitmapUtils
	{
		
//		public static function hitTest(coordSpace:DisplayObject,redClip:DisplayObject, blueClip:DisplayObject):Boolean
//		{
//			var stage:DisplayObject = coordSpace;
//			
//			var blueRect:Rectangle = blueClip.getBounds(stage);
//			var blueOffset:Matrix = blueClip.transform.matrix;
//			blueOffset.tx = blueClip.x - blueRect.x;
//			blueOffset.ty = blueClip.y - blueRect.y;        
//			
//			var blueClipBmpData = new BitmapData(blueRect.width, blueRect.height, true, 0);
//			blueClipBmpData.draw(blueClip, blueOffset);                
//			
//			var redRect:Rectangle = redClip.getBounds(stage);
//			var redClipBmpData = new BitmapData(redRect.width, redRect.height, true, 0);
//			
//			var redOffset:Matrix = redClip.transform.matrix;
//			redOffset.tx = redClip.x - redRect.x;
//			redOffset.ty = redClip.y - redRect.y;        
//			
//			redClipBmpData.draw(redClip, redOffset);        
//			
//			var rLoc:Point = new Point(redRect.x, redRect.y);
//			var bLoc:Point = new Point(blueRect.x, blueRect.y);        
//			
//			var result:Boolean = redClipBmpData.hitTest(rLoc,
//				1,
//				blueClipBmpData,
//				bLoc,
//				1
//			);
//			blueClipBmpData.dispose();
//			redClipBmpData.dispose();
//			return result;
//		}
//		
		// reusable temporary objects
		private static var tempMatrix:Matrix = new Matrix();

		[Embed(source="/weave/resources/images/missing.png")]
		private static var _missingImageClass:Class;
		private static var _missingImage:BitmapData;
		public static function get MISSING_IMAGE():BitmapData
		{
			if (!_missingImage)
				_missingImage = (new _missingImageClass() as BitmapAsset).bitmapData;
			return _missingImage;
		}
		
		/**
		 * This function will draw an image centered on an x,y coordinate.
		 * @param graphics The Graphics object where the icon should be drawn.
		 * @param x The center x coordinate used to draw the icon.
		 * @param y The center y coordinate used to draw the icon.
		 * @param source The icon image.
		 * @param fillColor A background fill color.
		 * @param fillAlpha A background fill alpha.
		 * @param scale A scale value used to resize the source image.
		 */
		public static function drawCenteredIcon(graphics:Graphics, x:Number, y:Number, source:BitmapData, fillColor:Number = NaN, fillAlpha:Number = 1.0, scale:Number = 1.0):void
		{
			// don't draw if we don't have valid coordinates
			if (isNaN(x) || isNaN(y))
				return;
			
			var scaledWidth:Number = scale * source.width;
			var scaledHeight:Number = scale * source.height;
			var floorX:Number = Math.floor(x) - int(scaledWidth / 2);
			var floorY:Number = Math.floor(y) - int(scaledHeight / 2);

			if (!isNaN(fillColor))
			{
				graphics.beginFill(fillColor, fillAlpha);
				graphics.drawRect(floorX, floorY, scaledWidth, scaledHeight);
				graphics.endFill();
			}
			
			tempMatrix.identity();
			tempMatrix.scale(scale, scale);
			tempMatrix.translate(floorX, floorY);
			
			graphics.beginBitmapFill(source, tempMatrix, false, true);
			graphics.drawRect(floorX, floorY, scaledWidth, scaledHeight);
			graphics.endFill();
		}
		
		/**
		 * This function will create a high quality thumbnail for a BitmapData.
		 * @param source A BitmapData to create a thumbnail for.
		 * @param width The maximum desired width of the result.
		 * @param height The maximum desired height of the result.
		 * @return A thumbnail version of the source BitmapData that fits within the specified width and height.
		 */
		public static function resizeBitmapData(source:BitmapData, width:uint, height:uint):BitmapData
		{
			// find target w,h with proper aspect ratio
			var scale:Number = Math.min(width/source.width, height/source.height);
			var w:int = Math.round(source.width * scale);
			var h:int = Math.round(source.height * scale);
			
			// upscale source width,height to the target w,h times a power of 2
			if (w > 0 && h > 0)
				while (w < source.width || h < source.height)
					w *= 2, h *= 2;
			var result:BitmapData = new BitmapData(w, h);
			tempMatrix.identity();
			tempMatrix.scale(w/source.width, h/source.height);
			result.draw(source, tempMatrix, null, null, null, true);
			
			// scale down step by step with 0.5 scale to get the highest quality thumbnail possible
			tempMatrix.identity();
			tempMatrix.scale(0.5, 0.5);
			while (w > width || h > height)
			{
				var temp:BitmapData = new BitmapData(w/=2, h/=2);
				temp.draw(result, tempMatrix, null, null, null, true);
				result.dispose();
				result = temp;
			}

			return result;
		}
		/**
		 * This function gets a screenshot of a component and optionally creates a thumbnail version.
		 * @param component A component from which to get a screenshot.
		 * @param desiredWidth If > 0, the width of the thumbnail version.
		 * @param desiredHeight If > 0, the height of the thumbnail version.
		 * @return A screenshot of the component. If desired width or height is specified, a thumbnail version is returned.
		 */
		public static function getBitmapDataFromComponent(component:IFlexDisplayObject, desiredWidth:int = 0, desiredHeight:int = 0):BitmapData
		{
			var screenshot:BitmapData = new BitmapData(component.width, component.height, true, 0x00000000);
			screenshot.draw(component);
			
			if (desiredWidth > 0 && desiredHeight > 0)
			{
				var result:BitmapData = resizeBitmapData(screenshot, desiredWidth, desiredHeight);
				screenshot.dispose();
				return result;
			}
			
			return screenshot;
		}
		
		/**
		 * This function accepts a component, gets its corresponding bitmap, and encodes the image as
		 * a base 64 string.
		 * @param component The component for which to get the string encoding.
		 * @return A base 64 encoding of the image.
		 */		
		public static function getBase64Image(component:IBitmapDrawable):String
		{
			// getBitmapDataFromComponent doesn't give a valid image that can be saved to disk
//			var data:BitmapData = getBitmapDataFromComponent(component);
//			var byteArray:ByteArray = new ByteArray();
//			byteArray.writeObject(data.getPixels(data.rect));
			
			return StandardLib.btoa(ImageSnapshot.captureImage(component).data);
		}
		
//		/**
//		 * This generates a JPEG screenshot of a component.
//		 * @param component The component from which to get a screenshot.
//		 * @param quality A quality value between 0 and 100.
//		 * @return A JPEG version of the screenshot, stored in a ByteArray.
//		 * @see mx.graphics.codec.JPEGEncoder
//		 */
//		public static function getJPEGFromComponent(component:IBitmapDrawable, quality:int = 100):ByteArray
//		{		
//			var bitmap:BitmapData = getBitmapDataFromComponent(component);
//			return new JPEGEncoder(quality).encode(bitmap);
//		}
		
		/**
		 * This generates a PNG screenshot of a component.
		 * @param component The component from which to get a screenshot.
		 * @return A PNG version of the screenshot, stored in a ByteArray.
		 */
		public static function getPNGFromComponent(component:IFlexDisplayObject):ByteArray
		{		
			var bitmap:BitmapData = getBitmapDataFromComponent(component);
			return new PNGEncoder().encode(bitmap);
		}
		
		/**
		 * @param javaScriptImgExpression A JavaScript expression which gets a pointer to the img tag.
		 *                                The expression can use a "weave" variable as a pointer to Weave.
		 * @param bitmapData The BitmapData to use as the img source.
		 */
		public static function setHtmlImgSource(javaScriptImgExpression:String, bitmapData:BitmapData):void
		{
			var base64data:String = bitmapData ? StandardLib.btoa(new PNGEncoder().encode(bitmapData)) : '';
			ExternalInterface.marshallExceptions = false;
			ExternalInterface.call(
				"function(base64data) {" +
				"  var weave = " + JavaScript.JS_this + ";" +
				"  (" + javaScriptImgExpression + ").src = 'data:image/png;base64,' + base64data;" +
				"}",
				base64data
			);
		}
		
		
		public static function setBitmapDataToolTip(component:UIComponent, getBitmapData:Function):void
		{
			component.toolTip = ' ';
			component.addEventListener(ToolTipEvent.TOOL_TIP_SHOWN, onToolTipShown);
			component.addEventListener(ToolTipEvent.TOOL_TIP_HIDE, onToolTipHide);
			function onToolTipShown(event:ToolTipEvent):void
			{
				var bitmapData:BitmapData = getBitmapData() as BitmapData;
				if (bitmapData)
				{
					if (!staticBitmapBorder)
					{
						staticBitmapBorder = new BorderContainer();
						staticBitmap = new BitmapImage();
						staticBitmapBorder.addElement(staticBitmap);
					}
					staticBitmap.source = bitmapData;
					staticBitmapBorder.x = 0;
					staticBitmapBorder.y = 0;
					staticBitmapBorder.width = bitmapData.width + 2;
					staticBitmapBorder.height = bitmapData.height + 2;
					(event.toolTip as UIComponent).addChild(staticBitmapBorder);
					
					// reposition so it's on the screen
					var p:Point = event.toolTip.localToGlobal(new Point(0, 0));
					var stage:Stage = event.toolTip.stage as Stage;
					var sw:Number = stage.stageWidth;
					var sh:Number = stage.stageHeight;
					if (p.x + bitmapData.width > sw)
						p.x = stage.mouseX - bitmapData.width - 2;
					if (p.y + bitmapData.height > sh)
						p.y = stage.mouseY - bitmapData.height - 2;
					p = event.toolTip.parent.globalToLocal(p);
					event.toolTip.x = p.x;
					event.toolTip.y = p.y;
				}
				else
				{
					event.toolTip.visible = false;
				}
			}
			function onToolTipHide(event:ToolTipEvent):void
			{
				if ((event.toolTip as UIComponent).contains(staticBitmapBorder))
					(event.toolTip as UIComponent).removeChild(staticBitmapBorder);
			}
		}
		
		private static var staticBitmapBorder:BorderContainer;
		private static var staticBitmap:BitmapImage;
	}
}
