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
	import flash.geom.Point;
	
	import mx.utils.ObjectUtil;
	
	import weave.api.primitives.IBounds2D;
	import weave.primitives.Bounds2D;

	/**
	 * This is a collection of static methods used for common computational geometry
	 * problems involving LineSegment, LineRay, Bounds2D, and other objects.
	 *
	 * @author adufilie 
	 * @author kmonico
	 */
	public class ComputationalGeometryUtils
	{

		/**
		 * This function will determine whether the two lines intersect. An intersection is defined
		 * if the line segments cross at one point--if they are parallel or coincidental, the intersection
		 * is defined to be false. 
		 * 
		 * @param x1 X coordinate of A in AB.
		 * @param y1 Y coordinate of A in AB.
		 * @param x2 X coordinate of B in AB.
		 * @param y2 Y coordinate of B in AB.
		 * @param x3 X coordinate of E in EF.
		 * @param y3 Y coordinate of E in EF. 
		 * @param x4 X coordinate of F in EF.
		 * @param y4 Y coordinate of F in EF.
		 * @return A boolean indicating true if the lines intersect, and false otherwise.
		 */
		public static function lineIntersectsLine(x1:Number, y1:Number, x2:Number, y2:Number, x3:Number, y3:Number, x4:Number, y4:Number, output:Point = null, ABasSeg:Boolean=true, EFasSeg:Boolean=true):Point
		{
			// we have two lines
			// line1: P1 = line1Begin + s * (line1End - line1Begin) 
			// line2: P2 = line2Begin + t * (line2End - line2Begin)
			// If we let P1 = P2, a point on both lines, we get these two equations
			// x1 + s * (x2 - x1) = x3 + t * (x4 - x3)
			// y1 + s * (y2 - y1) = y3 + t * (y4 - y3)
			// ... where (x1, y1) and (x2, y2) are the points for line1, and similarly for line2
			//
			// We can rearrange these to get this system
			// x3 - x1 = s * (x2 - x1) - t * (x4 - x3)
			// y3 - y1 = s * (y2 - y1) - t * (y4 - y3)
			// or equivalently,
			// | (x3 - x1) |   | (x2 - x1)    (x4 - x3) | | s |
			// |           | = |                        | |   |
			// | (y3 - y1) |   | (y2 - y1)    (y4 - y3) | | t |
			// which is a 2x1 matrix = (2x2 matrix) * (2x1 matrix)
			// we can invert the 2x2 matrix, multiply both sides by that, and get
			// the values of s and t
			var y1minusy3:Number = y1 - y3;
			var x1minusx3:Number = x1 - x3;
			var y4minusy3:Number = y4 - y3;
			var x4minusx3:Number = x4 - x3;
			var y2minusy1:Number = y2 - y1;
			var x2minusx1:Number = x2 - x1;
			
			var denominator:Number = (y4minusy3) * (x2minusx1) - (x4minusx3) * (y2minusy1); // the determinant of the 2x2 matrix
			
			// if this is 0, the lines are parallel (no inverted matrix => no solution)
			if (Math.abs(denominator) <= Number.MIN_VALUE) 
			{
				return null; 
			}
			
			var s:Number = ((x4minusx3) * (y1minusy3) - (y4minusy3) * (x1minusx3)) / denominator;
			var t:Number = ((x2minusx1) * (y1minusy3) - (y2minusy1) * (x1minusx3)) / denominator;
				
			// if AB or EF is a line segment, ensure the intersection is on the line
			if ( (ABasSeg && (s < 0 || s > 1)) || (EFasSeg && (t < 0 || t > 1)) )
			{
				return null;
			}

			
			// store output point
			if (output)
			{
				output.x = x1 + s * (x2minusx1);
				output.y = y1 + s * (y2minusy1);
			}

			return output;
		}
			
		// reusable objects
		private static const _tempMinPoint:Point = new Point();
		private static const _tempMaxPoint:Point = new Point();		
		private static const _tempBounds:IBounds2D = new Bounds2D();
		private static const _tempVectorPoint:Point = new Point();
		
		/**
		 * lineIntersectsLine
		 * This function computes the intersection point of two lines.
		 * Each line can individually be treated as a segment or an infinite line.
		 * It is much faster to compute the intersection of infinite lines.
		 * The algorithm was taken from the following blogs and optimized for speed:
		 * http://keith-hair.net/blog/2008/08/04/find-intersection-point-of-two-lines-in-as3/
		 * http://blog.controul.com/2009/05/line-segment-intersection/
		 * @param Ax X coordinate of A in line AB
		 * @param Ay Y coordinate of A in line AB
		 * @param Bx X coordinate of B in line AB
		 * @param By Y coordinate of B in line AB
		 * @param Ex X coordinate of E in line EF
		 * @param Ey Y coordinate of E in line EF
		 * @param Fx X coordinate of F in line EF
		 * @param Fy Y coordinate of F in line EF
		 * @param outputIntersectionPoint A Point object to store the intersection coordinates in
		 * @param ABasSeg true if you want to treat line AB as a segment, false for an infinite line
		 * @param EFasSeg true if you want to treat line EF as a segment, false for an infinite line
		 * @return Either outputIntersectionPoint or a new Point containing the intersection coordinates
		 */
		public static function lineIntersectsLine2(Ax:Number, Ay:Number, Bx:Number, By:Number, Ex:Number, Ey:Number, Fx:Number, Fy:Number, outputIntersectionPoint:Point=null, ABasSeg:Boolean=true, EFasSeg:Boolean=true):Point
		{
			var dy1:Number = By-Ay;
			var dx1:Number = Ax-Bx;
			var dy2:Number = Fy-Ey;
			var dx2:Number = Ex-Fx;
			var denom:Number = dy1*dx2 - dy2*dx1;
			
			if (denom == 0)
			{
				return null;
			}
			var c1:Number = Bx*Ay - Ax*By;
			var c2:Number = Fx*Ey - Ex*Fy;
			
			// get the intersection point of the two lines
			var ipx:Number, ipy:Number;
			ipx = (dx1*c2 - dx2*c1) / denom;
			ipy = (dy2*c1 - dy1*c2) / denom;

			// fix rounding errors
			if (dy1 == 0)
			{
				ipy = Ay;
			}
			else if (dy2 == 0)
			{
				ipy = Ey;
			}
			if (dx1 == 0)
			{
				ipx = Ax;
			}
			else if (dx2 == 0)
			{
				ipx = Ex;
			}

			// if the lines are segments, return null if the intersection falls outside their bounds.
			if (ABasSeg)
			{
				if ( (Ax < Bx) ? (ipx < Ax || Bx < ipx) : (ipx < Bx || Ax < ipx) )
				{
					return null;
				}
				if ( (Ay < By) ? (ipy < Ay || By < ipy) : (ipy < By || Ay < ipy) )
				{
					return null;
				}
			}
			if (EFasSeg)
			{
				if ( (Ex < Fx) ? (ipx < Ex || Fx < ipx) : (ipx < Fx || Ex < ipx) )
				{
					return null;
				}
				if ( (Ey < Fy) ? (ipy < Ey || Fy < ipy) : (ipy < Fy || Ey < ipy) )
				{
					return null;
				}
			}
			
			if (outputIntersectionPoint == null)
				outputIntersectionPoint = new Point();
			outputIntersectionPoint.x = ipx;
			outputIntersectionPoint.y = ipy;
			return outputIntersectionPoint;
		}

		/**
		 * polygonOverlapsPolygon
		 * Optimized for situations where polygon2 is contained in polygon1.
		 * @param polygon1 An array of objects representing vertices, each having x and y properties.
		 * @param polygon2 An array of objects representing vertices, each having x and y properties.
		 * @return true if the polygons overlap
		 */
		public static function polygonOverlapsPolygon(polygon1:Object, polygon2:Object):Boolean
		{
			if (polygon1.length == 0 || polygon2.length == 0)
				return false;
			var a:Object = polygon2[0];
			var b:Object;
			for (var i2:int = polygon2.length - 1; i2 >= 0; i2--)
			{
				b = a;
				a = polygon2[i2];
				if (polygonIntersectsLine(polygon1, a.x, a.y, b.x, b.y))
					return true;
			}
			// if no lines intersect, check for point containment
			if (polygonOverlapsPoint(polygon1, a.x, a.y))
				return true;
			a = polygon1[0];
			return polygonOverlapsPoint(polygon2, a.x, a.y);
		}
		
		/**
		 * polygonIntersectsLine
		 * @param polygon An array of objects representing vertices, each having x and y properties.
		 * @param Ax X coordinate of A in line AB
		 * @param Ay Y coordinate of A in line AB
		 * @param Bx X coordinate of B in line AB
		 * @param By Y coordinate of B in line AB
		 * @param asSegment true if you want to treat line AB as a segment, false for an infinite line
		 * @return true if the line intersects the polygon
		 */
		public static function polygonIntersectsLine(polygon:Object, Ax:Number, Ay:Number, Bx:Number, By:Number, asSegment:Boolean=true):Boolean
		{
			if (polygon.length == 0)
				return false;
			var c:Object = polygon[0];
			var d:Object;
			for (var i:int = polygon.length - 1; i >= 0; i--)
			{
				d = c;
				c = polygon[i];
				if (lineIntersectsLine(Ax, Ay, Bx, By, c.x, c.y, d.x, d.y, tempPoint, asSegment) != null)
					return true;
			}
			
			return false;
		}

		/**
		 * @param polygon An array of objects representing vertices, each having x and y properties.
		 * @param Ax X coordinate of A in line AB
		 * @param Ay Y coordinate of A in line AB
		 * @param Bx X coordinate of B in line AB
		 * @param By Y coordinate of B in line AB
		 * @param asSegment true if you want to treat line AB as a segment, false for an infinite line
		 * @return true if the line overlaps the polygon.
		 */
		public static function polygonOverlapsLine(polygon:Object, Ax:Number, Ay:Number, Bx:Number, By:Number, asSegment:Boolean=true):Boolean
		{
			if (polygonIntersectsLine(polygon, Ax, Ay, Bx, By, asSegment) == true)
				return true;
			
			if (polygonOverlapsPoint(polygon, Ax, Ay) == true)
				return true;
			
			if (polygonOverlapsPoint(polygon, Bx, By) == true)
				return true;
			
			return false;
		}
		
		/**
		 * polygonOverlapsPoint
		 * @param polygon An array of objects representing vertices, each having x and y properties.
		 * @param x The x coordinate of the point to test for containment.
		 * @param y The y coordinate of the point to test for containment.
		 * @return true if the polygon contains the point.
		 */
		public static function polygonOverlapsPoint(polygon:Object, x:Number, y:Number):Boolean
		{
			if (polygon.length == 0)
				return false;
			var riCount:int = 0; // number of ray intersections
			var riIndex:int; // ray intersection index
			var segSide:int;
			var Ax:Number = polygon[0].x;
			var Ay:Number = polygon[0].y;
			var Bx:Number;
			var By:Number;
			// loop through the segments of the polygon
			for (var pointIndex:int = polygon.length - 1; pointIndex >= 0; pointIndex--)
			{
				Bx = Ax;
				By = Ay;
				Ax = polygon[pointIndex].x;
				Ay = polygon[pointIndex].y;

				// get intersection of segment AB and a horizontal ray passing through (x,y), then check if the intersection is >= x
				if (Ay != By && lineIntersectsLine(x, y, x + 1, y, Ax, Ay, Bx, By, tempPoint, false) != null && tempPoint.x >= x)
				{
					// if the intersection is on an endpoint of segment AB, determine if the segment is above or below the ray
					if (tempPoint.y == Ay && tempPoint.x == Ax)
						segSide = ObjectUtil.numericCompare(tempPoint.y, By);
					else if (tempPoint.y == By && tempPoint.x == Bx)
						segSide = ObjectUtil.numericCompare(tempPoint.y, Ay);
					else
						segSide = 0;
					// if intersection is an endpoint of segment AB, check if this intersection has already been recorded
					if (segSide != 0)
						for (riIndex = 0; riIndex < riCount; riIndex++) // loop through previously recorded intersections
							if (riXcoords[riIndex] == tempPoint.x && riYcoords[riIndex] == tempPoint.y) // if coords match...
								if (riSegSide[riIndex] == -segSide) // and previous segment was on the opposite side of the ray...
									break; // don't count this duplicate intersection point
					// if the above loop was not ended with break, or the intersection was not an endpoint of segment AB...
					if (riIndex == riCount || segSide == 0)
					{
						// record the intersection
						riXcoords[riCount] = tempPoint.x;
						riYcoords[riCount] = tempPoint.y;
						riSegSide[riCount] = segSide;
						riCount++;
					}
				}
			}
			// an odd number of intersections means the point is inside the polygon
			return (riCount % 2 == 1);
		}

		/**
		 * Compute the distance from the line passing through A and B to the point C.
		 * This function assumes the normal from point C to AB lies on AB.
		 * 
		 * @param ax The X coordinate of point A
		 * @param ay The Y coordinate of point A
		 * @param bx The X coordinate of point B
		 * @param by The Y coordinate of point B
		 * @param cx The X coordinate of point C
		 * @param cy The Y coordinate of point C
		 * @return The distance from the line passing through A and B to the point C
		 */
		public static function getDistanceFromLine(ax:Number, ay:Number, bx:Number, by:Number, cx:Number, cy:Number):Number
		{
			var dx:Number = bx-ax;
			var dy:Number = by-ay;
			var dd:Number = Math.sqrt(dx*dx+dy*dy);
			return Math.abs( ((cx - ax)*dy - (cy - ay)*dx)/dd );
		}

		/**
		 * Compute the unscaled distance from the line to the point. This function should only be used for
		 * comparing unscaled distances of other point to line segment distances.
		 * This function assumes the normal from point C to AB lies on AB.
		 * 
		 * @param ax The X coordinate of point A
		 * @param ay The Y coordinate of point A
		 * @param bx The X coordinate of point B
		 * @param by The Y coordinate of point B
		 * @param cx The X coordinate of point C
		 * @param cy The Y coordinate of point C
		 * @return The distance from the line passing through A and B to the point C
		 */
		public static function getUnscaledDistanceFromLine(ax:Number, ay:Number, bx:Number, by:Number, cx:Number, cy:Number):Number
		{
			var dx:Number = bx-ax;
			var dy:Number = by-ay;
			var dd:Number = dx*dx + dy*dy;
			return Math.abs( ((cx - ax)*dy - (cy - ay)*dx) / dd );
		}
		
		/**
		 * @param ax The X coordinate of point A
		 * @param ay The Y coordinate of point A
		 * @param bx The X coordinate of point B
		 * @param by The Y coordinate of point B
		 * @return The distance from point A to point B
		 */
		public static function getDistanceFromPointSq(ax:Number, ay:Number, bx:Number, by:Number):Number
		{
			var dx:Number = bx - ax;
			var dy:Number = by - ay;
			return dx * dx + dy * dy;
		}
		
		// reusable temporary objects to reduce GC activity:
		private static const tempPoint:Point = new Point();
		private static const riXcoords:Array = []; // ray intersection coords
		private static const riYcoords:Array = []; // ray intersection coords
		private static const riSegSide:Array = []; // each value is -1 or 1 depending on if segment was completely above or below the ray, 0 if neither	
	}
}