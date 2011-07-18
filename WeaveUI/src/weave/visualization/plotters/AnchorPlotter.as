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
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Point;
	
	import mx.utils.ObjectUtil;
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IFilteredKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.data.KeySets.FilteredKeySet;
	import weave.data.KeySets.KeySet;
	import weave.data.QKeyManager;
	import weave.utils.BitmapText;
	import weave.utils.ColumnUtils;

	/**
	 * AnchorPlotter
	 * @author kmanohar
	 */	
	public class AnchorPlotter extends AbstractPlotter
	{
		public var anchors:LinkableHashMap = newSpatialProperty(LinkableHashMap,handleAnchorsChange);
		public const labelAngleRatio:LinkableNumber = registerSpatialProperty(new LinkableNumber(0, verifyLabelAngleRatio));
		
		private var _keySet:KeySet;
		private const tempPoint:Point = new Point();
		private const _bitmapText:BitmapText = new BitmapText();
		
		public function AnchorPlotter()	{}
		
		public function handleAnchorsChange():void
		{		
			var keys:Array = anchors.getNames(AnchorPoint);
			var keyArray:Array = WeaveAPI.QKeyManager.getQKeys('dimensionAnchors',keys);

			_keySet = new KeySet();
			_keySet.replaceKeys(keyArray);
			setKeySource(_keySet);
		}						
		
		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			var array:Array = anchors.getObjects(AnchorPoint);
			var x:Number; 
			var y:Number;
			var anchor:AnchorPoint;
			var radians:Number;
			var graphics:Graphics = tempShape.graphics;
			graphics.clear();
			// loop through anchors hash map and draw dimensional anchors and labels	
			for each(var key:IQualifiedKey in recordKeys)
			{
				anchor = anchors.getObject(key.localName) as AnchorPoint;
				
				x = anchor.x.value;
				y = anchor.y.value;
				radians = anchor.polarRadians.value;
				var radius:Number = anchor.radius.value;
				
				var cos:Number = Math.cos(radians);
				var sin:Number = Math.sin(radians);
				
				tempPoint.x = radius * cos;
				tempPoint.y = radius * sin;
				dataBounds.projectPointTo(tempPoint, screenBounds);

				_bitmapText.text = key.localName;
				
				_bitmapText.verticalAlign = BitmapText.VERTICAL_ALIGN_CENTER;
				
				_bitmapText.angle = screenBounds.getYDirection() * (radians * 180 / Math.PI);
				_bitmapText.angle = (_bitmapText.angle % 360 + 360) % 360;
				if (cos > -0.000001) // the label exactly at the bottom will have left align
				{
					_bitmapText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_LEFT;
					// first get values between -90 and 90, then multiply by the ratio
					_bitmapText.angle = ((_bitmapText.angle + 90) % 360 - 90) * labelAngleRatio.value;
				}
				else
				{
					_bitmapText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_RIGHT;
					// first get values between -90 and 90, then multiply by the ratio
					_bitmapText.angle = (_bitmapText.angle - 180) * labelAngleRatio.value;
				}
				_bitmapText.textFormat.color = Weave.properties.axisFontColor.value;
				_bitmapText.textFormat.size = Weave.properties.axisFontSize.value;
				_bitmapText.textFormat.underline = Weave.properties.axisFontUnderline.value;
				_bitmapText.x = tempPoint.x;
				_bitmapText.y = tempPoint.y;
				_bitmapText.draw(destination);
				graphics.lineStyle(3);
				graphics.drawCircle(tempPoint.x, tempPoint.y, 1);
			}
			destination.draw(tempShape);			
		}
		
		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			if( !anchors ) return null;
			
			var anchor:AnchorPoint = anchors.getObject(recordKey.localName) as AnchorPoint;
			tempPoint.x = anchor.x.value;
			tempPoint.y = anchor.y.value;
			
			var bounds:IBounds2D = getReusableBounds();
			bounds.includePoint(tempPoint);
			return [bounds];
		}
		
		override public function getBackgroundDataBounds():IBounds2D
		{
			return getReusableBounds(-1, -1.1, 1, 1.1);
		}
		
		private function verifyLabelAngleRatio(value:Number):Boolean
		{
			return 0 <= value && value <= 1;
		}
		
	}	
}