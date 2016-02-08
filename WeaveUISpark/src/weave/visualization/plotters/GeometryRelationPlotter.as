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
	import flash.geom.Point;
	import flash.text.TextFormat;
	
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IObjectWithDescription;
	import weave.api.ui.IPlotTask;
	import weave.api.ui.IPlotter;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.ReprojectedGeometryColumn;
	import weave.primitives.GeneralizedGeometry;
	import weave.utils.BitmapText;
	import weave.utils.EquationColumnLib;

	public class GeometryRelationPlotter extends AbstractPlotter implements IObjectWithDescription
	{
		WeaveAPI.ClassRegistry.registerImplementation(IPlotter, GeometryRelationPlotter, "Geometry relations");

		public function GeometryRelationPlotter()
		{
			registerSpatialProperty(geometryColumn);
			valueStats = registerLinkableChild(this, WeaveAPI.StatisticsCache.getColumnStatistics(valueColumn));
			
			setColumnKeySources([geometryColumn]);
		}
		
		public function getDescription():String
		{
			return geometryColumn.getDescription();
		}
		
		public const geometryColumn:ReprojectedGeometryColumn = newSpatialProperty(ReprojectedGeometryColumn);
		public const sourceKeyColumn:DynamicColumn = newSpatialProperty(DynamicColumn);
		public const destinationKeyColumn:DynamicColumn = newSpatialProperty(DynamicColumn);
		public const valueColumn:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const lineWidth:LinkableNumber = registerLinkableChild(this, new LinkableNumber(5));
		public const posLineColor:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0xFF0000));
		public const negLineColor:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0x0000FF));
		public const showValue:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		public const fontSize:LinkableNumber = registerLinkableChild(this, new LinkableNumber(11));
		public const fontColor:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0x000000));
		private var valueStats:IColumnStatistics;
		
		private const bitmapText:BitmapText = new BitmapText();
		protected const tempPoint:Point = new Point();
		protected const tempSourcePoint:Point = new Point();
		
		/**
		 * @param geomKey
		 * @param output
		 * @return true on success 
		 */
		protected function getGeomCoords(geomKey:IQualifiedKey, output:Point):Boolean
		{
			var geoms:Array = geometryColumn.getValueFromKey(geomKey, Array) as Array;
			var geom:GeneralizedGeometry;
			if (geoms && geoms.length)
				geom = geoms[0] as GeneralizedGeometry;
			if (geom)
			{
				geom.bounds.getCenterPoint(output);
				return true;
			}
			else
			{
				output.x = output.y = NaN;
				return false;
			}
		}
		
		public var includeDestPointsInDataBounds:Boolean = false; // for testing
		
		override public function getDataBoundsFromRecordKey(geomKey:IQualifiedKey, output:Array):void
		{
			getGeomCoords(geomKey, tempPoint);
			
			if (includeDestPointsInDataBounds)
			{
				var rowKeys:Array = EquationColumnLib.getAssociatedKeys(sourceKeyColumn, geomKey);
				var n:int = rowKeys ? rowKeys.length : 0;
				initBoundsArray(output, n + 1).includePoint(tempPoint);
				for (var i:int = 0; i < n; i++)
				{
					getGeomCoords(destinationKeyColumn.getValueFromKey(rowKeys[i], IQualifiedKey), tempPoint);
					(output[i + 1] as IBounds2D).includePoint(tempPoint);
				}
			}
			else
			{
				initBoundsArray(output).includePoint(tempPoint);
			}
		}
		
		override public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			// Make sure all four column are populated
			if (task.iteration == 0 && (
					sourceKeyColumn.keys.length == 0
					|| destinationKeyColumn.keys.length == 0
					|| valueColumn.keys.length == 0
					|| geometryColumn.keys.length == 0))
				return 1;
			
			// this template from AbstractPlotter will draw one record per iteration
			if (task.iteration < task.recordKeys.length)
			{
				
				//------------------------
				// draw one record
				var geoKey:IQualifiedKey = task.recordKeys[task.iteration] as IQualifiedKey;
				tempShape.graphics.clear();

				if (!getGeomCoords(geoKey, tempSourcePoint))
					return task.iteration / task.recordKeys.length;
				
				task.dataBounds.projectPointTo(tempSourcePoint, task.screenBounds);

				var rowKeys:Array = EquationColumnLib.getAssociatedKeys(sourceKeyColumn, geoKey);
				var rowKey:IQualifiedKey;
				var destKey:IQualifiedKey;
				var value:Number;
				
				// Draw lines from source to destinations
				var absMax:Number = Math.max(Math.abs(valueStats.getMin()), Math.abs(valueStats.getMax()));
				
				// Value normalization
				for each (rowKey in rowKeys)
				{
					destKey = destinationKeyColumn.getValueFromKey(rowKey, IQualifiedKey);
					value = valueColumn.getValueFromKey(rowKey, Number);
					
					if (geoKey == destKey)
						continue;
					
					var color:uint = value < 0 ? negLineColor.value : posLineColor.value;
					var thickness:Number = Math.abs(value / absMax) * lineWidth.value;
					var ceil:Number = Math.ceil(thickness);
					var floor:Number = Math.floor(thickness);
					var fractional:Number = thickness - floor;
					var alpha:Number = floor/ceil + (1.0 - floor/ceil) * fractional; // between floor/ceil and 1
					tempShape.graphics.lineStyle(thickness, color, alpha);
					tempShape.graphics.moveTo(tempSourcePoint.x, tempSourcePoint.y);
					if (!getGeomCoords(destKey, tempPoint))
						continue;
					task.dataBounds.projectPointTo(tempPoint, task.screenBounds);
					tempShape.graphics.lineTo(tempPoint.x, tempPoint.y);
				}
								
				task.buffer.draw(tempShape);
				
				if (showValue.value)
				{
					for each (rowKey in rowKeys)
					{
						destKey = destinationKeyColumn.getValueFromKey(rowKey, IQualifiedKey);
						if (!getGeomCoords(destKey, tempPoint))
							continue;
						task.dataBounds.projectPointTo(tempPoint, task.screenBounds);
						
						bitmapText.x = Math.round((tempSourcePoint.x + tempPoint.x) / 2);
						bitmapText.y = Math.round((tempSourcePoint.y + tempPoint.y) / 2);
						bitmapText.text = valueColumn.getValueFromKey(rowKey, String);
						bitmapText.verticalAlign = BitmapText.VERTICAL_ALIGN_MIDDLE;
						bitmapText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_CENTER;
						
						var f:TextFormat = bitmapText.textFormat;
						f.size = fontSize.value;
						f.color = fontColor.value;
						
						bitmapText.draw(task.buffer);
					}
				}
				
				// report progress
				return task.iteration / task.recordKeys.length;
			}
			
			// report progress
			return 1; // avoids division by zero in case task.recordKeys.length == 0
		}
	}
}