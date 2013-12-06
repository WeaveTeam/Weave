package weave.radviz.voronoi
/*package net.ivank.voronoi*/
{
	import flash.geom.Point;
	//import de.polygonal.ds.Heap;
	//import de.polygonal.ds.PriorityQueue;
	
	
	public class Voronoi
	{	
		private var places:Vector.<Point>;
		private var edges: Vector.<VEdge>;
		//private var queue:PriorityQueue = new PriorityQueue(true);
		private var queue:VQueue = new VQueue();
		//private var queue:Heap = new Heap(true);
		private var i:int;
		private var width:Number;
		private var height:Number;
		
		private var root:VParabola;
		
		private var ly:Number; // line y
		private var lasty:Number; // last y
		
		private var fp:Point; // first point
		
		public function Voronoi()
		{
		}
		
		
		public function GetEdges(p:Vector.<Point>, width:int, height:int):Vector.<VEdge>
		{
			root = null;
			this.places = p;
			this.edges = new Vector.<VEdge>();
			this.width = width;
			this.height = height;
			
			queue.clear(true);
			for(i=0; i<places.length; i++)
			{
				var ev:VEvent = new VEvent(places[i], true);
				queue.enqueue(ev);
			}
			
			var lasty:Number = Number.MAX_VALUE;
			var num:int = 0;
			while(!queue.isEmpty())
			{
				var e:VEvent = queue.dequeue();  
				ly = e.point.y;
				if(e.pe) InsertParabola(e.point);
				else RemoveParabola(e);
				
				if(e.y > lasty) 
				{
					//trace("!!!!! chyba řazení. "+e.y + " < " + lasty);
				} 
				
				lasty = e.y;
				//num++;
			}
			//trace(num);
			FinishEdge(root);
			
			for(i=0; i<edges.length; i++)
			{
				if(edges[i].neighbour) edges[i].start = edges[i].neighbour.end;
			}
			
			return edges;
		}
		
		
		// M E T H O D S   F O R   W O R K   W I T H   T R E E -------
		
		private function InsertParabola(p:Point):void
		{
			if(!root){root = new VParabola(p); fp = p; return;}
			
			if(root.isLeaf && root.site.y - p.y <1)	// degenerovaný případ - první dvě místa ve stejné výšce
			{
				root.isLeaf = false;
				root.left = new VParabola(fp);
				root.right = new VParabola(p);
				var s:Point = new Point((p.x+fp.x)/2, height);
				if(p.x>fp.x) root.edge = new VEdge(s, fp, p);
				else root.edge = new VEdge(s, p, fp);
				edges.push(root.edge);
				return;
			}
			
			var par:VParabola = GetParabolaByX(p.x);
			
			if(par.cEvent)
			{
				queue.remove(par.cEvent);
				par.cEvent = null;
			}
			
			var start:Point = new Point(p.x, GetY(par.site, p.x));
			
			var el:VEdge = new VEdge(start, par.site, p);
			var er:VEdge = new VEdge(start, p, par.site);
			
			el.neighbour = er;
			edges.push(el);
			
			par.edge = er;
			par.isLeaf = false;
			
			var p0:VParabola = new VParabola(par.site);
			var p1:VParabola = new VParabola(p);
			var p2:VParabola = new VParabola(par.site);
			
			par.right = p2;
			par.left = new VParabola();
			par.left.edge = el;
			
			par.left.left = p0;
			par.left.right = p1;
			
			CheckCircle(p0);
			CheckCircle(p2);
		}
		
		private function RemoveParabola(e:VEvent):void
		{						
			var p1:VParabola = e.arch;
			
			var xl:VParabola = GetLeftParent(p1);
			var xr:VParabola = GetRightParent(p1);
			
			var p0:VParabola = GetLeftChild(xl);
			var p2:VParabola = GetRightChild(xr);
			
			if(p0.cEvent){queue.remove(p0.cEvent); p0.cEvent = null;}
			if(p2.cEvent){queue.remove(p2.cEvent); p2.cEvent = null;}
						
			var p:Point = new Point(e.point.x, GetY(p1.site, e.point.x));
			
			lasty = e.point.y;
			
			xl.edge.end = p;
			xr.edge.end = p;
			
			var higher:VParabola;
			var par:VParabola = p1;
			while(par != root)
			{
				par = par.parent;
				if(par == xl) {higher = xl;}
				if(par == xr) {higher = xr;}
			}
			
			higher.edge = new VEdge(p, p0.site, p2.site);
			
			edges.push(higher.edge);
			
			var gparent:VParabola = p1.parent.parent;
			if(p1.parent.left == p1)
			{
				if(gparent.left  == p1.parent) gparent.left  = p1.parent.right;
				else p1.parent.parent.right = p1.parent.right;
			}
			else
			{
				if(gparent.left  == p1.parent) gparent.left  = p1.parent.left;
				else gparent.right = p1.parent.left;
			}
			
			CheckCircle(p0);
			CheckCircle(p2);
		}
		
		private function FinishEdge(n:VParabola):void
		{
			var mx:Number;
			if(n.edge.direction.x > 0.0)
			{
				mx = Math.max(width, n.edge.start.x + 10 );
			}
			else
			{
				mx = Math.min(0.0, n.edge.start.x - 10);
			}
			n.edge.end = new Point(mx, n.edge.f*mx + n.edge.g);
			
			if(!n.left.isLeaf)  FinishEdge(n.left);
			if(!n.right.isLeaf) FinishEdge(n.right);
		}
		
		private function GetXOfEdge(par:VParabola, y:Number):Number // počítá průsečík parabol v daném uzlu
		{
			var left:VParabola = GetLeftChild(par);
			var right:VParabola = GetRightChild(par);
			
			var p:Point = left.site;
			var r:Point = right.site;
			
			var dp:Number = 2*(p.y - y);
			var a1:Number = 1/dp;
			var b1:Number = -2*p.x/dp;
			var c1:Number = y+dp/4 + p.x*p.x/dp;
			
			dp = 2*(r.y - y);
			var a2:Number = 1/dp;
			var b2:Number = -2*r.x/dp;
			var c2:Number = y+dp/4 + r.x*r.x/dp;
			
			var a:Number = a1 - a2;
			var b:Number = b1 - b2;
			var c:Number = c1 - c2;
			
			var disc:Number = b*b - 4 * a * c;
			var x1:Number = (-b + Math.sqrt(disc)) / (2*a);
			var x2:Number = (-b - Math.sqrt(disc)) / (2*a);

			var ry:Number;
			if(p.y < r.y ) ry =  Math.max(x1, x2);
			else ry = Math.min(x1, x2);

			return ry;
		}
		
		public function GetParabolaByX(xx:Number):VParabola
		{
			var par:VParabola = root;
			var x:Number = 0;
			
			while(!par.isLeaf)
			{
				x = GetXOfEdge(par, ly);
				if(x>xx) par = par.left;
				else par = par.right;				
			}
			return par;
		}
		
		private function GetY(p:Point, x:Number):Number // ohnisko, x-souřadnice, řídící přímka
		{
			var dp:Number = 2*(p.y - ly);
			var b1:Number = -2*p.x/dp;
			var c1:Number = ly+dp/4 + p.x*p.x/dp;
			
			return(x*x/dp + b1*x + c1);
		}
		
		
		private function CheckCircle(b:VParabola):void
		{
			var lp:VParabola = GetLeftParent(b);
			var rp:VParabola = GetRightParent(b);
			
			var a:VParabola = GetLeftChild(lp);
			var c:VParabola = GetRightChild(rp);
			
			if(!a || !c || a.site == c.site) return;
			
			var s:Point = GetEdgeIntersection(lp.edge, rp.edge);
			if(!s) return;
			
			var d:Number = Point.distance(a.site, s);
			//if(d > 5000) return;
			if(s.y - d  >= ly) return;
			
			var e:VEvent = new VEvent(new Point(s.x, s.y - d), false);
			
			b.cEvent = e;
			e.arch = b;
			queue.enqueue(e);
		}
		
		private function GetEdgeIntersection(a:VEdge, b:VEdge):Point
		{
			
			var x:Number = (b.g-a.g) / (a.f - b.f);
			var y:Number = a.f * x + a.g;
			
			// test rovnoběžnosti
			if(Math.abs(x) + Math.abs(y) > 20*width) { return null;} // parallel
			if(Math.abs(a.direction.x)<0.01 && Math.abs(b.direction.x) <0.01) { return null;} 
			
			if((x - a.start.x)/a.direction.x<0) {return null};
			if((y - a.start.y)/a.direction.y<0) {return null};
			
			if((x - b.start.x)/b.direction.x<0) {return null};
			if((y - b.start.y)/b.direction.y<0) {return null};			
						
			return new Point(x, y);
		}
		
		/*
		private function GetCircumcenter(a:Point, b:Point, c:Point):Point
		{
			// line: y = f*x + g
			var f1 = (b.x - a.x) / (a.y - b.y);
			var m1 = new Point((a.x + b.x)/2, (a.y + b.y)/2);
			var g1 = m1.y - f1*m1.x;
			
			var f2 = (c.x - b.x) / (b.y - c.y);
			var m2 = new Point((b.x + c.x)/2, (b.y + c.y)/2);
			var g2 = m2.y - f2*m2.x;
			
			var x:Number = (g2-g1) / (f1 - f2);
			return new Point(x, f1*x + g1);
		}
		*/
		
		private function GetLeft(n:VParabola):VParabola
		{
			return GetLeftChild(GetLeftParent(n));
		}
		
		private function GetRight(n:VParabola):VParabola
		{
			return GetRightChild(GetRightParent(n));
		}	
		
		private function GetLeftParent(n:VParabola):VParabola
		{
			var par:VParabola = n.parent;
			var pLast:VParabola = n;
			while(par.left == pLast) 
			{ 
				if(!par.parent) return null;
				pLast = par; par = par.parent; 
			}
			return par;
		}
		private function GetRightParent(n:VParabola):VParabola
		{
			var par:VParabola = n.parent;
			var pLast:VParabola = n;
			while(par.right == pLast) 
			{	
				if(!par.parent) return null;
				pLast = par; par = par.parent;	
			}
			return par;
		}
		private function GetLeftChild(n:VParabola):VParabola
		{
			if(!n) return null;
			var par:VParabola = n.left;
			while(!par.isLeaf) par = par.right;
			return par;
		}
		private function GetRightChild(n:VParabola):VParabola
		{
			if(!n) return null;
			var par:VParabola = n.right;
			while(!par.isLeaf) par = par.left;
			return par;
		}
		
		/*
		private function drawParabola(p:Point, y:Number):void
		{
			var dp = 2*(p.y - y);
			var a1 = 1/dp;
			var b1 = -2*p.x/dp;
			var c1 = y+dp/4 + p.x*p.x/dp;
			
			gr.lineStyle(2, 0x000000);
			for(var i:int = -500; i<1000; i+=5)
			{
				gr.moveTo(i, a1*i*i + b1*i + c1);
				gr.lineTo(i+5, a1*(i+5)*(i+5) + b1*(i+5) + c1);
			}
			
		}
		
		private function drawGraph(p:VParabola, x:int, y:int, w:int):void
		{
			gr.lineStyle(3, p.color);
			gr.drawCircle(x, y, 5);
			gr.lineStyle(2, 0x000000);
			if(!p.isLeaf)
			{
				gr.moveTo(x, y);
				gr.lineTo(x-w/4, y+10);
				gr.moveTo(x, y);
				gr.lineTo(x+w/4, y+10);
				drawGraph(p.left, x-w/4, y+10, w/2);
				drawGraph(p.right, x+w/4, y+10, w/2);
			}
			else
			{
				//gr.lineStyle(3, p.color);
				//gr.moveTo(x, y);
				//gr.lineTo(p.site.x, p.site.y);
			}
			
		}
		
		private function drawBeachLine(n:VParabola, y:Number, from:Number, to:Number)
		{
			if(!n) return;
			if(n.isLeaf)
			{
				var dp = 2*(n.site.y - y);
				var a1 = 1/dp;
				var b1 = -2*n.site.x/dp;
				var c1 = y+dp/4 + n.site.x * n.site.x/dp;
				for(var i:int = from; i<to; i++)
				{
					gr.lineStyle(2, n.color);
					gr.moveTo(i, a1*i*i + b1*i + c1);
					gr.lineTo(i+1, a1*(i+1)*(i+1) + b1*(i+1) + c1);
					gr.moveTo(i, y);
					gr.lineTo(i+1, y);
				}
			}
			else
			{
				var m:Number = GetXOfEdge(n, y);
				var ny:Number = GetY(GetRightChild(n).site, m);
				
				gr.lineStyle(1, 0x000000);
				gr.moveTo(m, ny);
				gr.lineTo(m + n.edge.direction.x, ny + n.edge.direction.y);
				//trace(n.edge.direction.y);
				
				gr.moveTo(m, 0);
				gr.lineTo(m, 1000);
				drawBeachLine(n.left, y, from, m);
				drawBeachLine(n.right, y, m, to);
			}
			
			
		}
		*/
	}
}