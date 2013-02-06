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
	import flash.display.Graphics;
	import flash.display.LineScaleMode;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import weave.Weave;
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnWrapper;
	import weave.api.data.IQualifiedKey;
	import weave.api.disposeObjects;
	import weave.api.linkSessionState;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.setSessionState;
	import weave.api.ui.IPlotTask;
	import weave.api.ui.IPlotter;
	import weave.api.ui.IPlotterWithGeometries;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.data.AttributeColumns.ImageColumn;
	import weave.data.AttributeColumns.ReprojectedGeometryColumn;
	import weave.data.AttributeColumns.StreamedGeometryColumn;
	import weave.primitives.GeneralizedGeometry;
	import weave.utils.PlotterUtils;
	import weave.visualization.plotters.styles.ExtendedFillStyle;
	import weave.visualization.plotters.styles.ExtendedLineStyle;
	
	/**
	 * GeometryPlotter
	 * 
	 * @author adufilie
	 */
	public class GeometryPlotter extends AbstractPlotter implements IPlotterWithGeometries
	{
		public function GeometryPlotter()
		{
			// initialize default line & fill styles
			line.scaleMode.defaultValue.setSessionState(LineScaleMode.NONE);
			fill.color.internalDynamicColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;

			line.weight.addImmediateCallback(this, disposeCachedBitmaps);
			
			linkSessionState(StreamedGeometryColumn.geometryMinimumScreenArea, pixellation);

			setSingleKeySource(geometryColumn);
			
			// not every change to the geometries changes the keys
			geometryColumn.removeCallback(_filteredKeySet.triggerCallbacks);
			geometryColumn.boundingBoxCallbacks.addImmediateCallback(this, _filteredKeySet.triggerCallbacks);
			
			geometryColumn.boundingBoxCallbacks.addImmediateCallback(this, spatialCallbacks.triggerCallbacks); // bounding box should trigger spatial
			registerSpatialProperty(_filteredKeySet.keyFilter); // subset should trigger spatial callbacks
		}
		
		public const symbolPlotters:ILinkableHashMap = registerLinkableChild(this, new LinkableHashMap(IPlotter));

		/**
		 * This is the reprojected geometry column to draw.
		 */
		public const geometryColumn:ReprojectedGeometryColumn = newLinkableChild(this, ReprojectedGeometryColumn);
		
		/**
		 *  This is the default URL path for images, when using images in place of points.
		 */
		public const pointDataImageColumn:ImageColumn = newLinkableChild(this, ImageColumn);
		public const useFixedImageSize:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		
		[Embed(source="/weave/resources/images/missing.png")]
		private static var _missingImageClass:Class;
		private static const _missingImage:BitmapData = Bitmap(new _missingImageClass()).bitmapData;
		
		/**
		 * This is the line style used to draw the lines of the geometries.
		 */
		public const line:ExtendedLineStyle = newLinkableChild(this, ExtendedLineStyle, invalidateCachedBitmaps);
		/**
		 * This is the fill style used to fill the geometries.
		 */
		public const fill:ExtendedFillStyle = newLinkableChild(this, ExtendedFillStyle, invalidateCachedBitmaps);

		/**
		 * This is the size of the points drawn when the geometry represents point data.
		 **/
		public const iconSize:LinkableNumber = registerLinkableChild(this, new LinkableNumber(10, validateIconSize), disposeCachedBitmaps);
		private function validateIconSize(value:Number):Boolean { return 0.2 <= value && value <= 1024; };

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
		
		public function getGeometriesFromRecordKey(recordKey:IQualifiedKey, minImportance:Number = 0, bounds:IBounds2D = null):Array
		{
			var value:* = geometryColumn.getValueFromKey(recordKey);
			var geoms:Array = null;
			
			if (value is Array)
				geoms = value;
			else if (value is GeneralizedGeometry)
				geoms = [ value as GeneralizedGeometry ];
			
			var results:Array = [];
			if (geoms != null)
				for each (var geom:GeneralizedGeometry in geoms)
					results.push(geom);
			
			return results;
		}
		
		public function getBackgroundGeometries():Array
		{
			return [];
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
				column = (column as IColumnWrapper).getInternalColumn();
			
			// if the internal geometry column is a streamed column, request the required detail
			var streamedColumn:StreamedGeometryColumn = column as StreamedGeometryColumn;
			if (streamedColumn)
				return streamedColumn.collectiveBounds;
			else
				return getReusableBounds(); // undefined
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
			
			var weight:Number = line.weight.getValueFromKey(null, Number);
			pointOffset = (Math.ceil(iconSize.value) + weight) / 2;
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
					if (fill.enableMissingDataGradient.value)
						fill.beginFillStyle(null, g);
				}
				else if (fill.enabled.defaultValue.value)
				{
					g.beginFill(color, fill.alpha.getValueFromKey(null, Number));
				}
				line.beginLineStyle(null, g);
				g.drawCircle(pointOffset, pointOffset, iconSize.value / 2);
				g.endFill();
				PlotterUtils.clearBitmapData(bitmapData);
				bitmapData.draw(tempShape);
				g.clear(); // clear tempShape now so these graphics don't get used anywhere else by mistake
				
				colorToBitmapValidFlagMap[color] = true;
			}
			// copy bitmap graphics
			tempPoint.x = Math.round(x - pointOffset);
			tempPoint.y = Math.round(y - pointOffset);
			destination.copyPixels(bitmapData, circleBitmapDataRectangle, tempPoint, null, null, true);
		}
		
		public const pixellation:LinkableNumber = registerLinkableChild(this, new LinkableNumber(1));
		
		private const _destinationToPlotTaskMap:Dictionary = new Dictionary(true);
		
		private const _singleGeom:Array = []; // reusable array for holding one item
		
		private const RECORD_INDEX:String = 'recordIndex';
		private const MIN_IMPORTANCE:String = 'minImportance';
		override public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			if (task.iteration == 0)
			{
				task.asyncState[RECORD_INDEX] = 0; 
				task.asyncState[MIN_IMPORTANCE] = getDataAreaPerPixel(task.dataBounds, task.screenBounds) * pixellation.value;
			}
			
			var recordIndex:Number = task.asyncState[RECORD_INDEX];
			var minImportance:Number = task.asyncState[MIN_IMPORTANCE];
			var progress:Number = 1; // set to 1 in case loop is not entered
			while (recordIndex < task.recordKeys.length)
			{
				var recordKey:IQualifiedKey = task.recordKeys[recordIndex] as IQualifiedKey;
				var geoms:Array = null;
				var value:* = geometryColumn.getValueFromKey(recordKey);
				if (value is Array)
					geoms = value;
				else if (value is GeneralizedGeometry)
				{
					geoms = _singleGeom;
					_singleGeom[0] = value;
				}
				
				if (geoms && geoms.length > 0)
				{
					var graphics:Graphics = tempShape.graphics;
					var styleSet:Boolean = false;
					
					// draw the geom
					for (var i:int = 0; i < geoms.length; i++)
					{
						var geom:GeneralizedGeometry = geoms[i] as GeneralizedGeometry;
						if (geom)
						{
							// skip shapes that are considered unimportant at this zoom level
							if (geom.geomType == GeneralizedGeometry.GEOM_TYPE_POLYGON && geom.bounds.getArea() < minImportance)
								continue;
							if (!styleSet)
							{
								graphics.clear();
								fill.beginFillStyle(recordKey, graphics);
								line.beginLineStyle(recordKey, graphics);
								styleSet = true;
							}
							drawMultiPartShape(recordKey, geom.getSimplifiedGeometry(minImportance, task.dataBounds), geom.geomType, task.dataBounds, task.screenBounds, graphics, task.buffer);
						}
					}
					if (styleSet)
					{
						graphics.endFill();
						task.buffer.draw(tempShape);
					}
				}
				
				// this progress value will be less than 1
				progress = recordIndex / task.recordKeys.length;
				task.asyncState[RECORD_INDEX] = ++recordIndex;
				
				// avoid doing too little or too much work per iteration 
				if (getTimer() > task.iterationStopTime)
					break; // not done yet
			}
			
			// hack for symbol plotters
			var symbolPlottersArray:Array = symbolPlotters.getObjects();
			var ourAsyncState:Object = task.asyncState;
			for each (var plotter:IPlotter in symbolPlottersArray)
			{
				if (task.iteration == 0)
				{
					_asyncState[plotter] = {};
					_asyncProgress[plotter] = 0;
				}
				task.asyncState = _asyncState[plotter];
				if (_asyncProgress[plotter] != 1)
					_asyncProgress[plotter] = plotter.drawPlotAsyncIteration(task);
				progress += _asyncProgress[plotter];
			}
			task.asyncState = ourAsyncState;
			
			return progress / (1 + symbolPlottersArray.length);
		}
		
		private const _asyncState:Dictionary = new Dictionary(true); // IPlotter -> Object
		private const _asyncProgress:Dictionary = new Dictionary(true); // IPlotter -> Number
		
		private static const tempPoint:Point = new Point(); // reusable object
		private static const tempMatrix:Matrix = new Matrix(); // reusable object

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
		private function drawShape(key:IQualifiedKey, points:Object, shapeType:String, dataBounds:IBounds2D, screenBounds:IBounds2D, outputGraphics:Graphics, outputBitmapData:BitmapData):void
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
					// round coordinates for faster & more consistent rendering
					tempPoint.x = Math.round(tempPoint.x);
					tempPoint.y = Math.round(tempPoint.y);
					if (pointDataImageColumn.getInternalColumn())
					{
						var bitmapData:BitmapData = pointDataImageColumn.getValueFromKey(key) || _missingImage;
						var imgWidth:Number = useFixedImageSize.value ? iconSize.value : bitmapData.width;
						var imgHeight:Number = useFixedImageSize.value ? iconSize.value : bitmapData.height;
						tempMatrix.identity();
						if (useFixedImageSize.value)
							tempMatrix.scale(iconSize.value / bitmapData.width, iconSize.value / bitmapData.height);
						tempMatrix.translate(tempPoint.x - imgWidth / 2, tempPoint.y - imgHeight / 2);
						outputBitmapData.draw(bitmapData, tempMatrix, null, null, null, true);
					}
					else
					{
						drawCircle(outputBitmapData, fill.color.getValueFromKey(key, Number), tempPoint.x, tempPoint.y);
					}
				}
				return;
			}

			// prevent moveTo/lineTo from drawing a filled polygon if the shape type is line
			if (shapeType == GeneralizedGeometry.GEOM_TYPE_LINE)
				outputGraphics.endFill();

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
					outputGraphics.moveTo(tempPoint.x, tempPoint.y);
					continue;
				}
				outputGraphics.lineTo(tempPoint.x, tempPoint.y);
			}
			
			if (shapeType == GeneralizedGeometry.GEOM_TYPE_POLYGON)
				outputGraphics.lineTo(firstX, firstY);
		}
		
		override public function dispose():void
		{
			disposeCachedBitmaps();
			super.dispose();
		}

		// backwards compatibility 0.9.6
		[Deprecated(replacement="line")] public function set lineStyle(value:Object):void
		{
			try {
				setSessionState(line, value[0].sessionState);
			} catch (e:Error) { }
		}
		[Deprecated(replacement="fill")] public function set fillStyle(value:Object):void
		{
			try {
				setSessionState(fill, value[0].sessionState);
			} catch (e:Error) { }
		}
		[Deprecated(replacement="geometryColumn")] public function set geometry(value:Object):void
		{
			setSessionState(geometryColumn.internalDynamicColumn, value);
		}
		// backwards compatibility May 2012
		[Deprecated(replacement="iconSize")] public function set pointShapeSize(value:Number):void { iconSize.value = value * 2; }
	}
}
