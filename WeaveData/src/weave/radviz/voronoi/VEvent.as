package weave.radviz.voronoi
/*package net.ivank.voronoi*/
{
	import flash.geom.Point;
	//import de.polygonal.ds.Comparable;
	
	public class VEvent // implements Comparable
	{
		public var point:Point;
		public var pe:Boolean; // place event or not
		
		public var y:Number;
		public var key:int;
		
		public var arch:VParabola;
		
		public var value:int;
		
		public function VEvent(p:Point, pe:Boolean)
		{
			this.point = p;
			this.pe = pe;
			this.y = p.y;
			this.key = Math.random()*100000000000;
		}
		
		public function compare(other:Object):int
		{
			var b1:Boolean = (y > other.y);
			return (b1?1:-1);
		}

	}
	
}