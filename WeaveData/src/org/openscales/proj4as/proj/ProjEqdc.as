/*******************************************************************************
   NAME                            EQUIDISTANT CONIC

   PURPOSE:	Transforms input longitude and latitude to Easting and Northing
   for the Equidistant Conic projection.  The longitude and
   latitude must be in radians.  The Easting and Northing values
   will be returned in meters.

   PROGRAMMER              DATE
   ----------              ----
   T. Mittan		Mar, 1993

   ALGORITHM REFERENCES

   1.  Snyder, John P., "Map Projections--A Working Manual", U.S. Geological
   Survey Professional Paper 1395 (Supersedes USGS Bulletin 1532), United
   State Government Printing Office, Washington D.C., 1987.

   2.  Snyder, John P. and Voxland, Philip M., "An Album of Map Projections",
   U.S. Geological Survey Professional Paper 1453 , United State Government
   Printing Office, Washington D.C., 1989.
 *******************************************************************************/

package org.openscales.proj4as.proj {
	import org.openscales.proj4as.ProjPoint;
	import org.openscales.proj4as.ProjConstants;
	import org.openscales.proj4as.Datum;

	public class ProjEqdc extends AbstractProjProjection {
		public function ProjEqdc(data:ProjParams) {
			super(data);
		}


		/* Variables common to all subroutines in this code file
		 -----------------------------------------------------*/

		/* Initialize the Equidistant Conic projection
		 ------------------------------------------*/
		override public function init():void {
			/* Place parameters in static storage for common use
			 -------------------------------------------------*/
			if (!this.mode)
				this.mode=0; //chosen default mode
			this.temp=this.b / this.a;
			this.es=1.0 - Math.pow(this.temp, 2);
			this.e=Math.sqrt(this.es);
			this.e0=ProjConstants.e0fn(this.es);
			this.e1=ProjConstants.e1fn(this.es);
			this.e2=ProjConstants.e2fn(this.es);
			this.e3=ProjConstants.e3fn(this.es);

			this.sinphi=Math.sin(this.lat1);
			this.cosphi=Math.cos(this.lat1);

			this.ms1=ProjConstants.msfnz(this.e, this.sinphi, this.cosphi);
			this.ml1=ProjConstants.mlfn(this.e0, this.e1, this.e2, this.e3, this.lat1);

			/* format B
			 ---------*/
			if (this.mode != 0) {
				if (Math.abs(this.lat1 + this.lat2) < ProjConstants.EPSLN) {
					trace("eqdc:Init:EqualLatitudes");
						//return(81);
				}
				this.sinphi=Math.sin(this.lat2);
				this.cosphi=Math.cos(this.lat2);

				this.ms2=ProjConstants.msfnz(this.e, this.sinphi, this.cosphi);
				this.ml2=ProjConstants.mlfn(this.e0, this.e1, this.e2, this.e3, this.lat2);
				if (Math.abs(this.lat1 - this.lat2) >= ProjConstants.EPSLN) {
					this.ns=(this.ms1 - this.ms2) / (this.ml2 - this.ml1);
				} else {
					this.ns=this.sinphi;
				}
			} else {
				this.ns=this.sinphi;
			}
			this.g=this.ml1 + this.ms1 / this.ns;
			this.ml0=ProjConstants.mlfn(this.e0, this.e1, this.e2, this.e3, this.lat0);
			this.rh=this.a * (this.g - this.ml0);
		}


		/* Equidistant Conic forward equations--mapping lat,long to x,y
		 -----------------------------------------------------------*/
		override public function forward(p:ProjPoint):ProjPoint {
			var lon:Number=p.x;
			var lat:Number=p.y;

			/* Forward equations
			 -----------------*/
			var ml:Number=ProjConstants.mlfn(this.e0, this.e1, this.e2, this.e3, lat);
			var rh1:Number=this.a * (this.g - ml);
			var theta:Number=this.ns * ProjConstants.adjust_lon(lon - this.long0);

			var x:Number=this.x0 + rh1 * Math.sin(theta);
			var y:Number=this.y0 + this.rh - rh1 * Math.cos(theta);
			p.x=x;
			p.y=y;
			return p;
		}

		/* Inverse equations
		 -----------------*/
		override public function inverse(p:ProjPoint):ProjPoint {
			p.x-=this.x0;
			p.y=this.rh - p.y + this.y0;
			var con:Number;
			var rh1:Number;
			if (this.ns >= 0) {
				rh1=Math.sqrt(p.x * p.x + p.y * p.y);
				con=1.0;
			} else {
				rh1=-Math.sqrt(p.x * p.x + p.y * p.y);
				con=-1.0;
			}
			var theta:Number=0.0;
			if (rh1 != 0.0)
				theta=Math.atan2(con * p.x, con * p.y);
			var ml:Number=this.g - rh1 / this.a;
			var lat:Number=this.phi3z(this.ml, this.e0, this.e1, this.e2, this.e3);
			var lon:Number=ProjConstants.adjust_lon(this.long0 + theta / this.ns);

			p.x=lon;
			p.y=lat;
			return p;
		}

		/* Function to compute latitude, phi3, for the inverse of the Equidistant
		   Conic projection.
		 -----------------------------------------------------------------*/
		private function phi3z(ml:Number, e0:Number, e1:Number, e2:Number, e3:Number):Number {
			var phi:Number;
			var dphi:Number;

			phi=ml;
			for (var i:int=0; i < 15; i++) {
				dphi=(ml + e1 * Math.sin(2.0 * phi) - e2 * Math.sin(4.0 * phi) + e3 * Math.sin(6.0 * phi)) / e0 - phi;
				phi+=dphi;
				if (Math.abs(dphi) <= .0000000001) {
					return phi;
				}
			}
			trace("PHI3Z-CONV:Latitude failed to converge after 15 iterations");
			return 0;
		}


	}
}