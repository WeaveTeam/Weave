/*******************************************************************************
   NAME                            MERCATOR

   PURPOSE:	Transforms input longitude and latitude to Easting and
   Northing for the Mercator projection.  The
   longitude and latitude must be in radians.  The Easting
   and Northing values will be returned in meters.

   PROGRAMMER              DATE
   ----------              ----
   D. Steinwand, EROS      Nov, 1991
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
	import org.openscales.proj4as.Datum;
	import org.openscales.proj4as.ProjConstants;
	import org.openscales.proj4as.ProjPoint;

	public class ProjMerc extends AbstractProjProjection {
		public function ProjMerc(data:ProjParams) {
			super(data);
		}

		override public function init():void {
			//?this.temp = this.r_minor / this.r_major;
			//this.temp = this.b / this.a;
			//this.es = 1.0 - Math.sqrt(this.temp);
			//this.e = Math.sqrt( this.es );
			//?this.m1 = Math.cos(this.lat_origin) / (Math.sqrt( 1.0 - this.es * Math.sin(this.lat_origin) * Math.sin(this.lat_origin)));
			//this.m1 = Math.cos(0.0) / (Math.sqrt( 1.0 - this.es * Math.sin(0.0) * Math.sin(0.0)));
			if (this.lat_ts) {
				if (this.sphere) {
					this.k0=Math.cos(this.lat_ts);
				} else {
					this.k0=ProjConstants.msfnz(this.es, Math.sin(this.lat_ts), Math.cos(this.lat_ts));
				}
			}
		}

		/* Mercator forward equations--mapping lat,long to x,y
		 --------------------------------------------------*/
		
		// KM Feb 10, 2011--added constant which is the maximum latitude in radians
		static private const MAX_LAT_IN_RAD:Number = Math.atan(ProjConstants.sinh(Math.PI));
		
		override public function forward(p:ProjPoint):ProjPoint {
			//alert("ll2m coords : "+coords);
			var lon:Number=p.x;
			var lat:Number=p.y;
			// convert to radians
			if (lat * ProjConstants.R2D > 90.0 && lat * ProjConstants.R2D < -90.0 && lon * ProjConstants.R2D > 180.0 && lon * ProjConstants.R2D < -180.0) {
				trace("merc:forward: llInputOutOfRange: " + lon + " : " + lat);
				return null;
			}

			var x:Number, y:Number;
			
			if (Math.abs(lat) > MAX_LAT_IN_RAD) {
				//trace("merc:forward: ll2mAtPoles");
				
				// KM Feb 10, 2011--still need to reproject the point, so put it at the max/min lat
				if (lat > 0)
					lat = MAX_LAT_IN_RAD;
				else
					lat = -MAX_LAT_IN_RAD;
			}
			
			// KM Feb 10, 2011--always reproject
			if (this.sphere) {
				x=this.x0 + this.a * this.k0 * ProjConstants.adjust_lon(lon - this.long0);
				y=this.y0 + this.a * this.k0 * Math.log(Math.tan(ProjConstants.FORTPI + 0.5 * lat));
			} else {
				var sinphi:Number=Math.sin(lat);
				var ts:Number=ProjConstants.tsfnz(this.e, lat, sinphi);
				x=this.x0 + this.a * this.k0 * ProjConstants.adjust_lon(lon - this.long0);
				y=this.y0 - this.a * this.k0 * Math.log(ts);
			}
			p.x=x;
			p.y=y;
			return p;
		}


		/* Mercator inverse equations--mapping x,y to lat/long
		 --------------------------------------------------*/
		override public function inverse(p:ProjPoint):ProjPoint {
			var x:Number=p.x - this.x0;
			var y:Number=p.y - this.y0;
			var lon:Number, lat:Number;

			if (this.sphere) {
				lat=ProjConstants.HALF_PI - 2.0 * Math.atan(Math.exp(-y / this.a * this.k0));
			} else {
				var ts:Number=Math.exp(-y / (this.a * this.k0));
				lat=ProjConstants.phi2z(this.e, ts);
				if (lat == -9999) {
					trace("merc:inverse: lat = -9999");
					return null;
				}
			}
			lon=ProjConstants.adjust_lon(this.long0 + x / (this.a * this.k0));

			p.x=lon;
			p.y=lat;
			return p;
		}


	}
}