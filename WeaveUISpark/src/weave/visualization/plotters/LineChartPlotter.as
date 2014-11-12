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
	import flash.geom.Point;
	
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.reportError;
	import weave.api.ui.IPlotTask;
	import weave.api.ui.IPlotter;
	import weave.api.ui.ISelectableAttributes;
	import weave.core.SessionManager;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.KeySets.FilteredKeySet;
	import weave.visualization.layers.PlotTask;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	public class LineChartPlotter extends AbstractPlotter implements ISelectableAttributes
	{
		WeaveAPI.ClassRegistry.registerImplementation(IPlotter, LineChartPlotter, "Line Chart");
		
		public function LineChartPlotter()
		{
			sortedUnfilteredKeys.setColumnKeySources([group, order, dataX, dataY]);
			setSingleKeySource(sortedUnfilteredKeys);
			
			// temporary solution until lineStyle is given record keys
			var sm:SessionManager = WeaveAPI.SessionManager as SessionManager;
			var ls:SolidLineStyle = lineStyle;
			for each (var adc:AlwaysDefinedColumn in [ls.alpha,ls.caps,ls.color,ls.joints,ls.miterLimit,ls.pixelHinting,ls.scaleMode,ls.weight])
				sm.excludeLinkableChildFromSessionState(adc, adc.internalDynamicColumn);
		}
		
		public function getSelectableAttributeNames():Array
		{
			return ["X", "Y", "Order", "Group"];
		}
		public function getSelectableAttributes():Array
		{
			return [dataX, dataY, order, group];
		}
		
		private const sortedUnfilteredKeys:FilteredKeySet = newSpatialProperty(FilteredKeySet);
		
		public const group:DynamicColumn = newLinkableChild(this, DynamicColumn);
 		public const order:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const dataX:DynamicColumn = newSpatialProperty(DynamicColumn);
		public const dataY:DynamicColumn = newSpatialProperty(DynamicColumn);
		
		public const lineStyle:SolidLineStyle = newLinkableChild(this, SolidLineStyle);
		
		override public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			if (!(task.asyncState is AsyncState))
				task.asyncState = new AsyncState(this, task, sortedUnfilteredKeys);
			return (task.asyncState as AsyncState).iterate();
		}
		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey, output:Array):void
		{
			var x:Number = dataX.getValueFromKey(recordKey, Number);
			var y:Number = dataY.getValueFromKey(recordKey, Number);
			initBoundsArray(output).setCenteredRectangle(x, y, 0, 0);
		}
	}
}

import flash.display.Graphics;
import flash.display.Shape;
import flash.geom.Point;
import flash.utils.getTimer;

import mx.utils.ObjectUtil;

import weave.api.data.IKeySet;
import weave.api.data.IQualifiedKey;
import weave.api.newDisposableChild;
import weave.api.reportError;
import weave.api.ui.IPlotTask;
import weave.data.KeySets.KeySet;
import weave.visualization.layers.PlotTask;
import weave.visualization.plotters.LineChartPlotter;

internal class AsyncState
{
	public function AsyncState(plotter:LineChartPlotter, task:IPlotTask, unfilteredKeySet:IKeySet)
	{
		this.plotter = plotter;
		this.task = task;
		this.unfilteredKeySet = unfilteredKeySet;
		this.shape = new Shape();
		this.point = new Point();
		if ((task as PlotTask).taskType != PlotTask.TASK_TYPE_SUBSET)
			this.keySet = newDisposableChild(plotter, KeySet);
	}
	
	public var plotter:LineChartPlotter;
	public var task:IPlotTask;
	public var shape:Shape;
	public var point:Point;
	public var unfilteredKeySet:IKeySet;
	public var keys:Array;
	public var keyIndex:Number;
	public var handlePoint:Function;
	public var keySet:KeySet;
	public var group:Number;
	
	public function iterate():Number
	{
		var graphics:Graphics = shape.graphics;
		if (task.iteration == 0)
		{
			handlePoint = graphics.moveTo;
			if (keySet)
			{
				keySet.clearKeys();
				keySet.replaceKeys(task.recordKeys);
			}
			keys = unfilteredKeySet.keys;
			keyIndex = 0;
		}
		
		try
		{
			graphics.clear();
			graphics.moveTo(point.x, point.y);
			plotter.lineStyle.beginLineStyle(null, graphics);
			
			for (; keyIndex < keys.length; keyIndex++)
			{
				if (getTimer() > task.iterationStopTime)
				{
					task.buffer.draw(shape);
					return keyIndex / keys.length;
				}
				
				var key:IQualifiedKey = keys[keyIndex] as IQualifiedKey;
				
				if (keySet ? keySet.containsKey(key) : plotter.filteredKeySet.containsKey(key))
				{
					point.x = plotter.dataX.getValueFromKey(key, Number);
					point.y = plotter.dataY.getValueFromKey(key, Number);
				}
				else
				{
					point.x = point.y = NaN;
				}
				
				if (isFinite(point.x) && isFinite(point.y))
					task.dataBounds.projectPointTo(point, task.screenBounds);
				
				// if group differs from previous group, use moveTo()
				var newGroup:Number = plotter.group.getValueFromKey(key, Number);
				if (ObjectUtil.numericCompare(group, newGroup) != 0)
					handlePoint = graphics.moveTo;
				group = newGroup;
				
				if (isFinite(point.x) && isFinite(point.y))
				{
					handlePoint(point.x, point.y);
					handlePoint = graphics.lineTo;
				}
				else
					handlePoint = graphics.moveTo;
			}
		}
		catch (e:Error)
		{
			reportError(e);
		}
		
		task.buffer.draw(shape);
		
		return 1;
	}
}