package weave.radviz.voronoi
/*package net.ivank.voronoi*/
{
	import flash.geom.Point;
	
	public class VParabola
	{		
		public var site:Point;
		public var cEvent:VEvent;
		
		public var parent:VParabola;		
		private var _left:VParabola;
		private var _right:VParabola;
		public var isLeaf:Boolean;

		public var edge:VEdge;
		
		public function VParabola(s:Point = null)
		{
			this.site = s;
			isLeaf = (site!=null);
		}
		
		public function set left(p:VParabola):void 
		{
			_left = p;
			p.parent = this;
		}	
		public function set right(p:VParabola):void 
		{
			_right = p;
			p.parent = this;
		}
		public function get left():VParabola{ return _left; } 
		public function get right():VParabola{ return _right; } 
		
	}
}