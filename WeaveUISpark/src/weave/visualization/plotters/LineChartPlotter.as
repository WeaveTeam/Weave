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
	import flash.display.Graphics;
	import flash.geom.Point;
	
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.reportError;
	import weave.api.ui.IPlotTask;
	import weave.api.ui.IPlotter;
	import weave.api.ui.ISelectableAttributes;
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
		
		public const dataX:DynamicColumn = newSpatialProperty(DynamicColumn);
		public const dataY:DynamicColumn = newSpatialProperty(DynamicColumn);
		public const group:DynamicColumn = newLinkableChild(this, DynamicColumn);
 		public const order:DynamicColumn = newLinkableChild(this, DynamicColumn);
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

import flash.display.BitmapData;
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
		this.renderer = new AsyncLineRenderer();
		
		if ((task as PlotTask).taskType != PlotTask.TASK_TYPE_SUBSET)
			this.keySet = newDisposableChild(plotter, KeySet);
	}
	
	public var renderer:AsyncLineRenderer;
	public var plotter:LineChartPlotter;
	public var task:IPlotTask;
	public var unfilteredKeySet:IKeySet;
	public var keys:Array;
	public var keyIndex:Number;
	public var keySet:KeySet;
	public var group:Number;
	
	private static const tempPoint:Point = new Point();
	
	public function iterate():Number
	{
		if (task.iteration == 0)
		{
			renderer.reset();
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
			for (; keyIndex < keys.length; keyIndex++)
			{
				if (getTimer() > task.iterationStopTime)
				{
					renderer.flush(task.buffer);
					return keyIndex / keys.length;
				}
				
				var key:IQualifiedKey = keys[keyIndex] as IQualifiedKey;
				
				if (keySet ? keySet.containsKey(key) : plotter.filteredKeySet.containsKey(key))
				{
					tempPoint.x = plotter.dataX.getValueFromKey(key, Number);
					tempPoint.y = plotter.dataY.getValueFromKey(key, Number);
					
					if (isFinite(tempPoint.x) && isFinite(tempPoint.y))
						task.dataBounds.projectPointTo(tempPoint, task.screenBounds);
				}
				else
				{
					tempPoint.x = tempPoint.y = NaN;
				}
				
				// if group differs from previous group, use moveTo()
				var newGroup:Number = plotter.group.getValueFromKey(key, Number);
				if (ObjectUtil.numericCompare(group, newGroup) != 0)
					renderer.newLine();
				group = newGroup;
				
				renderer.addPoint(tempPoint.x, tempPoint.y, plotter.lineStyle.getLineStyleParams(key));
			}
		}
		catch (e:Error)
		{
			reportError(e);
		}
		
		renderer.flush(task.buffer);
		return 1;
	}
}

internal class AsyncLineRenderer
{
	public function AsyncLineRenderer()
	{
		shape = new Shape();
		graphics = shape.graphics;
	}
	
	private var shape:Shape;
	private var graphics:Graphics;
	private var handlePoint:Function;
	private var prevX:Number;
	private var prevY:Number;
	private var continueLine:Boolean;
	private var prevLineStyle:Array;
	
	/**
	 * Call this at the beginning of the async task
	 */
	public function reset():void
	{
		graphics.clear();
		newLine();
	}
	
	/**
	 * Call this before starting a new line
	 */
	public function newLine():void
	{
		continueLine = false;
	}
	
	/**
	 * Call this for each coordinate in the line, whether the coordinates are defined or not.
	 */
	public function addPoint(x:Number, y:Number, lineStyleParams:Array):void
	{
		var isDefined:Boolean = isFinite(x) && isFinite(y);
		
		if (isDefined && continueLine)
		{
			var midX:Number = (prevX + x) / 2;
			var midY:Number = (prevY + y) / 2;
			
			graphics.lineStyle.apply(graphics, prevLineStyle);
			graphics.lineTo(midX, midY);
			graphics.lineStyle.apply(graphics, lineStyleParams);
			graphics.lineTo(x, y);
		}
		else
		{
			graphics.moveTo(x, y);
		}
		
		prevX = x;
		prevY = y;
		continueLine = isDefined;
		prevLineStyle = lineStyleParams;
	}
	
	/**
	 * Call this to flush the graphics to a BitmapData buffer.
	 */
	public function flush(buffer:BitmapData):void
	{
		buffer.draw(shape);
		graphics.clear();
		if (continueLine)
			graphics.moveTo(prevX, prevY);
	}
}
