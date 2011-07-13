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
	
	import weave.api.WeaveAPI;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IFilteredKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.core.LinkableHashMap;
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
		
		private var _keySet:KeySet;
		private var tempPoint:Point = new Point();
		
		public function AnchorPlotter()	{}
		
		public function handleAnchorsChange():void
		{		
			var keys:Array = anchors.getNames(AnchorPoint);
			var keyArray:Array = WeaveAPI.QKeyManager.getQKeys('dimensionalAnchors',keys);

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
			var key:IQualifiedKey;
			
			// loop through anchors hash map and draw dimensional anchors and labels					
			for( var i:int = 0 ; i < recordKeys.length ; i++ )
			{
				key = recordKeys[i];
				anchor = anchors.getObject(key.localName) as AnchorPoint;
				tempPoint.x = x = anchor.x.value;
				tempPoint.y = y = anchor.y.value;
				
				dataBounds.projectPointTo(tempPoint, screenBounds);
				var graphics1:Graphics = tempShape.graphics;
				var labelText:BitmapText = new BitmapText();
				labelText.text = key.localName;
				
				if(x > 0) // right half of unit circle
				{
					labelText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_LEFT ;
					labelText.verticalAlign = BitmapText.VERTICAL_ALIGN_CENTER ;
					labelText.x = tempPoint.x + 10;
					labelText.y = tempPoint.y;
				}
				
				else if ( x == 0 && y <= 0 ) // exact bottom of circle
				{
					labelText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_CENTER ;
					labelText.x = tempPoint.x ;
					labelText.y = tempPoint.y + 10;
				}
				else if( x == 0 && y > 0) // exact top of circle
				{
					labelText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_CENTER ;
					labelText.verticalAlign = BitmapText.VERTICAL_ALIGN_BOTTOM ;					
					labelText.x = tempPoint.x;
					labelText.y = tempPoint.y - 10;
				}
				else // left half of circle
				{
					labelText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_RIGHT ;
					labelText.verticalAlign = BitmapText.VERTICAL_ALIGN_CENTER ;
					labelText.x = tempPoint.x - 10;
					labelText.y = tempPoint.y;
				}
				labelText.draw(destination) ;
				graphics1.clear();
				graphics1.lineStyle(3);
				graphics1.drawCircle(tempPoint.x, tempPoint.y, 1) ;
				destination.draw(tempShape);
			}
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
	}	
}