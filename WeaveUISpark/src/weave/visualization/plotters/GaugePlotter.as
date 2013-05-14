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
	import flash.geom.Point;
	
	import weave.api.registerLinkableChild;
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	import weave.api.ui.IPlotTask;
	import weave.compiler.StandardLib;
	import weave.data.BinningDefinitions.DynamicBinningDefinition;
	import weave.data.BinningDefinitions.SimpleBinningDefinition;
	import weave.primitives.ColorRamp;
	import weave.utils.PlotUtils;
	import weave.utils.RadialAxis;

	/**
	 * This is the plotter for the semi-circular Gauge tool.
	 */
	public class GaugePlotter extends MeterPlotter
	{
		
		//the radius of the Gauge (from 0 to 1)
		//TODO make this part of the session state
		private const outerRadius:Number = 0.8;
		
		//the radius of the Gauge (from 0 to 1)
		//TODO make this part of the session state
		private const innerRadius:Number = 0.3;
		
		//the radius at which the tick mark labels are drawn
		//TODO make this part of the session state
		private const tickMarkLabelsRadius:Number = outerRadius+0.08;

		//the angle offset determining the size of the gauge wedge.
		//Range is 0 to PI/2. 0 means full semicircle, PI/2 means 1 pixel wide vertical wedge.
		//TODO make this part of the session state
		private const theta:Number = Math.PI/4;
		
		//the thickness and color of the outer line
		//TODO make this part of the session state
		private const outlineThickness:Number = 2;
		private const outlineColor:Number = 0x000000;
		
		//the thickness and color of the outer line
		//TODO make this part of the session state
		private const needleThickness:Number = 2;
		private const needleColor:Number = 0x000000;
		
		//wrapper for a SimpleBinningDefinition, which creates equally spaced bins
		public const binningDefinition:DynamicBinningDefinition = registerLinkableChild(this, new DynamicBinningDefinition(true));
		
		//the approximate desired number of tick marks
		//TODO make this part of the session state
		public const numberOfTickMarks:Number = 10;
		
		//the color ramp mapping bins to colors
		public const colorRamp:ColorRamp = registerLinkableChild(this, new ColorRamp(ColorRamp.getColorRampXMLByName("Traffic Light")));
		
		// reusable point objects
		private const p1:Point = new Point(), p2:Point = new Point();
		
		// the radial axis of the gauge
		private const axis:RadialAxis = new RadialAxis();
		
		/**
		 * Creates a new gauge plotter with default settings
		 */
		public function GaugePlotter()
		{
			//initializes the binning definition which defines a number of evenly spaced bins
			binningDefinition.requestLocalObject(SimpleBinningDefinition, false);
			(binningDefinition.internalObject as SimpleBinningDefinition).numberOfBins.value = 3;
			
			meterColumn.addImmediateCallback(this, updateAxis);
			binningDefinition.generateBinClassifiersForColumn(meterColumn);
			registerLinkableChild(this, binningDefinition.asyncResultCallbacks);
		}
		
		/**
		 * Updates the internal axis representation with the latest min, max, and 
		 * numberOfTickMarks. This should be called whenever any one of those changes.
		 */ 
		private function updateAxis():void
		{
			var max:Number = meterColumnStats.getMax();
			var min:Number = meterColumnStats.getMin();
			axis.setParams(min,max,numberOfTickMarks);
		}
		
		private function getMeterValue(recordKeys:Array):Number
		{
			var n:Number = recordKeys.length;
			if(n == 1)
				return meterColumn.getValueFromKey(recordKeys[i] as IQualifiedKey, Number)
			else{
				//compute the meter value by averaging record values
				var meterValueSum:Number = 0;
				for (var i:int = 0; i < n; i++)//TODO handle missing values
					meterValueSum += meterColumn.getValueFromKey(recordKeys[i] as IQualifiedKey, Number);
				return meterValueSum / n;
			}
		}
		
		override public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			if (task.recordKeys.length > 0)
			{
				//project center point
				p1.x = p1.y = 0;
				task.dataBounds.projectPointTo(p1, task.screenBounds);
				
				//project tip point (angle driven by data value)
				var meterValue:Number = getMeterValue(task.recordKeys);
				var meterValueMax:Number = meterColumnStats.getMax();
				var meterValueMin:Number = meterColumnStats.getMin();
				var norm:Number = StandardLib.normalize(meterValue, meterValueMin, meterValueMax);
	
				//compute the angle and project to screen coordinates
				var angle:Number = theta+(1-norm)*(Math.PI-2*theta)
				p2.x = Math.cos(angle)*outerRadius;
				p2.y = Math.sin(angle)*outerRadius;
				task.dataBounds.projectPointTo(p2, task.screenBounds);
				
				//draw the needle line (from center to tip)
				var g:Graphics = tempShape.graphics;
				g.clear();
				g.lineStyle(needleThickness,needleColor,1.0);
				g.moveTo(p1.x, p1.y+outerRadius);
				g.lineTo(p2.x, p2.y);
				//flush the graphics buffer
				task.buffer.draw(tempShape);
			}
			return 1;
		}
		
		/**
		 * This function draws the background graphics for this plotter, if applicable.
		 * An example background would be the origin lines of an axis.
		 * @param dataBounds The data coordinates that correspond to the given screenBounds.
		 * @param screenBounds The coordinates on the given sprite that correspond to the given dataBounds.
		 * @param destination The sprite to draw the graphics onto.
		 */
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			//clear the graphics
			var g:Graphics = tempShape.graphics;
			g.clear();
			
			//fill the colored sectors
			fillSectors(dataBounds, screenBounds, g);
			
			//draw the meter outline
			drawMeterOutline(dataBounds, screenBounds, g);

			//TODO incorporate the bin names, use as labels
			//call getNames(),getObjects() on bins
			
			axis.draw(outerRadius,theta,tickMarkLabelsRadius,dataBounds, screenBounds,g,destination);
			
			//flush the graphics buffer
			destination.draw(tempShape);
		}
		
		private function fillSectors(dataBounds:IBounds2D, screenBounds:IBounds2D,g:Graphics):void
		{
			var binNames:Array = binningDefinition.getBinNames();
			var numSectors:Number = binNames.length;
			var sectorSize:Number = (Math.PI-2*theta)/numSectors;
			for(var i:Number = 0;i<numSectors;i++){
				var color:uint = colorRamp.getColorFromNorm(i/(numSectors-1));
				PlotUtils.fillSector(innerRadius,outerRadius,theta+i*sectorSize,theta+(i+1)*sectorSize,color,dataBounds, screenBounds, g);
			}
		}
		
		private function drawMeterOutline(dataBounds:IBounds2D, screenBounds:IBounds2D,g:Graphics):void
		{
			g.lineStyle(outlineThickness,outlineColor,1.0);
			var minAngle:Number = theta;
			var maxAngle:Number = Math.PI-theta;
			PlotUtils.drawArc(outerRadius,minAngle,maxAngle,dataBounds, screenBounds, g);
			PlotUtils.drawArc(innerRadius,minAngle,maxAngle,dataBounds, screenBounds, g);
			PlotUtils.drawRadialLine(innerRadius,outerRadius,minAngle,dataBounds, screenBounds, g);
			PlotUtils.drawRadialLine(innerRadius,outerRadius,maxAngle,dataBounds, screenBounds, g);
		}
		
		/**
		 * This function returns a Bounds2D object set to the data bounds associated with the background.
		 * @param outputDataBounds A Bounds2D object to store the result in.
		 * @return A Bounds2D object specifying the background data bounds.
		 */
		override public function getBackgroundDataBounds(output:IBounds2D):void
		{
			//TODO move these hard coded bounds to sessioned variables and make UI for editing them
			output.setBounds(-1, -.3, 1, 1);
		}
		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey, output:Array):void
		{
			initBoundsArray(output);
			(output[0] as IBounds2D).setBounds(-1, -.3, 1, 1);
		}
	}
}


