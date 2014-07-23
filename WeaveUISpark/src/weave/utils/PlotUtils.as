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
	import flash.display.Graphics;
	import flash.geom.Point;
	
	import weave.api.primitives.IBounds2D;
	import weave.primitives.Bounds2D;
	/**
	 * A utility class containing implementations of graphics functions missing from the Flex Graphics API
	 * 
	 * @author curran
	 */
	public class PlotUtils
	{
		//reusable object, used for projection to screen coordinates
		private static const p:Point = new Point();
		
		//the angle span (in radians) per line segment used to draw arcs
		private static const segmentSpan:Number = Math.PI/50;
	    /**
		 * innerRadius - the radius in data coordinates of the inner sector arc
		 * outerRadius - the radius in data coordinates of the outer sector arc
		 * beginAngle - the begin angle in radians
		 * endAngle - the end angle in radians (> beginAngle)
		 */
		public static function fillSector(innerRadius:Number,outerRadius:Number,beginAngle:Number,endAngle:Number,color:uint,dataBounds:IBounds2D, screenBounds:IBounds2D,graphics:Graphics):void{
			var angle:Number = beginAngle;
			//traverse the outer arc
			graphics.beginFill(color);
			while (true){
				if(angle > endAngle)
					angle = endAngle;
				p.x = Math.cos(angle)*outerRadius;
				p.y = Math.sin(angle)*outerRadius;
				dataBounds.projectPointTo(p, screenBounds);
				if(angle == beginAngle)
					graphics.moveTo(p.x, p.y);
				else
					graphics.lineTo(p.x, p.y);
				if(angle == endAngle)
					break;
				else
					angle += segmentSpan;
			}
			//traverse the inner arc backwards
			while (true){
				if(angle < beginAngle)
					angle = beginAngle;
				p.x = Math.cos(angle)*innerRadius;
				p.y = Math.sin(angle)*innerRadius;
				dataBounds.projectPointTo(p, screenBounds);
				graphics.lineTo(p.x, p.y);
				if(angle == beginAngle)
					break;
				else
					angle -= segmentSpan;
			}
			graphics.endFill();
		}
		/**
		 * Draws a line specified by radial coordinates:
		 * r1 - the beginning distance away from the origin
		 * r2 - the ending distance away from the origin
		 * angle - the angle at which to draw the line
		 */
		public static function drawRadialLine(r1:Number,r2:Number,angle:Number,dataBounds:IBounds2D, screenBounds:IBounds2D,g:Graphics):void{
			var cos:Number = Math.cos(angle);
			var sin:Number = Math.sin(angle);
			
			p.x = cos*r1;
			p.y = sin*r1;
			dataBounds.projectPointTo(p, screenBounds);
			g.moveTo(p.x, p.y);
			
			p.x = cos*r2;
			p.y = sin*r2;
			dataBounds.projectPointTo(p, screenBounds);
			g.lineTo(p.x, p.y);
		}
		/**
		 * radius - the radius in data coordinates of the arc
		 * beginAngle - the begin angle in radians
		 * endAngle - the end angle in radians (> beginAngle)
		 */
		public static function drawArc(radius:Number,beginAngle:Number,endAngle:Number,dataBounds:IBounds2D, screenBounds:IBounds2D,g:Graphics):void{
			var angle:Number = beginAngle;
			while (true){
				if(angle > endAngle)
					angle = endAngle;
				p.x = Math.cos(angle)*radius;
				p.y = Math.sin(angle)*radius;
				dataBounds.projectPointTo(p, screenBounds);
				if(angle == beginAngle)
					g.moveTo(p.x, p.y);
				else
					g.lineTo(p.x, p.y);
				if(angle == endAngle)
					break;
				else
					angle += segmentSpan;
			}
		}
	}
}