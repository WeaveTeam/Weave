package weave.radviz.voronoi
/*package net.ivank.voronoi*/
{
	import flash.geom.Point;
	
	public class VEdge
	{		
		public var start:Point;
		public var end:Point;
		
		public var direction:Point;
		
		public var left:Point;
		public var right:Point;
		public var f:Number;
		public var g:Number;
		
		public var neighbour:VEdge;
		
		public function VEdge(s:Point, a:Point, b:Point):void // start, left, right
		{
			left = a;
			right = b;
			start = s;
			f = (b.x - a.x) / (a.y - b.y);
			g = s.y - f*s.x;
			direction = new Point(b.y-a.y, -(b.x - a.x));
		}
		
	}
}