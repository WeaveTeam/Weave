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
	import flash.display.LineScaleMode;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import weave.Weave;
	import weave.api.copySessionState;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnWrapper;
	import weave.api.data.IQualifiedKey;
	import weave.api.disposeObjects;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableNumber;
	import weave.core.StageUtils;
	import weave.data.AttributeColumns.ColorColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.ReprojectedGeometryColumn;
	import weave.data.AttributeColumns.StreamedGeometryColumn;
	import weave.primitives.GeneralizedGeometry;
	import weave.utils.PlotterUtils;
	import weave.visualization.plotters.styles.DynamicFillStyle;
	import weave.visualization.plotters.styles.DynamicLineStyle;
	import weave.visualization.plotters.styles.ExtendedSolidFillStyle;
	import weave.visualization.plotters.styles.ExtendedSolidLineStyle;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * GeometryPlotter
	 * 
	 * @author adufilie
	 */
	public class GeometryPlotter extends AbstractPlotter
	{
		public function GeometryPlotter()
		{
			registerSpatialProperties(geometryColumn.internalDynamicColumn);
			// initialize default line & fill styles
			line.scaleMode.defaultValue.setSessionState(LineScaleMode.NONE);
			fill.color.internalDynamicColumn.requestGlobalObject(Weave.DEFAULT_COLOR_COLUMN, ColorColumn, false);

			fill.enableMissingDataFillPattern.value = false;
			line.weight.addImmediateCallback(this, disposeCachedBitmaps);
			

			setKeySource(geometryColumn);
		}

		/**
		 * This is the reprojected geometry column to draw.
		 */
		public const geometryColumn:ReprojectedGeometryColumn = newSpatialProperty(ReprojectedGeometryColumn);
		
		/**
		 * This is the line style used to draw the lines of the geometries.
		 */
		public const line:ExtendedSolidLineStyle = newNonSpatialProperty(ExtendedSolidLineStyle, invalidateCachedBitmaps);
		/**
		 * This is the fill style used to fill the geometries.
		 */
		public const fill:ExtendedSolidFillStyle = newNonSpatialProperty(ExtendedSolidFillStyle, invalidateCachedBitmaps);

		/**
		 * This is the size of the points drawn when the geometry represents point data.
		 **/
		public const pointShapeSize:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(5, validatePointShapeSize), disposeCachedBitmaps);
		private function validatePointShapeSize(value:Number):Boolean { return 0.2 <= value && value <= 1024; };

		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			var geoms:Array = null;
			var column:IAttributeColumn = geometryColumn; 
			
			// the column value may contain a single geom or an array of geoms
			var value:* = column.getValueFromKey(recordKey);
			if (value is Array)
				geoms = value; // array of geoms
			else if (value is GeneralizedGeometry)
				geoms = [value as GeneralizedGeometry]; // single geom -- create array

			var results:Array = [];
			if (geoms != null)
				for each (var geom:GeneralizedGeometry in geoms)
					results.push(geom.bounds);
			return results;
		}
		
		/**
		 * This function returns a Bounds2D object set to the data bounds associated with the background.
		 * @param outputDataBounds A Bounds2D object to store the result in.
		 */
		override public function getBackgroundDataBounds():IBounds2D
		{
			// try to find an internal StreamedGeometryColumn
			var column:IAttributeColumn = geometryColumn;
			while (!(column is StreamedGeometryColumn) && column is IColumnWrapper)
				column = (column as IColumnWrapper).internalColumn;
			
			// if the internal geometry column is a streamed column, request the required detail
			var streamedColumn:StreamedGeometryColumn = column as StreamedGeometryColumn;
			if (streamedColumn)
				return streamedColumn.collectiveBounds;
			else
				return getReusableBounds();
		}

		/**
		 * This function calculates the importance of a pixel.
		 */
		protected function getDataAreaPerPixel(dataBounds:IBounds2D, screenBounds:IBounds2D):Number
		{
			// get minimum importance value required to display the shape at this zoom level
//			var dw:Number = dataBounds.getWidth();
//			var dh:Number = dataBounds.getHeight();
//			var sw:Number = screenBounds.getWidth();
//			var sh:Number = screenBounds.getHeight();
//			return Math.min((dw*dw)/(sw*sw), (dh*dh)/(sh*sh));
			return dataBounds.getArea() / screenBounds.getArea();
		}
		
		private var colorToBitmapMap:Dictionary = new Dictionary(); // color -> BitmapData
		private var colorToBitmapValidFlagMap:Dictionary = new Dictionary(); // color -> valid flag

		// this calls dispose() on all cached bitmaps and removes references to them.
		private function disposeCachedBitmaps():void
		{
			var disposed:Boolean = false;
			for each (var bitmapData:BitmapData in colorToBitmapMap)
			{
				bitmapData.dispose();
				disposed = true;
			}
			if (disposed)
				colorToBitmapMap = new Dictionary();
			invalidateCachedBitmaps();
			
			var weight:Number = line.weight.getValueFromKey(null, Number) as Number;
			pointOffset = Math.ceil(pointShapeSize.value) + weight / 2;
			circleBitmapSize = Math.ceil(pointOffset * 2 + 1);
			circleBitmapDataRectangle.width = circleBitmapSize;
			circleBitmapDataRectangle.height = circleBitmapSize;
		}
		// this invalidates all cached bitmap graphics
		private function invalidateCachedBitmaps():void
		{
			for (var k:* in colorToBitmapValidFlagMap)
			{
				colorToBitmapValidFlagMap = new Dictionary();
				return;
			}
		}
		
		private var circleBitmapSize:int = 0;
		private var circleBitmapDataRectangle:Rectangle = new Rectangle(0,0,0,0);
		
		// this is the offset used to draw a circle onto a cached BitmapData
		private var pointOffset:Number;
		
		// this function returns the BitmapData associated with the given key
		private function drawCircle(destination:BitmapData, color:Number, x:Number, y:Number):void
		{
			var bitmapData:BitmapData = colorToBitmapMap[color] as BitmapData;
			if (!bitmapData)
			{
				// create bitmap
				try
				{
					bitmapData = new BitmapData(circleBitmapSize, circleBitmapSize);
				}
				catch (e:Error)
				{
					return; // do nothing if this fails
				}
				colorToBitmapMap[color] = bitmapData;
			}
			if (colorToBitmapValidFlagMap[color] == undefined)
			{
				// draw graphics on cached bitmap
				var g:Graphics = tempShape.graphics;
				g.clear();
				if (isNaN(color))
				{
					if (fill.enableMissingDataFillPattern.value)
						fill.beginFillStyle(null, g);
				}
				else if (fill.enabled.defaultValue.value)
				{
					g.beginFill(color, fill.alpha.getValueFromKey(null, Number) as Number);
				}
				line.beginLineStyle(null, g);
				g.drawCircle(pointOffset, pointOffset, pointShapeSize.value);
				g.endFill();
				PlotterUtils.clear(bitmapData);
				bitmapData.draw(tempShape);
				g.clear(); // clear tempShape now so these graphics don't get used anywhere else by mistake
				
				colorToBitmapValidFlagMap[color] = true;
			}
			// copy bitmap graphics
			tempPoint.x = Math.round(x - pointOffset);
			tempPoint.y = Math.round(y - pointOffset);
			destination.copyPixels(bitmapData, circleBitmapDataRectangle, tempPoint, null, null, true);
		}
		
		public const pixellation:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(1));
		
		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			var minImportance:Number = getDataAreaPerPixel(dataBounds, screenBounds) * pixellation.value;
			
			// try to find an internal StreamedGeometryColumn
			var column:IAttributeColumn = geometryColumn;

			while (!(column is StreamedGeometryColumn) && column is IColumnWrapper)
				column = (column as IColumnWrapper).internalColumn;
			
			// if the internal geometry column is a streamed column, request the required detail
			var streamedColumn:StreamedGeometryColumn = column as StreamedGeometryColumn;
			if (streamedColumn)
			{
				var requestedDataBounds:IBounds2D = dataBounds;
				var requestedMinImportance:Number = minImportance;
				if (requestedDataBounds.isUndefined())// if data bounds is empty
				{
					// use the collective bounds from the geometry column and re-calculate the min importance
					requestedDataBounds = streamedColumn.collectiveBounds;
					requestedMinImportance = getDataAreaPerPixel(requestedDataBounds, screenBounds);
				}
				// only request more detail if requestedDataBounds is defined
				if (!requestedDataBounds.isUndefined())
					streamedColumn.requestGeometryDetail(requestedDataBounds, requestedMinImportance);
			}
			
			var graphics:Graphics = tempShape.graphics;
			graphics.clear();
			// loop through the records and draw the geometries
			for (var recIndex:int = 0; recIndex < recordKeys.length; recIndex++)
			{
				var recordKey:IQualifiedKey = recordKeys[recIndex] as IQualifiedKey;
				var geoms:Array;
				
				var value:* = column.getValueFromKey(recordKey);//geometry.getValueFromKey(recordKey);
				if (value is Array)
					geoms = value;
				else if (value is GeneralizedGeometry)
					geoms = [value as GeneralizedGeometry];
				else
					continue;
				if (geoms.length == 0)
					continue;
				
				fill.beginFillStyle(recordKey, graphics);
				line.beginLineStyle(recordKey, graphics);
	
				// draw the geom
				for (var i:int = 0; i < geoms.length; i++)
				{
					var geom:GeneralizedGeometry = geoms[i] as GeneralizedGeometry;
					if (geom)
					{
						if (geom.geomType == GeneralizedGeometry.GEOM_TYPE_POLYGON && geom.bounds.getArea() < minImportance)
							continue;
						drawMultiPartShape(recordKey, geom.getSimplifiedGeometry(minImportance, dataBounds), geom.geomType, dataBounds, screenBounds, graphics, destination);
					}
				}
				graphics.endFill();
			}
			
			destination.draw(tempShape);
		}
		
		private static const tempPoint:Point = new Point(); // reusable object


		/**
		 * This function draws a list of GeneralizedGeometry objects
		 * @param geometryParts A 2-dimensional Array or Vector of objects, each having x and y properties.
		 */
		private function drawMultiPartShape(key:IQualifiedKey, geometryParts:Object, shapeType:String, dataBounds:IBounds2D, screenBounds:IBounds2D, graphics:Graphics, bitmapData:BitmapData):void
		{
			for (var i:int = 0; i < geometryParts.length; i++)
				drawShape(key, geometryParts[i], shapeType, dataBounds, screenBounds, graphics, bitmapData);
		}
		/**
		 * This function draws a single geometry.
		 * @param points An Array or Vector of objects, each having x and y properties.
		 */
		private function drawShape(key:IQualifiedKey, points:Object, shapeType:String, dataBounds:IBounds2D, screenBounds:IBounds2D, graphics:Graphics, bitmapData:BitmapData):void
		{
			if (points.length == 0)
				return;

			var currentNode:Object;

			if (shapeType == GeneralizedGeometry.GEOM_TYPE_POINT)
			{
				for each (currentNode in points)
				{
					tempPoint.x = currentNode.x;
					tempPoint.y = currentNode.y;
					dataBounds.projectPointTo(tempPoint, screenBounds);
					drawCircle(bitmapData, fill.color.getValueFromKey(key, Number) as Number, tempPoint.x, tempPoint.y);
				}
				return;
			}

			// prevent moveTo/lineTo from drawing a filled polygon if the shape type is line
			if (shapeType == GeneralizedGeometry.GEOM_TYPE_LINE)
				graphics.endFill();

			var numPoints:int = points.length;
			var firstX:Number, firstY:Number;
			for (var vIndex:int = 0; vIndex < numPoints; vIndex++)
			{
				currentNode = points[vIndex];
				tempPoint.x = currentNode.x;
				tempPoint.y = currentNode.y;
				dataBounds.projectPointTo(tempPoint, screenBounds);
				
				if (vIndex == 0)
				{
					firstX = tempPoint.x;
					firstY = tempPoint.y;
					graphics.moveTo(tempPoint.x, tempPoint.y);
					continue;
				}
				graphics.lineTo(tempPoint.x, tempPoint.y);
			}
			
			if (shapeType == GeneralizedGeometry.GEOM_TYPE_POLYGON)
				graphics.lineTo(firstX, firstY);
		}
		
		override public function dispose():void
		{
			disposeCachedBitmaps();
			super.dispose();
		}

		// backwards compatibility 0.9.6
		[Deprecated(replacement="line")] public function get lineStyle():DynamicLineStyle
		{
			var deprecated:DynamicLineStyle = new DynamicLineStyle(SolidLineStyle);
			var callback:Function = function():void
			{
				copySessionState(deprecated.internalObject, line);
			};
			StageUtils.callLater(this, disposeObjects, [deprecated], false);
			return registerLinkableChild(this, deprecated, callback);
		}
		[Deprecated(replacement="fill")] public function get fillStyle():DynamicFillStyle
		{
			var deprecated:DynamicFillStyle = new DynamicFillStyle(SolidFillStyle);
			var callback:Function = function():void
			{
				fill.enableMissingDataFillPattern.value = (deprecated.internalObject is ExtendedSolidFillStyle);
				copySessionState(deprecated.internalObject, fill);
			};
			StageUtils.callLater(this, disposeObjects, [deprecated], false);
			return registerLinkableChild(this, deprecated, callback);
		}
		[Deprecated(replacement="geometryColumn")] public function get geometry():DynamicColumn
		{
			return registerLinkableChild(this, geometryColumn.internalDynamicColumn);
		}
	}
}
