/* Proj4as3
 *  German Osin (Gradoservice ltd.)
 *  LGPL Licencse
 *
 */

package org.openscales.proj4as.proj {
	import org.openscales.proj4as.ProjConstants;
	import org.openscales.proj4as.ProjPoint;
	import org.openscales.proj4as.Datum;

	public class ProjAea extends AbstractProjProjection {
		public function ProjAea(data:ProjParams) {
			super(data);
		}

		override public function init():void {
			if (Math.abs(this.lat1 + this.lat2) < ProjConstants.EPSLN) {
				trace("aeaInitEqualLatitudes");
				return;
			}
			this.temp=this.b / this.a;
			this.es=1.0 - Math.pow(this.temp, 2);
			this.e3=Math.sqrt(this.es);

			this.sin_po=Math.sin(this.lat1);
			this.cos_po=Math.cos(this.lat1);
			this.t1=this.sin_po
			this.con=this.sin_po;
			this.ms1=ProjConstants.msfnz(this.e3, this.sin_po, this.cos_po);
			this.qs1=ProjConstants.qsfnz(this.e3, this.sin_po, this.cos_po);

			this.sin_po=Math.sin(this.lat2);
			this.cos_po=Math.cos(this.lat2);
			this.t2=this.sin_po;
			this.ms2=ProjConstants.msfnz(this.e3, this.sin_po, this.cos_po);
			this.qs2=ProjConstants.qsfnz(this.e3, this.sin_po, this.cos_po);

			this.sin_po=Math.sin(this.lat0);
			this.cos_po=Math.cos(this.lat0);
			this.t3=this.sin_po;
			this.qs0=ProjConstants.qsfnz(this.e3, this.sin_po, this.cos_po);

			if (Math.abs(this.lat1 - this.lat2) > ProjConstants.EPSLN) {
				this.ns0=(this.ms1 * this.ms1 - this.ms2 * this.ms2) / (this.qs2 - this.qs1);
			} else {
				this.ns0=this.con;
			}
			this.c=this.ms1 * this.ms1 + this.ns0 * this.qs1;
			this.rh=this.a * Math.sqrt(this.c - this.ns0 * this.qs0) / this.ns0;
		}

		/* Albers Conical Equal Area forward equations--mapping lat,long to x,y
		 -------------------------------------------------------------------*/
		override public function forward(p:ProjPoint):ProjPoint {
			var lon:Number=p.x;
			var lat:Number=p.y;

			this.sin_phi=Math.sin(lat);
			this.cos_phi=Math.cos(lat);

			var qs:Number=ProjConstants.qsfnz(this.e3, this.sin_phi, this.cos_phi);
			var rh1:Number=this.a * Math.sqrt(this.c - this.ns0 * qs) / this.ns0;
			var theta:Number=this.ns0 * ProjConstants.adjust_lon(lon - this.long0);
			var x:Number=rh1 * Math.sin(theta) + this.x0;
			var y:Number=this.rh - rh1 * Math.cos(theta) + this.y0;

			p.x=x;
			p.y=y;
			return p;
		}


		override public function inverse(p:ProjPoint):ProjPoint {
			var rh1:Number;
			var qs:Number;
			var con:Number;
			var theta:Number
			var lon:Number;
			var lat:Number;

			p.x-=this.x0;
			p.y=this.rh - p.y + this.y0;
			if (this.ns0 >= 0) {
				rh1=Math.sqrt(p.x * p.x + p.y * p.y);
				con=1.0;
			} else {
				rh1=-Math.sqrt(p.x * p.x + p.y * p.y);
				con=-1.0;
			}
			theta=0.0;
			if (rh1 != 0.0) {
				theta=Math.atan2(con * p.x, con * p.y);
			}
			con=rh1 * this.ns0 / this.a;
			qs=(this.c - con * con) / this.ns0;
			if (this.e3 >= 1e-10) {
				con=1 - .5 * (1.0 - this.es) * Math.log((1.0 - this.e3) / (1.0 + this.e3)) / this.e3;
				if (Math.abs(Math.abs(con) - Math.abs(qs)) > .0000000001) {
					lat=this.phi1z(this.e3, qs);
				} else {
					if (qs >= 0) {
						lat=.5 * Math.PI;
					} else {
						lat=-.5 * Math.PI;
					}
				}
			} else {
				lat=this.phi1z(e3, qs);
			}

			lon=ProjConstants.adjust_lon(theta / this.ns0 + this.long0);
			p.x=lon;
			p.y=lat;
			return p;
		}

		/* Function to compute phi1, the latitude for the inverse of the
		   Albers Conical Equal-Area projection.
		 -------------------------------------------*/
		private function phi1z(eccent:Number, qs:Number):Number {
			var con:Number;
			var com:Number
			var dphi:Number;
			var phi:Number=ProjConstants.asinz(.5 * qs);
			if (eccent < ProjConstants.EPSLN)
				return phi;

			var eccnts:Number=eccent * eccent;
			for (var i:int=1; i <= 25; i++) {
				sinphi=Math.sin(phi);
				cosphi=Math.cos(phi);
				con=eccent * sinphi;
				com=1.0 - con * con;
				dphi=.5 * com * com / cosphi * (qs / (1.0 - eccnts) - sinphi / com + .5 / eccent * Math.log((1.0 - con) / (1.0 + con)));
				phi=phi + dphi;
				if (Math.abs(dphi) <= 1e-7)
					return phi;
			}
			trace("aea:phi1z:Convergence error");
			return 0;
		}


	}
}