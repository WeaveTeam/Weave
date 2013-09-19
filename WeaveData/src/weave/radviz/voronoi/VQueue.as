package weave.radviz.voronoi
/*package net.ivank.voronoi*/
{
	//import de.polygonal.ds.Prioritizable;
	import flash.geom.Point;
	
	public class VQueue
	{
		private var q:Array = new Array();
		private var i:int;
		
		public function sortOnY(a:VEvent, b:VEvent):Number 
		{
			//var bigger:Boolean = (a.y > b.y);
			return(a.y > b.y)?1:-1;
		}
		
		public function VQueue():void
		{
			
		}
		
		public function enqueue(p:VEvent):void
		{
			q.push(p);
		}
		
		public function dequeue():VEvent
		{
			q.sort(sortOnY);
			return q.pop();
		}
		public function remove(e:VEvent):void
		{
			var index:int = -1;
			for(i=0; i<q.length; i++)
			{
				if(q[i]==e){ index = i; break; }
			}
			q.splice(index, 1);
		}
		
		public function isEmpty():Boolean
		{
			return (q.length==0);
		}
		public function clear(b:Boolean):void
		{
			q = [];
		}
	}
	
}