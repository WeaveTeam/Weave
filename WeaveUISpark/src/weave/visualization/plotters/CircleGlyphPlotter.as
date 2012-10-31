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
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Point;
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.api.setSessionState;
	import weave.compiler.StandardLib;
	import weave.core.DynamicState;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.visualization.plotters.styles.DynamicLineStyle;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * CirclePlotter
	 * 
	 * @author adufilie
	 */
	public class CircleGlyphPlotter extends AbstractGlyphPlotter
	{
		public function CircleGlyphPlotter()
		{
			// initialize default line & fill styles
			lineStyle.requestLocalObject(SolidLineStyle, false);
			fill.color.internalDynamicColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;
		}

		public const minScreenRadius:LinkableNumber = registerLinkableChild(this, new LinkableNumber(3, isFinite));
		public const maxScreenRadius:LinkableNumber = registerLinkableChild(this, new LinkableNumber(12, isFinite));
		public const defaultScreenRadius:LinkableNumber = registerLinkableChild(this, new LinkableNumber(5, isFinite));
		public const enabledSizeBy:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));

		public const absoluteValueColorEnabled:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		public const absoluteValueColorMin:LinkableNumber = registerLinkableChild(this, new LinkableNumber());
		public const absoluteValueColorMax:LinkableNumber = registerLinkableChild(this, new LinkableNumber());
		
		/**
		 * This is the radius of the circle, in screen coordinates.
		 */
		public const screenRadius:DynamicColumn = newLinkableChild(this, DynamicColumn);
		// delare dependency on statistics (for norm values)
		private const _screenRadiusStats:IColumnStatistics = registerLinkableChild(this, WeaveAPI.StatisticsCache.getColumnStatistics(screenRadius));
		public const lineStyle:DynamicLineStyle = newLinkableChild(this, DynamicLineStyle);
		
		// backwards compatibility
		[Deprecated] public function set fillStyle(value:Object):void
		{
			try
			{
				setSessionState(fill, value[0][DynamicState.SESSION_STATE]);
			}
			catch (e:Error)
			{
				reportError(e);
			}
		}
		
		public const fill:SolidFillStyle = newLinkableChild(this, SolidFillStyle);

		/**
		 * This function may be defined by a class that extends AbstractPlotter to use the basic template code in AbstractPlotter.drawPlot().
		 */
		override protected function addRecordGraphicsToTempShape(recordKey:IQualifiedKey, dataBounds:IBounds2D, screenBounds:IBounds2D, tempShape:Shape):void
		{
//			var hasPrevPoint:Boolean = (isFinite(tempPoint.x) && isFinite(tempPoint.y));
			var graphics:Graphics = tempShape.graphics;
			
			// project data coordinates to screen coordinates and draw graphics
			getCoordsFromRecordKey(recordKey, tempPoint);
			
			dataBounds.projectPointTo(tempPoint, screenBounds);
			
			lineStyle.beginLineStyle(recordKey, graphics);
			fill.beginFillStyle(recordKey, graphics);
			
			var radius:Number;
			if (absoluteValueColorEnabled.value)
			{
				var sizeData:Number = screenRadius.getValueFromKey(recordKey);
				var alpha:Number = fill.alpha.getValueFromKey(recordKey);
				if( sizeData < 0 )
					graphics.beginFill(absoluteValueColorMin.value, alpha);
				else if( sizeData > 0 )
					graphics.beginFill(absoluteValueColorMax.value, alpha);
				var stats:IColumnStatistics = WeaveAPI.StatisticsCache.getColumnStatistics(screenRadius);
				var min:Number = stats.getMin();
				var max:Number = stats.getMax();
				var absMax:Number = Math.max(Math.abs(min), Math.abs(max));
				var normRadius:Number = StandardLib.normalize(Math.abs(sizeData), 0, absMax);
				radius = normRadius * maxScreenRadius.value;
			}
			else if (enabledSizeBy.value)
			{
				radius = minScreenRadius.value + (_screenRadiusStats.getNorm(recordKey) *(maxScreenRadius.value - minScreenRadius.value));
			}
			else
			{
				radius = defaultScreenRadius.value;
			}
			
//			if (hasPrevPoint)
//				graphics.lineTo(tempPoint.x, tempPoint.y);
			if (!isFinite(radius))
			{
				// handle undefined radius
				if (absoluteValueColorEnabled.value)
				{
					// draw nothing
				}
				else if (enabledSizeBy.value)
				{
					// draw square
					radius = defaultScreenRadius.value;
					graphics.drawRect(tempPoint.x - radius, tempPoint.y - radius, radius * 2, radius * 2);
				}
				else
				{
					// draw default circle
					graphics.drawCircle(tempPoint.x, tempPoint.y, defaultScreenRadius.value );
				}
			}
			else
			{
				if (absoluteValueColorEnabled.value && radius == 0)
				{
					// draw nothing
				}
				else
				{
					graphics.drawCircle(tempPoint.x, tempPoint.y, radius);
				}
			}
			graphics.endFill();
//			graphics.moveTo(tempPoint.x, tempPoint.y);
		}
	}
}
