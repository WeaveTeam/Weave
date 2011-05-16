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

package weave.utils
{
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.geom.Point;
	import flash.text.TextFormatAlign;
	
	import mx.formatters.NumberFormatter;
	
	import weave.api.primitives.IBounds2D;
	import weave.compiler.MathLib;

	/**
	 * A class for dealing with the radial axis problem.   
	 * @author curran
	 */
	public class RadialAxis
	{
		/**
		 * The minimum value of the column.
		 */
		private var min:Number;
		/**
		 * The maximum value of the column.
		 */
 		private var max:Number;
 		/**
		 * The approximate number of tick marks.
		 */
		private var n:Number;
		
		/**
		 * The length of major tick marks
		 */
		//TODO make this a sessioned variable
		//TODO add UI for editing this
		private var majorTickMarkLength:Number = 0.05;

		/**
		 * The length of minor tick marks
		 */
		//TODO make this a sessioned variable
		//TODO add UI for editing this
		private var minorTickMarkLength:Number = 0.2;
		
		/**
		 * The size of the tick mark label
		 */
		//TODO make this a sessioned variable
		//TODO add UI for editing this
		private var tickMarkLabelSize:Number = 12;
		
		private var isInitialized:Boolean = false;
		
		private var majorInterval:Number,firstMajorTickMarkValue:Number;
		
		//reusable object, used for projection to screen coordinates
		private const p:Point = new Point();
		
		// reusable object containing text style information for tick mark labels
		private const tickMarkLabel:BitmapText = new BitmapText(); 
		
		// reusable object for formatting tick mark label text
		private const formatter:NumberFormatter = new NumberFormatter();
		
		
		public function RadialAxis(){
			
			//set the font and style for the tick mark label text
			tickMarkLabel.textFormat.size = tickMarkLabelSize;
			tickMarkLabel.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_CENTER;
			tickMarkLabel.textFormat.align = TextFormatAlign.CENTER;
			tickMarkLabel.verticalAlign = BitmapText.VERTICAL_ALIGN_CENTER;
			tickMarkLabel.textFormat.color = 0x000000;
			tickMarkLabel.angle = 0;
			tickMarkLabel.width = 80;
		}
		
		/**
		 * Initializes the data-specific parameters:
		 * min - The minimum value of the column.
		 * max - The maximum value of the column.
		 * n - The approximate number of tick marks desired.
		 */
		public function setParams(min:Number,max:Number,n:Number):void{
			this.min = min;
			this.max = max;
			this.n = n;
			majorInterval = TickMarkUtils.getNiceInterval(min, max, n);
			firstMajorTickMarkValue = TickMarkUtils.getFirstTickValue(min,majorInterval);
			isInitialized = true;
		}
		
		/**
		 * Draws the radial axis.
		 * r - the radius of the axis
		 * theta - the angle offset defining the wedge size (begin angle = theta, end angle = PI - theta)
		 */
		public function draw(r:Number,theta:Number,labelsRadius:Number,dataBounds:IBounds2D, screenBounds:IBounds2D,g:Graphics,destination:BitmapData):void{
			if(isInitialized){
				var minAngle:Number = theta;
				var maxAngle:Number = Math.PI-theta;
			
				var norm:Number,angle:Number,sin:Number,cos:Number;
				
				var r1:Number = r-majorTickMarkLength/2;
				var r2:Number = r+majorTickMarkLength/2;
				
//				var value:Number = firstMajorTickMarkValue;
				for (var value:Number = firstMajorTickMarkValue; value < max; value += majorInterval) {
//				for (var i:Number = 0; value < max; i++) {
//					value = firstMajorTickMarkValue + i*majorInterval;
					norm = (value - min) / (max - min);
					angle = (1 - norm) * (maxAngle - minAngle) + minAngle;
					
					sin = Math.sin(angle);
					cos = Math.cos(angle);
					
					p.x = cos*r1;
					p.y = sin*r1;
					dataBounds.projectPointTo(p, screenBounds);
					g.moveTo(p.x,p.y);
					
					p.x = cos*r2;
					p.y = sin*r2;
					dataBounds.projectPointTo(p, screenBounds);
					g.lineTo(p.x,p.y);
					
					p.x = cos*labelsRadius;
					p.y = sin*labelsRadius;
					dataBounds.projectPointTo(p, screenBounds);
					tickMarkLabel.text = ""+MathLib.roundSignificant(value,8);//formatter.format(value);
					tickMarkLabel.x = p.x;
					tickMarkLabel.y = p.y;
					
					tickMarkLabel.draw(destination);
					
					//a marker for testing whether text is centered properly
					//g.drawCircle(p.x,p.y,2);
					
				}
			}
		}
	}
}
