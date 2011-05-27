package weave.primitives
{
	import flash.geom.Point;

	/**
	 * This class describes a line ray. A ray is defined as a direction and origin.
	 * The direction is an angle between 0 and 360 degrees. This class currently has limited
	 * functionality.
	 * 
	 * @author kmonico
	 */
	public class LineRay
	{
		public function LineRay(xOrigin:Number, yOrigin:Number, theta:Number = 0)
		{
			_origin.x = xOrigin;
			_origin.y = yOrigin;
			_angle = theta;
		}
		
		public function set origin(p:Point):void { _origin.x = p.x; _origin.y = p.y; }
		public function get origin():Point { return _origin; } 
		public function set angle(theta:Number):void { _angle = theta; }
		public function get angle():Number { return _angle; }
		private const _origin:Point = new Point();
		private var _angle:Number; // the angle in degrees
	}
}
