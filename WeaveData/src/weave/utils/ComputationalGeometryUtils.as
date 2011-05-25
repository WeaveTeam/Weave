package weave.utils
{
	import flash.geom.Point;
	
	import weave.api.primitives.IBounds2D;
	import weave.primitives.Bounds2D;
	import weave.primitives.LineRay;
	import weave.primitives.LineSegment;

	/**
	 * This is a collection of static methods used for common computational geometry
	 * problems involving LineSegment, LineRay, Bounds2D, and other objects.
	 * 
	 * @author kmonico
	 */
	public class ComputationalGeometryUtils
	{
		/**
		 * This function will determine if a ray intersects a line. In this function,
		 * the ray is treated as all possible rays originating from the origin of the point.
		 * 
		 * @param line The LineSegment to test.
		 * @param ray The LineRay to use for the test.
		 * @return A boolean indicating true or false if the ray does intersect the line.
		 */
		public static function doesLineIntersectRay(line:LineSegment, ray:LineRay):Boolean
		{
			// We assume A is always the lower point
			var rayOrigin:Point = ray.origin; // origin of the ray
			var A:Point = line.beginPoint; // the lower point of the line segment
			var B:Point = line.endPoint; // the higher point of the line segment
			
			// visual. Picture all rays as moving to the right (which we can do since we require the point to have positive slope)
			//    . . . .           o---->
			//               \     
			//               B
			//   o---->     /
			//             /     o---->
			//            /
			// o---->    /  o---->
			//          A
			//    . . . .
			// For a ray to intersect the segment AB, we require A.y <= rayOrigin.y <= B.y
			// Then, we require rayOrigin.x to be between A.x and B.x.
			// (Note that if rayOrigin.x is less than both A.x and B.x, it clearly intersects segment).
			// Then we calculate the slope of line segment AB and the slope of line segment RA, 
			// which is the line from the ray origin to point A. If the the slop from the ray to A is 
			// greater or equal to the slope of segment AB, then the ray intersects.
			// In all other cases, the ray does not intersect.
			
			// if the ray origin is lower than the lower point or higher than the higher point
			if (rayOrigin.y < A.y || rayOrigin.y > B.y)
				return false;
			
			// if the ray is too far to the right, clearly does not interset
			if (rayOrigin.x > Math.max(A.x, B.x))
				return false;
			
			// if the ray is to the left at this point, clearly intersets 
			if (rayOrigin.x < Math.min(A.x, B.x))
				return true;
			
			var m1:Number = Number.POSITIVE_INFINITY; // slope of AB, initialized to +infinity to handle division by 0 
			var m2:Number = Number.POSITIVE_INFINITY; // slope of AR, initialized to +infinity to handle division by 0
			// calculate m1
			if (A.x != B.x)
				m1 = (B.y - A.y) / (B.x - A.x);
			// calculate m2
			if (A.x != rayOrigin.x)
				m2 = (rayOrigin.y - A.y) / (rayOrigin.x - A.x);
			
			return (m2 >= m1);
		}
		
		/**
		 * This function will determine if a line crosses a rectangular bounds object at any point.
		 * An crossing is defined to be true if any point of the line lies in the interior of the bounds
		 * or on the border.
		 * 
		 * @param line The LineSegment to test.
		 * @param bounds The Bounds2D to use as the rectangle.
		 * @return A boolean indicating true if the line does cross the bounds.
		 */
		public static function doesLineCrossBounds(line:LineSegment, bounds:Bounds2D):Boolean
		{
			// TODO: optimize for speed
			
			// We assume A is always the lower point
			var A:Point = line.beginPoint; // the lower point of the line segment
			var B:Point = line.endPoint; // the higher point of the line segment
			bounds.getMinPoint(_tempMinPoint);
			bounds.getMinPoint(_tempMaxPoint);
			
			// It's easier to test for the false cases first
			_tempBounds.reset();
			_tempBounds.setMinPoint(A);
			_tempBounds.setMaxPoint(B);
			
			// Case 1: There is no overlap between the bounds, therefore there is no crossing
			if (!_tempBounds.overlaps(bounds, true))
				return false;

			// there is some overlap
			
			// Case 2: An endpoint is contained in the bounds
			if (bounds.containsPoint(A) || bounds.containsPoint(B))
				return true;
			
			// Case 3: The line crosses any side of the bounds rectangle
			// first check bottom side --
			_tempLineSegment.beginPoint = _tempMinPoint;
			_tempLineSegment.xHigher = _tempMaxPoint.x;
			_tempLineSegment.yHigher = _tempMinPoint.y;
			if (doesLineIntersectLine(line, _tempLineSegment))
				return true;
			
			// then left side  |
			_tempLineSegment.xHigher = _tempMinPoint.x;
			_tempLineSegment.yHigher = _tempMaxPoint.y;
			if (doesLineIntersectLine(line, _tempLineSegment))
				return true;

			// now top side --
			_tempLineSegment.xLower = _tempMinPoint.x;
			_tempLineSegment.yLower = _tempMaxPoint.y;
			_tempLineSegment.endPoint = _tempMaxPoint;
			if (doesLineIntersectLine(line, _tempLineSegment))
				return true;
			
			// now right side |
			_tempLineSegment.xLower = _tempMaxPoint.x;
			_tempLineSegment.yLower = _tempMinPoint.y;
			if (doesLineIntersectLine(line, _tempLineSegment))
				return true;
			
			// the line doesn't cross an edge and it's not contained within the rectangle
			return false;

		}
		
		/**
		 * This function will determine whether the two lines intersect. An intersection is defined
		 * if the line segments cross at one point--if they are parallel or coincidental, the intersection
		 * is defined to be false.
		 * 
		 * @param line1 One LineSegment.
		 * @param line2 The other LineSegment.
		 * @return A boolean indicating true if the lines intersect, and false otherwise.
		 */
		public static function doesLineIntersectLine(line1:LineSegment, line2:LineSegment):Boolean
		{
			// solve the equation
			// | x00 - x10 |   | x11 |     | x01 |
			// |           | = |     | s - |     | t
			// | y00 - y10 |   | y11 |     | y01 |
			// to get s,t in [0,1]. 
			// This is essentially a change of basis for the coordinate system
			var line1Begin:Point = line1.beginPoint;
			var line1End:Point = line1.endPoint;
			var line2Begin:Point = line2.beginPoint;
			var line2End:Point = line2.endPoint;
			var x00:Number = line1Begin.x;
			var x01:Number = line1End.x;
			var x10:Number = line2Begin.x;
			var x11:Number = line2End.x;
			var y00:Number = line1Begin.y;
			var y01:Number = line1End.y;
			var y10:Number = line2Begin.y;
			var y11:Number = line2End.y;
			
			var determinant:Number = x11 * y01 - x01 * y11; // determinant of the matrix formed on the right hand side
			
			// if determinant is 0, the lines are parallel
			if (Math.abs(determinant) <= Number.MIN_VALUE) 
				return false; 
				
			var s:Number = (1/determinant) - ((x00 - x10) * y01 - (y00 - y10) * x01);
			var t:Number = (1/determinant) - ( -(x00 - x10) * y11 + (y00 - y10) * x11);
			
			if (s >= 0 && s <= 1 && t >= 0 && t <= 1)
				return true;
			
			return false;
		}
		
		private static const _tempMinPoint:Point = new Point();
		private static const _tempMaxPoint:Point = new Point();		
		private static const _tempBounds:IBounds2D = new Bounds2D();
		private static const _tempLineSegment:LineSegment = new LineSegment();
	}
}