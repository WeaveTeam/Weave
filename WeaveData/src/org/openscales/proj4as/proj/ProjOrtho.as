/*******************************************************************************
   NAME                             ORTHOGRAPHIC

   PURPOSE:	Transforms input longitude and latitude to Easting and
   Northing for the Orthographic projection.  The
   longitude and latitude must be in radians.  The Easting
   and Northing values will be returned in meters.

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

	public class ProjOrtho extends AbstractProjProjection {

		private var cos_p14:Number;
		private var sin_p14:Number;

		public function ProjOrtho(data:ProjParams) {
			super(data);
		}

		override public function init():void {
			//double temp;			/* temporary variable		*/

			/* Place parameters in static storage for common use
			 -------------------------------------------------*/
			;
			this.sin_p14=Math.sin(this.lat0);
			this.cos_p14=Math.cos(this.lat0);
		}


		/* Orthographic forward equations--mapping lat,long to x,y
		 ---------------------------------------------------*/
		override public function forward(p:ProjPoint):ProjPoint {
			var sinphi:Number, cosphi:Number; /* sin and cos value				*/
			var dlon:Number; /* delta longitude value			*/
			var coslon:Number; /* cos of longitude				*/
			var ksp:Number; /* scale factor					*/
			var g:Number;
			var lon:Number=p.x;
			var lat:Number=p.y;
			var x:Number, y:Number;
			/* Forward equations
			 -----------------*/
			dlon=ProjConstants.adjust_lon(lon - this.long0);

			sinphi=Math.sin(lat);
			cosphi=Math.cos(lat);

			coslon=Math.cos(dlon);
			g=this.sin_p14 * sinphi + this.cos_p14 * cosphi * coslon;
			ksp=1.0;
			if ((g > 0) || (Math.abs(g) <= ProjConstants.EPSLN)) {
				x=this.a * ksp * cosphi * Math.sin(dlon);
				y=this.y0 + this.a * ksp * (this.cos_p14 * sinphi - this.sin_p14 * cosphi * coslon);
			} else {
				trace("orthoFwdPointError");
			}
			p.x=x;
			p.y=y;
			return p;
		}


		override public function inverse(p:ProjPoint):ProjPoint {
			var rh:Number; /* height above ellipsoid			*/
			var x:Number, y:Number, z:Number; /* angle					*/
			var sinz:Number, cosz:Number, cosi:Number; /* sin of z and cos of z			*/
			var temp:Number;
			var con:Number;
			var lon:Number, lat:Number;
			/* Inverse equations
			 -----------------*/
			p.x-=this.x0;
			p.y-=this.y0;
			rh=Math.sqrt(p.x * p.x + p.y * p.y);
			if (rh > this.a + .0000001) {
				trace("orthoInvDataError");
			}
			z=ProjConstants.asinz(rh / this.a);

			sinz=Math.sin(z);
			cosi=Math.cos(z);

			lon=this.long0;
			if (Math.abs(rh) <= ProjConstants.EPSLN) {
				lat=this.lat0;
			}
			lat=ProjConstants.asinz(cosz * this.sin_p14 + (y * sinz * this.cos_p14) / rh);
			con=Math.abs(lat0) - ProjConstants.HALF_PI;
			if (Math.abs(con) <= ProjConstants.EPSLN) {
				if (this.lat0 >= 0) {
					lon=ProjConstants.adjust_lon(this.long0 + Math.atan2(p.x, -p.y));
				} else {
					lon=ProjConstants.adjust_lon(this.long0 - Math.atan2(-p.x, p.y));
				}
			}
			con=cosz - this.sin_p14 * Math.sin(lat);
			if ((Math.abs(con) >= ProjConstants.EPSLN) || (Math.abs(x) >= ProjConstants.EPSLN)) {
				lon=ProjConstants.adjust_lon(this.long0 + Math.atan2((p.x * sinz * this.cos_p14), (con * rh)));
			}
			p.x=lon;
			p.y=lat;
			return p;
		}


	}
}