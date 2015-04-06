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
	
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.api.ui.IPlotTask;
	import weave.api.ui.IPlotter;
	import weave.core.LinkableFunction;
	import weave.core.LinkableNumber;
	import weave.visualization.layers.PlotTask;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	public class EquationPlotter extends AbstractPlotter
	{
		WeaveAPI.ClassRegistry.registerImplementation(IPlotter, EquationPlotter, "Equation");
		
		public const tStep:LinkableNumber = registerLinkableChild(this, new LinkableNumber(NaN));
		public const tBegin:LinkableNumber = registerLinkableChild(this, new LinkableNumber(NaN));
		public const tEnd:LinkableNumber = registerLinkableChild(this, new LinkableNumber(NaN));
		
		public const xEquation:LinkableFunction = registerLinkableChild(this, new LinkableFunction('t', true, false, ['t']));
		public const yEquation:LinkableFunction = registerLinkableChild(this, new LinkableFunction('t', true, false, ['t']));
		
		public const lineStyle:SolidLineStyle = newLinkableChild(this, SolidLineStyle);
		
		override public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			if ((task as PlotTask).taskType != PlotTask.TASK_TYPE_SUBSET)
				return 1;
			
			if (!(task.asyncState is AsyncState))
				task.asyncState = new AsyncState(this, task);
			return (task.asyncState as AsyncState).iterate();
		}
	}
}

import flash.display.Graphics;
import flash.display.Shape;
import flash.geom.Point;
import flash.utils.getTimer;

import weave.api.reportError;
import weave.api.ui.IPlotTask;
import weave.visualization.plotters.EquationPlotter;

internal class AsyncState
{
	public function AsyncState(plotter:EquationPlotter, task:IPlotTask)
	{
		this.plotter = plotter;
		this.task = task;
		this.shape = new Shape();
		this.point = new Point();
	}
	
	public var plotter:EquationPlotter;
	public var task:IPlotTask;
	public var shape:Shape;
	public var point:Point;
	public var step:Number;
	public var begin:Number;
	public var end:Number;
	public var t:Number;
	public var handlePoint:Function;
	
	public function iterate():Number
	{
		var graphics:Graphics = shape.graphics;
		if (task.iteration == 0)
		{
			step = plotter.tStep.value;
			begin = plotter.tBegin.value;
			end = plotter.tEnd.value;
			
			// calculate default step values in case parameters are unspecified
			var pixelStep:Number = 1; // default number of pixels to advance each iteration
			var xStep:Number = pixelStep * task.dataBounds.getXCoverage() / task.screenBounds.getXCoverage();
			var yStep:Number = pixelStep * task.dataBounds.getYCoverage() / task.screenBounds.getYCoverage();
			if (!isFinite(step))
			{
				if (plotter.xEquation.getSessionState() == 't')
					step = xStep;
				else if (plotter.yEquation.getSessionState() == 't')
					step = yStep;
				else
					step = Math.min(xStep, yStep);
			}
			if (!isFinite(begin))
			{
				begin = (step == yStep ? task.dataBounds.getYMin() : task.dataBounds.getXMin());
			}
			if (!isFinite(end))
			{
				end = (step == yStep ? task.dataBounds.getYMax() : task.dataBounds.getXMax());
			}
			
			// make sure step is going in the right direction.
			if (begin < end != step > 0)
				step = -step;
			
			// stop immediately if we know we will never finish.
			if (step == 0 || !isFinite(step) || !isFinite(begin) || !isFinite(end))
				return 1;
			
			handlePoint = graphics.moveTo;
			t = begin;
		}
		
		try
		{
			graphics.clear();
			graphics.moveTo(point.x, point.y);
			plotter.lineStyle.beginLineStyle(null, graphics);
			
			var stepEnd:Number = end + step;
			for (; t < stepEnd; t += step)
			{
				if (getTimer() > task.iterationStopTime)
				{
					task.buffer.draw(shape);
					return (t - begin) / (stepEnd - begin);
				}
				
				if (t > end)
					t = end;
				
				point.x = plotter.xEquation.apply(null, [t]);
				point.y = plotter.yEquation.apply(null, [t]);
				
				if (isFinite(point.x) && isFinite(point.y))
					task.dataBounds.projectPointTo(point, task.screenBounds);
				
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