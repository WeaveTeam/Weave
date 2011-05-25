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
		
		public function set xLower(val:Number):void { _p1.x = val; }
		public function set yLower(val:Number):void { _p1.y = val; }
		public function set xHigher(val:Number):void { _p2.x = val; }
		public function set yHigher(val:Number):void { _p2.y = val; }
		public function get xLower():Number { return _p1.x; }
		public function get yLower():Number { return _p1.y; }
		public function get xHigher():Number { return _p2.x; }
		public function get yHigher():Number { return _p2.y; }
	}
}