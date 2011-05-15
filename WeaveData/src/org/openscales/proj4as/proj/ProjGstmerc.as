package org.openscales.proj4as.proj {
	import org.openscales.proj4as.ProjPoint;
	import org.openscales.proj4as.ProjConstants;
	import org.openscales.proj4as.Datum;

	public class ProjGstmerc extends AbstractProjProjection {

		private var cp:Number;
		private var lc:Number;
		private var n2:Number;
		private var rs:Number;
		private var xs:Number;
		private var ys:Number;

		public function ProjGstmerc(data:ProjParams) {
			super(data);
		}

		override public function init():void {
			// array of:  a, b, lon0, lat0, k0, x0, y0
			var temp:Number=this.b / this.a;
			this.e=Math.sqrt(1.0 - temp * temp);
			this.lc=this.long0;
			this.rs=Math.sqrt(1.0 + this.e * this.e * Math.pow(Math.cos(this.lat0), 4.0) / (1.0 - this.e * this.e));
			var sinz:Number=Math.sin(this.lat0);
			var pc:Number=Math.asin(sinz / this.rs);
			var sinzpc:Number=Math.sin(pc);
			this.cp=ProjConstants.latiso(0.0, pc, sinzpc) - this.rs * ProjConstants.latiso(this.e, this.lat0, sinz);
			this.n2=this.k0 * this.a * Math.sqrt(1.0 - this.e * this.e) / (1.0 - this.e * this.e * sinz * sinz);
			this.xs=this.x0;
			this.ys=this.y0 - this.n2 * pc;

			if (!this.title)
				this.title="Gauss Schreiber transverse mercator";
		}


		// forward equations--mapping lat,long to x,y
		// -----------------------------------------------------------------
		override public function forward(p:ProjPoint):ProjPoint {
			var lon:Number=p.x;
			var lat:Number=p.y;

			var L:Number=this.rs * (lon - this.lc);
			var Ls:Number=this.cp + (this.rs * ProjConstants.latiso(this.e, lat, Math.sin(lat)));
			var lat1:Number=Math.asin(Math.sin(L) / ProjConstants.cosh(Ls));
			var Ls1:Number=ProjConstants.latiso(0.0, lat1, Math.sin(lat1));
			p.x=this.xs + (this.n2 * Ls1);
			p.y=this.ys + (this.n2 * Math.atan(ProjConstants.sinh(Ls) / Math.cos(L)));
			return p;
		}

		// inverse equations--mapping x,y to lat/long
		// -----------------------------------------------------------------
		override public function inverse(p:ProjPoint):ProjPoint {
			var x:Number=p.x;
			var y:Number=p.y;

			var L:Number=Math.atan(ProjConstants.sinh((x - this.xs) / this.n2) / Math.cos((y - this.ys) / this.n2));
			var lat1:Number=Math.asin(Math.sin((y - this.ys) / this.n2) / ProjConstants.cosh((x - this.xs) / this.n2));
			var LC:Number=ProjConstants.latiso(0.0, lat1, Math.sin(lat1));
			p.x=this.lc + L / this.rs;
			p.y=ProjConstants.invlatiso(this.e, (LC - this.cp) / this.rs);
			return p;
		}


	}
}