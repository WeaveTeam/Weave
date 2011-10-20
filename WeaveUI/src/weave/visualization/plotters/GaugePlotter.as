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
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IQualifiedKey;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.core.SessionManager;
	import weave.data.BinClassifiers.BinClassifierCollection;
	import weave.data.BinningDefinitions.DynamicBinningDefinition;
	import weave.data.BinningDefinitions.SimpleBinningDefinition;
	import weave.primitives.ColorRamp;
	import weave.utils.PlotUtils;
	import weave.utils.RadialAxis;
	


	/**
	 * This is the plotter for the semi-circular Gauge tool.
	 */
	public class GaugePlotter extends MeterPlotter{
		
		//the radius of the Gauge (from 0 to 1)
		//TODO make this part of the session state
		//TODO create UI for editing this
		private const outerRadius:Number = 0.8;
		
		//the radius of the Gauge (from 0 to 1)
		//TODO make this part of the session state
		//TODO create UI for editing this
		private const innerRadius:Number = 0.3;
		
		//the radius at which the tick mark labels are drawn
		//TODO make this part of the session state
		//TODO create UI for editing this
		private const tickMarkLabelsRadius:Number = outerRadius+0.08;

		//the angle offset determining the size of the gauge wedge.
		//Range is 0 to PI/2. 0 means full semicircle, PI/2 means 1 pixel wide vertical wedge.
		//TODO make this part of the session state
		//TODO create UI for editing this 
		private const theta:Number = Math.PI/4;
		
		//the thickness and color of the outer line
		//TODO make this part of the session state
		//TODO create UI for editing this
		private const outlineThickness:Number = 2;
		private const outlineColor:Number = 0x000000;
		
		//the thickness and color of the outer line
		//TODO make this part of the session state
		//TODO create UI for editing this
		private const needleThickness:Number = 2;
		private const needleColor:Number = 0x000000;
		
		//wrapper for a SimpleBinningDefinition, which creates equally spaced bins
		//TODO create UI for editing the number of bins
		public const binningDefinition:DynamicBinningDefinition = newLinkableChild(this, DynamicBinningDefinition, updateBins);
		
		//the approximate desired number of tick marks
		//TODO make this part of the session state
		//TODO create UI for editing this
		public const numberOfTickMarks:Number = 10;
		
		//reusable object for storing the output (the actual bins) of binningDefinition 
		private const bins:BinClassifierCollection = newDisposableChild(this, BinClassifierCollection);
		
		//the color ramp mapping bins to colors
		public const colorRamp:ColorRamp = registerLinkableChild(this, new ColorRamp(ColorRamp.getColorRampXMLByName("Traffic Light")));
		
		// reusable point objects
		private const p1:Point = new Point(), p2:Point = new Point();
		
		// the radial axis of the gauge
		private const axis:RadialAxis = new RadialAxis();
		
		/**
		 * Creates a new gauge plotter with default settings
		 */
		public function GaugePlotter(){
			//initializes the binning definition which defines a number of evenly spaced bins
			binningDefinition.requestLocalObject(SimpleBinningDefinition, false);
			(binningDefinition.internalObject as SimpleBinningDefinition).numberOfBins.value = 3;
			
			//update bins when column changes
			meterColumn.addImmediateCallback(this, updateBins);
			meterColumn.addImmediateCallback(this, updateAxis);
			
			for each (var child:ILinkableObject in [Weave.properties.axisFontSize, Weave.properties.axisFontColor])
				registerLinkableChild(this, child);
		}
		
		/**
		 * Updates the contents of the 'bins' object with the latest bins computed 
		 * from 'binningDefinition'. This should be called when the column changes, 
		 * or when the number of bins changes.
		 */
		private function updateBins():void{
			//writes up-to-date bins into "bins"
			binningDefinition.getBinClassifiersForColumn(meterColumn,bins);
		}
		
		/**
		 * Updates the internal axis representation with the latest min, max, and 
		 * numberOfTickMarks. This should be called whenever any one of those changes.
		 */ 
		private function updateAxis():void{
			var max:Number = WeaveAPI.StatisticsCache.getMax(meterColumn);
			var min:Number = WeaveAPI.StatisticsCache.getMin(meterColumn);
			axis.setParams(min,max,numberOfTickMarks);
		}
		
		private function getMeterValue(recordKeys:Array):Number{
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
		
		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			if(meterValueExists(recordKeys)){
				//clear the graphics
				var g:Graphics = tempShape.graphics;
				g.clear();
				
				//draw the needle
				drawNeedle(recordKeys,dataBounds, screenBounds,g);
				
				//flush the graphics buffer
				destination.draw(tempShape);
			}
		}
		
		private function drawNeedle(recordKeys:Array,dataBounds:IBounds2D, screenBounds:IBounds2D,g:Graphics):void{
			//project center point
			p1.x = p1.y = 0;
			dataBounds.projectPointTo(p1, screenBounds);
			
			//project tip point (angle driven by data value)
			//TODO: use a normalization abstraction here
			var meterValue:Number = getMeterValue(recordKeys);
			var meterValueMax:Number = WeaveAPI.StatisticsCache.getMax(meterColumn);
			var meterValueMin:Number = WeaveAPI.StatisticsCache.getMin(meterColumn);
			var norm:Number = (meterValue - meterValueMin)/(meterValueMax - meterValueMin);

			//compute the angle and project to screen coordinates
			var angle:Number = theta+(1-norm)*(Math.PI-2*theta)
			p2.x = Math.cos(angle)*outerRadius;
			p2.y = Math.sin(angle)*outerRadius;
			dataBounds.projectPointTo(p2, screenBounds);
			
			//draw the needle line (from center to tip)
			g.lineStyle(needleThickness,needleColor,1.0);
			g.moveTo(p1.x, p1.y+outerRadius);
			g.lineTo(p2.x, p2.y);
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
		
		private function fillSectors(dataBounds:IBounds2D, screenBounds:IBounds2D,g:Graphics):void{
			var binObjects:Array = bins.getObjects();
			var numSectors:Number = binObjects.length;
			var sectorSize:Number = (Math.PI-2*theta)/numSectors;
			for(var i:Number = 0;i<numSectors;i++){
				var color:uint = colorRamp.getColorFromNorm(i/(numSectors-1));
				PlotUtils.fillSector(innerRadius,outerRadius,theta+i*sectorSize,theta+(i+1)*sectorSize,color,dataBounds, screenBounds, g);
			}
		}
		
		private function drawMeterOutline(dataBounds:IBounds2D, screenBounds:IBounds2D,g:Graphics):void{
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
		override public function getBackgroundDataBounds():IBounds2D
		{
			//TODO move these hard coded bounds to sessioned variables and make UI for editing them
			return getReusableBounds(-1, -.3, 1, 1);
		}
		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			return [getReusableBounds(-1, -.3, 1, 1)];
		}
	}
}


