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

package org.oicweave.visualization.plotters
{
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Point;
	
	import org.oicweave.Weave;
	import org.oicweave.api.WeaveAPI;
	import org.oicweave.api.data.IAttributeColumn;
	import org.oicweave.api.data.IKeySet;
	import org.oicweave.api.data.IQualifiedKey;
	import org.oicweave.api.primitives.IBounds2D;
	import org.oicweave.core.LinkableBoolean;
	import org.oicweave.core.LinkableHashMap;
	import org.oicweave.core.LinkableNumber;
	import org.oicweave.core.LinkableString;
	import org.oicweave.data.AttributeColumns.AlwaysDefinedColumn;
	import org.oicweave.data.AttributeColumns.ColorColumn;
	import org.oicweave.data.KeySets.KeySet;
	import org.oicweave.utils.ColumnUtils;
	import org.oicweave.utils.DrawUtils;
	import org.oicweave.visualization.plotters.styles.ExtendedSolidLineStyle;
	
	/**
	 * @author heather byrne
	 * @author adufilie
	 * @author abaumann
	 */
	public class ParallelCoordinatesPlotter extends AbstractPlotter
	{
		public function ParallelCoordinatesPlotter()
		{
			lineStyle.color.internalDynamicColumn.requestGlobalObject(Weave.DEFAULT_COLOR_COLUMN, ColorColumn, false);
			lineStyle.weight.defaultValue.value = 1;
			lineStyle.alpha.defaultValue.value = 1.0;
			setKeySource(_combinedKeySet);
		}

		/*
		 * This is the line style used to draw the lines.
		 */
		public const lineStyle:ExtendedSolidLineStyle = newNonSpatialProperty(ExtendedSolidLineStyle);
		
		public function get alphaColumn():AlwaysDefinedColumn { return lineStyle.alpha; }
		
		public const columns:LinkableHashMap = registerSpatialProperty(new LinkableHashMap(IAttributeColumn), handleColumnsChange);
		
		private const _combinedKeySet:KeySet = newNonSpatialProperty(KeySet);
		
		private var _columns:Array = [];
		private function handleColumnsChange():void
		{
			_columns = columns.getObjects();

			// get list of all keys in all columns
			_combinedKeySet.delayCallbacks();
			if (_columns.length > 0)
				_combinedKeySet.replaceKeys((_columns[0] as IAttributeColumn).keys);
			else
				_combinedKeySet.clearKeys();
			for (var i:int = 1; i < _columns.length; i++)
			{
				_combinedKeySet.addKeys((_columns[i] as IAttributeColumn).keys);
			}
			_combinedKeySet.resumeCallbacks();
			
			// if there is only one column, push a copy of it so lines will be drawn
			if (_columns.length == 1)
				_columns.push(_columns[0]);
		}
		
		public const normalize:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(true));
		public const curveType:LinkableString  = registerNonSpatialProperty(new LinkableString(CURVE_NONE, curveTypeVerifier));
		public const shapeSize:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(5));

		public static const CURVE_NONE:String = 'none';
		public static const CURVE_TOWARDS:String = 'towards';
		public static const CURVE_AWAY:String = 'away';
		public static const CURVE_DOUBLE:String = 'double';
		private function curveTypeVerifier(type:String):Boolean
		{
			//BACKWARDS COMPATIBILITY 0.9.6
			// technically, the verifier function is not supposed to do this.
			if (type == "ParallelCoordinatesPlotter.LINE_STRAIGHT")
				curveType.value = CURVE_NONE;
			if (type == "ParallelCoordinatesPlotter.LINE_CURVE_TOWARDS")
				curveType.value = CURVE_TOWARDS;
			if (type == "ParallelCoordinatesPlotter.LINE_CURVE_AWAY")
				curveType.value = CURVE_AWAY;
			if (type == "ParallelCoordinatesPlotter.LINE_DOUBLE_CURVE")
				curveType.value = CURVE_DOUBLE;
			
			var types:Array = [CURVE_NONE, CURVE_TOWARDS, CURVE_AWAY, CURVE_DOUBLE];
			return types.indexOf(type) >= 0;
		}

		public static const shapesAvailable:Array = [NO_SHAPE, SOLID_CIRCLE, EMPTY_CIRCLE, SOLID_SQUARE, EMPTY_SQUARE, SOLID_TRIANGLE, EMPTY_TRIANGLE];
		
		public static const NO_SHAPE:String 	  = "No Shape";
		public static const SOLID_CIRCLE:String   = "Solid Circle";
		public static const EMPTY_CIRCLE:String   = "Empty Circle";
		public static const SOLID_SQUARE:String   = "Solid Square";
		public static const EMPTY_SQUARE:String   = "Empty Square";
		public static const SOLID_TRIANGLE:String = "Solid Triangle";
		public static const EMPTY_TRIANGLE:String = "Empty Triangle";
		private function shapeTypeVerifier(type:String):Boolean
		{
			return shapesAvailable.indexOf(type) >= 0;
		}
		
		public const shapeToDraw:LinkableString = registerNonSpatialProperty(new LinkableString(SOLID_CIRCLE, shapeTypeVerifier));
		public const shapeBorderThickness:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(0));
		public const shapeBorderColor:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(0x000000));
		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			var results:Array = [];
			var i:int;
			var _normalize:Boolean = normalize.value;
			for (i = 0; i < _columns.length; i++)
			{
				// project data coordinates to screen coordinates and draw graphics
				tempPoint.x = i;
				if (_normalize)
					tempPoint.y = ColumnUtils.getNorm(_columns[i], recordKey);
				else
					tempPoint.y = (_columns[i] as IAttributeColumn).getValueFromKey(recordKey, Number) as Number;
				
				var bounds:IBounds2D = getReusableBounds();
				bounds.setCenteredRectangle(tempPoint.x, tempPoint.y, 0, 0);
				results.push(bounds);
			}
			return results;
		}
		
		/**
		 * This function may be defined by a class that extends AbstractPlotter to use the basic template code in AbstractPlotter.drawPlot().
		 */
		override protected function addRecordGraphicsToTempShape(recordKey:IQualifiedKey, dataBounds:IBounds2D, screenBounds:IBounds2D, tempShape:Shape):void
		{
			var graphics:Graphics = tempShape.graphics;

			// project data coordinates to screen coordinates and draw graphics onto tempShape
			var i:int;
			var _normalize:Boolean = normalize.value;
			var _shapeSize:Number = this.shapeSize.value;
			var _prevX:Number = 0;
			var _prevY:Number = 0;
			var continueLine:Boolean = false;
			
			for (i = 0; i < _columns.length; i++)
			{
				// project data coordinates to screen coordinates and draw graphics
				tempPoint.x = i;
				if (_normalize)
					tempPoint.y = ColumnUtils.getNorm(_columns[i], recordKey);
				else
					tempPoint.y = (_columns[i] as IAttributeColumn).getValueFromKey(recordKey, Number) as Number;
				
				if (isNaN(tempPoint.y))
				{
					continueLine = false;
					continue;
				}
				
				dataBounds.projectPointTo(tempPoint, screenBounds);				
				var x:Number = tempPoint.x;
				var y:Number = tempPoint.y;

				
				// thickness of the line around each shape
				var shapeLineThickness:int = shapeBorderThickness.value;
				if(_shapeSize > 0)
				{
					var shapeSize:Number = _shapeSize;// - (shapeLineThickness*2) + 1;
					
					// use a gray border around each shape
					graphics.lineStyle(shapeLineThickness, shapeBorderColor.value, shapeLineThickness == 0 ? 0 : 1);
					// draw a different shape for each option
					switch(shapeToDraw.value)
					{								
						// solid circle
						case SOLID_CIRCLE:
							graphics.beginFill(lineStyle.color.getValueFromKey(recordKey));
							// circle uses radius, so size/2
							graphics.drawCircle(x, y, shapeSize/2);
							break;
						// empty circle
						case EMPTY_CIRCLE:
							graphics.lineStyle(shapeLineThickness, lineStyle.color.getValueFromKey(recordKey), shapeLineThickness == 0 ? 0 : 1);
							graphics.beginFill(0xFFFFFF);
							graphics.drawCircle(x, y, shapeSize/2);
							
							break;
						// solid square
						case SOLID_SQUARE:
							graphics.beginFill(lineStyle.color.getValueFromKey(recordKey));
							graphics.drawRect(x-_shapeSize/2, y-_shapeSize/2, _shapeSize, _shapeSize);
							break;
						// empty square
						case EMPTY_SQUARE:
							graphics.lineStyle(shapeLineThickness, lineStyle.color.getValueFromKey(recordKey), shapeLineThickness == 0 ? 0 : 1);
							graphics.beginFill(0xFFFFFF);
							graphics.drawRect(x-_shapeSize/2, y-_shapeSize/2, _shapeSize, _shapeSize);
							break;
						// solid triangle
						case SOLID_TRIANGLE:
							graphics.beginFill(lineStyle.color.getValueFromKey(recordKey));
							drawTriangleShape(graphics, x,y, shapeSize);
							break;
						// empty triangle
						case EMPTY_TRIANGLE:
							graphics.lineStyle(shapeLineThickness, lineStyle.color.getValueFromKey(recordKey), shapeLineThickness == 0 ? 0 : 1);
							graphics.beginFill(0xFFFFFF);
							drawTriangleShape(graphics, x,y, shapeSize);
							break;
					}
					
					graphics.endFill();
				}
				
				// begin the line style for the parallel coordinates line
				// we want to use the missing data line style since the line is the shape we are showing 
				// (rather than just a border of another shape)
				lineStyle.beginLineStyle(recordKey, graphics);
				
				// uncomment this to fill in area the line creates -- works well with curved lines
				//graphics.beginFill(lineStyle.color.getValueFromKey(recordKey), 0.3);
				
				/** We want to draw the lines up to the left of a shape, and from the right of the shape. **/
				// get half of the shape size (distance it goes right or left of the center point for that shape)
				var halfSize:Number = _shapeSize/2; 
				
				// if the shape is a triangle, we have to push the lines in further since the triangle is 1/2 its width at the center
				if(shapeToDraw.value == EMPTY_TRIANGLE || shapeToDraw.value == SOLID_TRIANGLE)
					halfSize = _shapeSize/4;
				
				// the coordinate to the left of the shape
				var xBeforeShape:Number 	= x - halfSize;	
				// the coorinate to the right of the shape
				var xAfterShape:Number  	= x + halfSize;
				// the previous coordinate to the left of the shape
				var prevXBeforeShape:Number = _prevX - halfSize;
				// the previous coorinate to the right of the shape	
				var prevXAfterShape:Number  = _prevX + halfSize;
				
				// if we aren't continuing a new line (it is a new line segment)	
				if (!continueLine)
				{
					// set the previous X and Y locations to be this new coordinate
					prevXAfterShape = x;
					_prevY = y;
					
					// move the pen to this location
					graphics.moveTo(x, y);
				}
				else
				{
					// otherwise move to the previous coordinate to the right of the shape and previous Y
					graphics.moveTo(prevXAfterShape, _prevY);	
				}
				
				// this is to avoid drawing any lines to the left of the y-axis
				if( (xBeforeShape - prevXAfterShape) >= 0)
				{
					// if it is a straight line, just do a line to the next coordinate to the left of the shape
					if (curveType.value == CURVE_NONE)
					{
						graphics.lineTo(xBeforeShape, y);
						//DrawUtils.drawDashedLine(tempShape.graphics, _prevX, _prevY, x, y, 3, 2); 
					}
					// otherwise for curves, curve from the coordinate to the right of the previous point to the 
					// coordinate before the next shape
					else if (curveType.value == CURVE_DOUBLE)
						DrawUtils.drawDoubleCurve(graphics, prevXAfterShape, _prevY, xBeforeShape, y, true, 1);
					else if(curveType.value == CURVE_TOWARDS)
						DrawUtils.drawCurvedLine(graphics, prevXAfterShape,  _prevY, xBeforeShape, y, -1);
					else if(curveType.value == CURVE_AWAY)
						DrawUtils.drawCurvedLine(graphics, prevXAfterShape,  _prevY, xBeforeShape, y,  1);
				}
				
				// move the pen to the point following the next shape
				if (_shapeSize > 0)
					graphics.moveTo(xAfterShape, y);
					
				continueLine = true;

				_prevX = x;
				_prevY = y;
			}
		}
		
		private function drawTriangleShape(graphics:Graphics, x:Number, y:Number, size:int):void
		{
			var halfSize:Number = size/2;
			
			// top point, half height above the center point (x,y)
			graphics.moveTo(x, y-halfSize);
			// bottom left
			graphics.lineTo(x-halfSize, y+halfSize);
			// bottom right
			graphics.lineTo(x+halfSize, y+halfSize);
			// back up to the top
			graphics.lineTo(x, y-halfSize);
		}
		
		override public function getBackgroundDataBounds():IBounds2D
		{
			// normalized data coordinates
			var bounds:IBounds2D = getReusableBounds();
			bounds.setBounds(0, 0, Math.max(1, columns.getNames().length - 1), 1);
			
			if (!normalize.value)
			{
				// reset y coords
				bounds.setYRange(NaN, NaN);
				for each (var column:IAttributeColumn in columns.getObjects())
				{
					// expand y range to include all data coordinates
					bounds.includeCoords(0, WeaveAPI.StatisticsCache.getMin(column));
					bounds.includeCoords(0, WeaveAPI.StatisticsCache.getMax(column));
				}
			}
			
			return bounds;
		}
		
		private static const tempPoint:Point = new Point(); // reusable object
	}
}
