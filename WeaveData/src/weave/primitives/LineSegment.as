package weave.primitives
{
	import flash.geom.Point;

	/** 
	 * This class acts a wrapper for two points. It provides some functionality for 
	 * computational geometry.
	 * 
	 * @author kmonico
	 */
	public class LineSegment
	{
		public function LineSegment(p1:Point = null, p2:Point = null)
		{
			if (p1 && p2)
			{
				// if p1 is lower point
				if (p1.y < p2.y)
				{
					_p1.x = p1.x;
					_p1.y = p1.y;
					_p2.x = p2.x;
					_p2.y = p2.y;
				}
				else // p2 is lower point
				{
					_p1.x = p2.x;
					_p1.y = p2.y;
					_p2.x = p1.x;
					_p2.y = p1.y;
				}
			}
			else if (p1)
			{
				_p1.x = p1.x;
				_p1.y = p1.y;
			}
			else if (p2)
			{
				_p2.x = p2.x;
				_p2.y = p2.y;
			}
		}
		
		public function get beginPoint():Point { return _p1; }
		public function get endPoint():Point { return _p2; }
		public function set beginPoint(p:Point):void { _p1.x = p.x; _p1.y = p.y; }
		public function set endPoint(p:Point):void { _p2.x = p.x; _p2.y = p.y; }
		
		private const _p1:Point = new Point();
		private const _p2:Point = new Point();
		
		public function intersectsRay(other:LineRay):Boolean
		{
			var rayOrigin:Point = other.origin; // origin of the ray
			var A:Point = _p1; // the lower point of the line segment
			var B:Point = _p2; // the higher point of the line segment
			
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
		
		public function makeSlopePositive():void
		{
			if (_p1.y > _p2.y)
			{
				var xTemp:Number = _p1.x;
				var yTemp:Number = _p1.y;
				_p1.x = _p2.x;
				_p1.y = _p2.y;
				_p2.x = xTemp;
				_p2.y = yTemp;
			}
		}
	}
}