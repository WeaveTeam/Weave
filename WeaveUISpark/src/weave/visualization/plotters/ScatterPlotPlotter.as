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
	import weave.api.WeaveAPI;
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.api.setSessionState;
	import weave.api.ui.IPlotTask;
	import weave.api.ui.IPlotter;
	import weave.compiler.StandardLib;
	import weave.core.CallbackJuggler;
	import weave.core.DynamicState;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.data.AttributeColumns.BinnedColumn;
	import weave.data.AttributeColumns.ColorColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.visualization.plotters.styles.DynamicLineStyle;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * @author adufilie
	 */
	public class ScatterPlotPlotter extends AbstractGlyphPlotter
	{
		WeaveAPI.registerImplementation(IPlotter, ScatterPlotPlotter, "Scatterplot");
		
		public function ScatterPlotPlotter()
		{
			// initialize default line & fill styles
			lineStyle.requestLocalObject(SolidLineStyle, false);
			fill.color.internalDynamicColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;
			
			fill.color.internalDynamicColumn.addImmediateCallback(this, handleColor, true);
			getCallbackCollection(colorDataJuggler).addImmediateCallback(this, updateKeySources, true);
		}
		
		/**
		 * This is the radius of the circle, in screen coordinates.
		 */
		public const screenRadius:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const minScreenRadius:LinkableNumber = registerLinkableChild(this, new LinkableNumber(3, isFinite));
		public const maxScreenRadius:LinkableNumber = registerLinkableChild(this, new LinkableNumber(12, isFinite));
		public const defaultScreenRadius:LinkableNumber = registerLinkableChild(this, new LinkableNumber(5, isFinite));
		public const enabledSizeBy:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		
		public const lineStyle:DynamicLineStyle = newLinkableChild(this, DynamicLineStyle);
		public const fill:SolidFillStyle = newLinkableChild(this, SolidFillStyle);
		public const absoluteValueColorEnabled:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		public const absoluteValueColorMin:LinkableNumber = registerLinkableChild(this, new LinkableNumber());
		public const absoluteValueColorMax:LinkableNumber = registerLinkableChild(this, new LinkableNumber());
		
		// for line connecting demo
		public var connectTheDots:Boolean = false;
		private var prevPoint:Point;
		
		// delare dependency on statistics (for norm values)
		private const _screenRadiusStats:IColumnStatistics = registerLinkableChild(this, WeaveAPI.StatisticsCache.getColumnStatistics(screenRadius));
		public var hack_horizontalBackgroundLineStyle:Array;
		public var hack_verticalBackgroundLineStyle:Array;
		
		private const colorDataJuggler:CallbackJuggler = newDisposableChild(this, CallbackJuggler);
		
		private var _extraKeyDependencies:Array;
		private var _keyInclusionLogic:Function;
		
		public function hack_setKeyInclusionLogic(keyInclusionLogic:Function, extraColumnDependencies:Array):void
		{
			_extraKeyDependencies = extraColumnDependencies;
			_keyInclusionLogic = keyInclusionLogic;
			updateKeySources();
		}
		
		private function handleColor():void
		{
			var cc:ColorColumn = fill.color.getInternalColumn() as ColorColumn;
			var bc:BinnedColumn = cc ? cc.getInternalColumn() as BinnedColumn : null;
			var fc:FilteredColumn = bc ? bc.getInternalColumn() as FilteredColumn : null;
			colorDataJuggler.target = fc ? fc.internalDynamicColumn : null;
		}
		
		private function updateKeySources():void
		{
			var columns:Array = [screenRadius, colorDataJuggler.target, dataX, dataY].concat(_extraKeyDependencies || []);
			_filteredKeySet.setColumnKeySources(columns, [true], null, _keyInclusionLogic);
		}
		
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			if (!filteredKeySet.keys.length)
				return;
			if (hack_horizontalBackgroundLineStyle)
			{
				tempShape.graphics.clear();
				tempShape.graphics.lineStyle.apply(null, hack_horizontalBackgroundLineStyle);
				tempShape.graphics.moveTo(screenBounds.getXMin(), screenBounds.getYCenter());
				tempShape.graphics.lineTo(screenBounds.getXMax(), screenBounds.getYCenter());
				destination.draw(tempShape);
			}
			if (hack_verticalBackgroundLineStyle)
			{
				tempShape.graphics.clear();
				tempShape.graphics.lineStyle.apply(null, hack_verticalBackgroundLineStyle);
				tempShape.graphics.moveTo(screenBounds.getXCenter(), screenBounds.getYMin());
				tempShape.graphics.lineTo(screenBounds.getXCenter(), screenBounds.getYMax());
				destination.draw(tempShape);
			}
		}
		
		override public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			// this template will draw one record per iteration
			if (task.iteration == 0)
			{
				if (!task.asyncState)
					task.asyncState = {};
				if (!task.asyncState.prevPoint)
					task.asyncState.prevPoint = new Point();
				var p:Point = task.asyncState.prevPoint as Point;
				p.x = p.y = NaN;
			}
			prevPoint = task.asyncState.prevPoint as Point;
			return super.drawPlotAsyncIteration(task);
		}
		
		/**
		 * This function may be defined by a class that extends AbstractPlotter to use the basic template code in AbstractPlotter.drawPlot().
		 */
		override protected function addRecordGraphicsToTempShape(recordKey:IQualifiedKey, dataBounds:IBounds2D, screenBounds:IBounds2D, tempShape:Shape):void
		{
			var graphics:Graphics = tempShape.graphics;
			graphics.clear();
			
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
			
			var hasPrevPoint:Boolean = connectTheDots && isFinite(prevPoint.x) && isFinite(prevPoint.y);
			if (hasPrevPoint)
			{
				graphics.moveTo(prevPoint.x, prevPoint.y);
				graphics.lineTo(tempPoint.x, tempPoint.y);
			}
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
					//trace('circle',tempPoint);
					graphics.drawCircle(tempPoint.x, tempPoint.y, radius);
				}
			}
			graphics.endFill();
			
			prevPoint.x = tempPoint.x;
			prevPoint.y = tempPoint.y;
		}
		
		// backwards compatibility
		[Deprecated] public function set circlePlotter(value:Object):void { setSessionState(this, value); }
		[Deprecated] public function set xColumn(value:Object):void { setSessionState(dataX, value); }
		[Deprecated] public function set yColumn(value:Object):void { setSessionState(dataY, value); }
		[Deprecated] public function set alphaColumn(value:Object):void { setSessionState(fill.alpha, value); }
		[Deprecated] public function set colorColumn(value:Object):void { setSessionState(fill.color, value); }
		[Deprecated] public function set radiusColumn(value:Object):void { setSessionState(screenRadius, value); }
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
	}
}

