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
	
	import weave.Weave;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.ColorColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.primitives.Bounds2D;
	import weave.utils.BitmapText;
	import weave.utils.ColumnUtils;
	import weave.visualization.plotters.styles.DynamicFillStyle;
	import weave.visualization.plotters.styles.DynamicLineStyle;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * RadVizPlotter
	 * 
	 * @author kmanohar
	 */
	public class RadVizPlotter extends AbstractPlotter
	{
		public function RadVizPlotter()
		{
			// initialize default line & fill styles
			lineStyle.requestLocalObject(SolidLineStyle, false);
			fillStyle.color.internalDynamicColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;
			defaultScreenRadius.value = 5;
			registerNonSpatialProperties(Weave.properties.axisFontUnderline,Weave.properties.axisFontSize,Weave.properties.axisFontColor);
		}
				
		private function handleColumnsChange():void
		{
			var array:Array = columns.getObjects();
			if (array.length > 0)
				setKeySource(array[0]);
			else
				setKeySource(null);
		}
		
		public const columns:LinkableHashMap = registerSpatialProperty(new LinkableHashMap(IAttributeColumn), handleColumnsChange);
		
		public const lineStyle:DynamicLineStyle = newNonSpatialProperty(DynamicLineStyle);
		public const fillStyle:SolidFillStyle = newNonSpatialProperty(SolidFillStyle);
		public const defaultScreenRadius:LinkableNumber = newNonSpatialProperty(LinkableNumber);
		
		private const coordinate:Point = new Point();//reusable object
		
		private const _currentDataBounds:IBounds2D = new Bounds2D(); // reusable temporary object
		private const _currentScreenBounds:IBounds2D = new Bounds2D(); // reusable temporary object
		
		public const radiusColumn:DynamicColumn = newNonSpatialProperty(DynamicColumn);
		public function get colorColumn():AlwaysDefinedColumn { return fillStyle.color; }
		public function get alphaColumn():AlwaysDefinedColumn { return fillStyle.alpha; }
		
		private function getXYcoordinates(recordKey:IQualifiedKey):void
		{
			//implements RadViz algorithm for x and y coordinates of a record
			
			var numeratorX:Number = 0;
			var denominatorX:Number = 0;
			var numeratorY:Number = 0;
			var denominatorY:Number = 0;
			//var tmpPoint:Point = new Point();
			var columnArray:Array = columns.getObjects();
			var columnArrayLength:int = columnArray.length;
			//CORRECT this function so the coordinate is accurate
			var j:int;
			var value:Number = 0;
			var theta:Number = (2 * Math.PI) / columnArrayLength; 
			for (j=0; j<columnArrayLength; j++) {
				
				value = ColumnUtils.getNorm(columnArray[j], recordKey);
				
				numeratorX += value * Math.cos(theta * j);
				denominatorX += value;
				numeratorY += value * Math.sin(theta * j);
				denominatorY += value;
				//trace(numeratorX, numeratorY, denominatorX, denominatorY);
				
			}
			if(denominatorX) coordinate.x = numeratorX/denominatorX;
			else coordinate.x = 0;
			if(denominatorY) coordinate.y = numeratorY/denominatorY;
			else coordinate.y = 0;
		}
		
		/**
		 * This function may be defined by a class that extends AbstractPlotter to use the basic template code in AbstractPlotter.drawPlot().
		 */
		override protected function addRecordGraphicsToTempShape(recordKey:IQualifiedKey, dataBounds:IBounds2D, screenBounds:IBounds2D, tempShape:Shape):void
		{
			var graphics:Graphics = tempShape.graphics;

			var radius:Number = (radiusColumn.internalColumn) ? ColumnUtils.getNorm(radiusColumn, recordKey) : 1 ;
			// do not plot record with missing value for radiusColumn
			if(!isNaN(radius)) radius = 2 + (radius*8);
			if(isNaN(radius)) radius = defaultScreenRadius.value;
			//if (DataRepository.getKeysFromColumn(keyColumn).indexOf(recordKey) > 0) return;
			
			_currentDataBounds.copyFrom(dataBounds);
			_currentScreenBounds.copyFrom(screenBounds);
			
			getXYcoordinates(recordKey);
			//trace(coordinate, screenBounds, dataBounds);
			dataBounds.projectPointTo(coordinate, screenBounds);			
			
			lineStyle.beginLineStyle(recordKey, graphics);				
			fillStyle.beginFillStyle(recordKey, graphics);
			
			if(radiusColumn.internalColumn)
				graphics.drawCircle(coordinate.x, coordinate.y, radius*defaultScreenRadius.value/3);
			else 
				graphics.drawCircle(coordinate.x, coordinate.y, defaultScreenRadius.value);
			graphics.endFill();
		}
		
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			var g:Graphics = tempShape.graphics;
			g.clear();
			
			coordinate.x = -1;
			coordinate.y = -1;
			dataBounds.projectPointTo(coordinate, screenBounds);
			var x:Number = coordinate.x;
			var y:Number = coordinate.y;
			coordinate.x = 1;
			coordinate.y = 1;
			dataBounds.projectPointTo(coordinate, screenBounds);
			
			try {
				g.lineStyle(2, 0, .2);
				g.drawEllipse(x, y, coordinate.x - x, coordinate.y - y);
			} catch (e:Error) { }
			
			destination.draw(tempShape);
			var i:int = 0;
			var column1:Array = columns.getObjects(IAttributeColumn);
			for each( var column:IAttributeColumn in column1 )
			{
				i++ ;
			}
			
			var theta:Number = ( 2 * Math.PI )/column1.length ;
			for( i = 0 ; i < column1.length ; i++ )
			{
				coordinate.x = Math.cos( theta * i ) ;
				coordinate.y = Math.sin( theta * i ) ;
				dataBounds.projectPointTo(coordinate, screenBounds);
				var graphics1:Graphics = tempShape.graphics;
				var labelText:BitmapText = new BitmapText();
				labelText.text = ("  " + ColumnUtils.getTitle(column1[i] as IAttributeColumn) + "  ");
				if (((theta*i) < (Math.PI/2)) || ((theta*i) > ((3*Math.PI)/2)))
				{
					labelText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_LEFT ;
					labelText.verticalAlign = BitmapText.VERTICAL_ALIGN_CENTER ;
				}
					//else if( theta <= ((55*Math.PI)/36) && theta >= ((53*Math.PI)/36))
				else if ((theta*i) == ((3*Math.PI)/2) )
				{
					labelText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_CENTER ;
				}
				else if ((theta*i) == (Math.PI/2))
				{
					labelText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_CENTER ;
					labelText.verticalAlign = BitmapText.VERTICAL_ALIGN_BOTTOM ;
				}
				else
				{
					labelText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_RIGHT ;
					labelText.verticalAlign = BitmapText.VERTICAL_ALIGN_CENTER ;
				}
				labelText.textFormat.color=Weave.properties.axisFontColor.value;
				labelText.textFormat.size=Weave.properties.axisFontSize.value;
				labelText.textFormat.underline=Weave.properties.axisFontUnderline.value;
				labelText.x = coordinate.x ;
				labelText.y = coordinate.y ;
				labelText.draw(destination) ;
				graphics1.clear();
				graphics1.lineStyle(3);
				graphics1.drawCircle(coordinate.x, coordinate.y, 1) ;
				destination.draw(tempShape);
			}
		}		
		
		/**
		 * This function sorts record keys based on their radiusColumn values, then by their colorColumn values
		 * @param key1 First record key (a)
		 * @param key2 Second record key (b)
		 * @return Sort value: 0: (a == b), -1: (a < b), 1: (a > b)
		 * 
		 */			
		private function sortKeys(key1:IQualifiedKey, key2:IQualifiedKey):int
		{
			// compare size
			var a:Number = radiusColumn.getValueFromKey(key1);
			var b:Number = radiusColumn.getValueFromKey(key2);
			// sort descending (high radius values drawn first)
			if( a < b )
				return -1;
			else if( a > b )
				return 1;
			
			// size equal.. compare color
						
			a = fillStyle.color.getValueFromKey(key1, Number);
			b = fillStyle.color.getValueFromKey(key2, Number);
			// sort ascending (high values drawn last)
			if( a < b ) return 1; 
			else if( a > b ) return -1 ;
			
			else return 0 ;
		}
		
		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			recordKeys.sort(sortKeys, Array.DESCENDING);
			super.drawPlot(recordKeys, dataBounds, screenBounds, destination);
		}
		
		/**
		 * The data bounds for a glyph has width and height equal to zero.
		 * This function returns a Bounds2D object set to the data bounds associated with the given record key.
		 * @param key The key of a data record.
		 * @param outputDataBounds A Bounds2D object to store the result in.
		 */
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			getXYcoordinates(recordKey);
			
			var bounds:IBounds2D = getReusableBounds();
			bounds.includePoint(coordinate);
			return [bounds];
		}

		/**
		 * This function returns a Bounds2D object set to the data bounds associated with the background.
		 * @param outputDataBounds A Bounds2D object to store the result in.
		 */
		override public function getBackgroundDataBounds():IBounds2D
		{
			return getReusableBounds(-1, -1.1, 1, 1.1);
		}
	}
}