/*******************************************************************************
   NAME                  LAMBERT AZIMUTHAL EQUAL-AREA

   PURPOSE:	Transforms input longitude and latitude to Easting and
   Northing for the Lambert Azimuthal Equal-Area projection.  The
   longitude and latitude must be in radians.  The Easting
   and Northing values will be returned in meters.

   PROGRAMMER              DATE
   ----------              ----
   D. Steinwand, EROS      March, 1991

   This function was adapted from the Lambert Azimuthal Equal Area projection
   code (FORTRAN) in the General Cartographic Transformation Package software
   which is available from the U.S. Geological Survey National Mapping Division.

   ALGORITHM REFERENCES

   1.  "New Equal-Area Map Projections for Noncircular Regions", John P. Snyder,
   The American Cartographer, Vol 15, No. 4, October 1988, pp. 341-355.

   2.  Snyder, John P., "Map Projections--A Working Manual", U.S. Geological
   Survey Professional Paper 1395 (Supersedes USGS Bulletin 1532), United
   State Government Printing Office, Washington D.C., 1987.

   3.  "Software Documentation for GCTP General Cartographic Transformation
   Package", U.S. Geological Survey National Mapping Division, May 1982.
 *******************************************************************************/

package org.openscales.proj4as.proj {
	import org.openscales.proj4as.ProjPoint;
	import org.openscales.proj4as.ProjConstants;
	import org.openscales.proj4as.Datum;

	public class ProjLaea extends AbstractProjProjection {
		private var sin_lat_o:Number;
		private var cos_lat_o:Number;

		public function ProjLaea(data:ProjParams) {
			super(data);
		}

		/* Initialize the Lambert Azimuthal Equal Area projection
		 ------------------------------------------------------*/
		override public function init():void {
			this.sin_lat_o=Math.sin(this.lat0);
			this.cos_lat_o=Math.cos(this.lat0);
		}

		/* Lambert Azimuthal Equal Area forward equations--mapping lat,long to x,y
		 -----------------------------------------------------------------------*/
		override public function forward(p:ProjPoint):ProjPoint {

			/* Forward equations
			 -----------------*/
			var lon:Number=p.x;
			var lat:Number=p.y;
			var delta_lon:Number=ProjConstants.adjust_lon(lon - this.long0);

			//v 1.0
			var sin_lat:Number=Math.sin(lat);
			var cos_lat:Number=Math.cos(lat);

			var sin_delta_lon:Number=Math.sin(delta_lon);
			var cos_delta_lon:Number=Math.cos(delta_lon);

			var g:Number=this.sin_lat_o * sin_lat + this.cos_lat_o * cos_lat * cos_delta_lon;
			if (g == -1.0) {
				trace("laea:fwd:Point projects to a circle of radius ");
				return null;
			}
			var ksp:Number=this.a * Math.sqrt(2.0 / (1.0 + g));
			var x:Number=ksp * cos_lat * sin_delta_lon + this.x0;
			var y:Number=ksp * (this.cos_lat_o * sin_lat - this.sin_lat_o * cos_lat * cos_delta_lon) + this.y0;
			p.x=x;
			p.y=y
			return p;
		} //lamazFwd()

		/* Inverse equations
		 -----------------*/
		override public function inverse(p:ProjPoint):ProjPoint {
			p.x-=this.x0;
			p.y-=this.y0;

			var Rh:Number=Math.sqrt(p.x * p.x + p.y * p.y);
			var temp:Number=Rh / (2.0 * this.a);

			if (temp > 1) {
				trace("laea:Inv:DataError");
				return null;
			}

			var z:Number=2.0 * ProjConstants.asinz(temp);
			var sin_z:Number=Math.sin(z);
			var cos_z:Number=Math.cos(z);

			var lon:Number=this.long0;
			if (Math.abs(Rh) > ProjConstants.EPSLN) {
				var lat:Number=ProjConstants.asinz(this.sin_lat_o * cos_z + this.cos_lat_o * sin_z * p.y / Rh);
				temp=Math.abs(this.lat0) - ProjConstants.HALF_PI;
				if (Math.abs(temp) > ProjConstants.EPSLN) {
					temp=cos_z - this.sin_lat_o * Math.sin(lat);
					if (temp != 0.0)
						lon=ProjConstants.adjust_lon(this.long0 + Math.atan2(p.x * sin_z * this.cos_lat_o, temp * Rh));
				} else if (this.lat0 < 0.0) {
					lon=ProjConstants.adjust_lon(this.long0 - Math.atan2(-p.x, p.y));
				} else {
					lon=ProjConstants.adjust_lon(this.long0 + Math.atan2(p.x, -p.y));
				}
			} else {
				lat=this.lat0;
			}
			//return(OK);
			p.x=lon;
			p.y=lat;
			return p;
		} //lamazInv()


	}
}