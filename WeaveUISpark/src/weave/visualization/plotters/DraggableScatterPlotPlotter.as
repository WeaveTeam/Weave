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
	import flash.utils.Dictionary;
	
	import weave.Weave;
	import weave.api.core.DynamicState;
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
	import weave.api.ui.ISelectableAttributes;
	import weave.compiler.StandardLib;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableDynamicObject;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.core.LinkableVariable;
	import weave.core.LinkableWatcher;
	import weave.data.AttributeColumns.BinnedColumn;
	import weave.data.AttributeColumns.ColorColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * @author adufilie
	 */
	public class DraggableScatterPlotPlotter extends AbstractGlyphPlotter implements ISelectableAttributes
	{
		public const movedDataPoints:LinkableVariable = registerSpatialProperty(new LinkableVariable(Dictionary, null, new Dictionary()));		
		private var tempDictionary:Dictionary;
		
		WeaveAPI.ClassRegistry.registerImplementation(IPlotter, DraggableScatterPlotPlotter, "Draggable Scatterplot");
		
		public function DraggableScatterPlotPlotter()
		{
			fill.color.internalDynamicColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;
			fill.color.internalDynamicColumn.addImmediateCallback(this, handleColor, true);
			getCallbackCollection(colorDataWatcher).addImmediateCallback(this, updateKeySources, true);
			
		}
		
		public function getSelectableAttributeNames():Array
		{
			return ["X", "Y", "Color", "Size"];
		}
		public function getSelectableAttributes():Array
		{
			return [dataX, dataY, fill.color, sizeBy];
		}
		
		public const sizeBy:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const minScreenRadius:LinkableNumber = registerLinkableChild(this, new LinkableNumber(3, isFinite));
		public const maxScreenRadius:LinkableNumber = registerLinkableChild(this, new LinkableNumber(25, isFinite));
		public const defaultScreenRadius:LinkableNumber = registerLinkableChild(this, new LinkableNumber(5, isFinite));
		
		public const line:SolidLineStyle = newLinkableChild(this, SolidLineStyle);
		public const fill:SolidFillStyle = newLinkableChild(this, SolidFillStyle);
		public const colorBySize:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		public const colorNegative:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0x800000));
		public const colorPositive:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0x008000));
		
		// delare dependency on statistics (for norm values)
		private const _sizeByStats:IColumnStatistics = registerLinkableChild(this, WeaveAPI.StatisticsCache.getColumnStatistics(sizeBy));
		public var hack_horizontalBackgroundLineStyle:Array;
		public var hack_verticalBackgroundLineStyle:Array;
		
		private const colorDataWatcher:LinkableWatcher = newDisposableChild(this, LinkableWatcher);
		
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
			var dc:DynamicColumn = fc ? fc.internalDynamicColumn : null;
			colorDataWatcher.target = dc || fc || bc || cc;
		}
		
		private function updateKeySources():void
		{
			var columns:Array = [sizeBy];
			if (colorDataWatcher.target)
				columns.push(colorDataWatcher.target)
			columns.push(dataX, dataY);
			if (_extraKeyDependencies)
				columns = columns.concat(_extraKeyDependencies);
			
			// sort size descending, all others ascending
			var sortDirections:Array = columns.map(function(c:*, i:int, a:*):int { return i == 0 ? -1 : 1; });
			
			_filteredKeySet.setColumnKeySources(columns, sortDirections, null, _keyInclusionLogic);
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
		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey, output:Array):void
		{
			tempDictionary = movedDataPoints.getSessionState() as Dictionary;
			
			if( !(tempDictionary[recordKey.localName] != null) )
				getCoordsFromRecordKey(recordKey, tempPoint);
			else
			{
				tempPoint.x = (tempDictionary[recordKey.localName] as Object).x;
				tempPoint.y = (tempDictionary[recordKey.localName] as Object).y;
			}
			
			var bounds:IBounds2D = initBoundsArray(output);
			bounds.includePoint(tempPoint);
			if (isNaN(tempPoint.x))
				bounds.setXRange(-Infinity, Infinity);
			if (isNaN(tempPoint.y))
				bounds.setYRange(-Infinity, Infinity);
		}
		
		/**
		 * This function may be defined by a class that extends AbstractPlotter to use the basic template code in AbstractPlotter.drawPlot().
		 */
		override protected function addRecordGraphicsToTempShape(recordKey:IQualifiedKey, dataBounds:IBounds2D, screenBounds:IBounds2D, tempShape:Shape):void
		{
			tempDictionary = movedDataPoints.getSessionState() as Dictionary;
			
			var graphics:Graphics = tempShape.graphics;
			graphics.clear();
			
			// project data coordinates to screen coordinates and draw graphics
			if( !(tempDictionary[recordKey.localName] != null) )
				getCoordsFromRecordKey(recordKey, tempPoint);
			else
			{
				tempPoint.x = (tempDictionary[recordKey.localName] as Object).x;
				tempPoint.y = (tempDictionary[recordKey.localName] as Object).y;
			}
			
 			dataBounds.projectPointTo(tempPoint, screenBounds);
			
			line.beginLineStyle(recordKey, graphics);
			fill.beginFillStyle(recordKey, graphics);
			
			var radius:Number;
			if (colorBySize.value)
			{
				var sizeData:Number = sizeBy.getValueFromKey(recordKey, Number);
				var alpha:Number = fill.alpha.getValueFromKey(recordKey, Number);
				if( sizeData < 0 )
					graphics.beginFill(colorNegative.value, alpha);
				else if( sizeData > 0 )
					graphics.beginFill(colorPositive.value, alpha);
				var min:Number = _sizeByStats.getMin();
				var max:Number = _sizeByStats.getMax();
				var absMax:Number = Math.max(Math.abs(min), Math.abs(max));
				var normRadius:Number = StandardLib.normalize(Math.abs(sizeData), 0, absMax);
				radius = normRadius * maxScreenRadius.value;
			}
			else if (sizeBy.internalObject)
			{
				radius = minScreenRadius.value + (_sizeByStats.getNorm(recordKey) * (maxScreenRadius.value - minScreenRadius.value));
			}
			else
			{
				radius = defaultScreenRadius.value;
			}
			
			if (!isFinite(radius))
			{
				// handle undefined radius
				if (colorBySize.value)
				{
					// draw nothing
				}
				else if (sizeBy.internalObject)
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
				if (colorBySize.value && radius == 0)
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
		}
		
		private var keyBeingDragged:IQualifiedKey;
		public var isDragging:Boolean = false;
		
		public function startPointDrag(key:IQualifiedKey):void
		{
			keyBeingDragged = key;
			//trace("Dragging Started  " + keyBeingDragged.localName);
			isDragging = true;
		}
		
		public function updatePointDrag(tempDragPoint:Point):void
		{
			if( keyBeingDragged != null )
			{
				//trace("Dragging happening  " + keyBeingDragged.localName);
				tempDictionary = movedDataPoints.getSessionState() as Dictionary;
				tempDictionary[keyBeingDragged.localName] = tempDragPoint;
				movedDataPoints.setSessionState(tempDictionary);
			}
		}
		
		public function stopPointDrag(endPoint:Point):void
		{
			//trace("Dragging End  " + keyBeingDragged.localName);
			isDragging = false;
			if(keyBeingDragged != null )
			{
				tempDictionary = movedDataPoints.getSessionState() as Dictionary;
				tempDictionary[keyBeingDragged.localName] = endPoint;
				movedDataPoints.setSessionState(tempDictionary);
			}
			keyBeingDragged = null;
		}
		
		public function resetMovedDataPoints():void
		{
			movedDataPoints.setSessionState(new Dictionary());
		}
		
		// backwards compatibility
		[Deprecated] public function set absoluteValueColorEnabled(value:Boolean):void { colorBySize.value = value; }
		[Deprecated] public function set absoluteValueColorMin(value:Number):void { colorNegative.value = value; }
		[Deprecated] public function set absoluteValueColorMax(value:Number):void { colorPositive.value = value; }
		[Deprecated] public function set circlePlotter(value:Object):void { setSessionState(this, value); }
		[Deprecated] public function set xColumn(value:Object):void { setSessionState(dataX, value); }
		[Deprecated] public function set yColumn(value:Object):void { setSessionState(dataY, value); }
		[Deprecated] public function set alphaColumn(value:Object):void { setSessionState(fill.alpha, value); }
		[Deprecated] public function set colorColumn(value:Object):void { setSessionState(fill.color, value); }
		[Deprecated] public function set radiusColumn(value:Object):void { setSessionState(sizeBy, value); }
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
		[Deprecated] public function set lineStyle(value:Object):void
		{
			try
			{
				setSessionState(line, value[0][DynamicState.SESSION_STATE]);
			}
			catch (e:Error)
			{
				reportError(e);
			}
		}
		[Deprecated(replacement="sizeBy")] public function set screenRadius(value:Object):void
		{
			if (_deprecatedEnabledSizeBy)
				setSessionState(sizeBy, value);
			else
				sizeBy.removeObject();
			_deprecatedEnabledSizeBy = true;
		}
		[Deprecated(replacement="sizeBy")] public function set enabledSizeBy(value:Boolean):void
		{
			_deprecatedEnabledSizeBy = value;
			if (!value)
				sizeBy.removeObject();
		}
		private var _deprecatedEnabledSizeBy:Boolean = true;
	}
}
