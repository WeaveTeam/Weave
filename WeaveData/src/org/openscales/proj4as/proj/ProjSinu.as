/*******************************************************************************
   NAME                  		SINUSOIDAL

   PURPOSE:	Transforms input longitude and latitude to Easting and
   Northing for the Sinusoidal projection.  The
   longitude and latitude must be in radians.  The Easting
   and Northing values will be returned in meters.

   PROGRAMMER              DATE
   ----------              ----
   D. Steinwand, EROS      May, 1991

   This function was adapted from the Sinusoidal projection code (FORTRAN) in the
   General Cartographic Transformation Package software which is available from
   the U.S. Geological Survey National Mapping Division.

   ALGORITHM REFERENCES

   1.  Snyder, John P., "Map Projections--A Working Manual", U.S. Geological
   Survey Professional Paper 1395 (Supersedes USGS Bulletin 1532), United
   State Government Printing Office, Washington D.C., 1987.

   2.  "Software Documentation for GCTP General Cartographic Transformation
   Package", U.S. Geological Survey National Mapping Division, May 1982.
 *******************************************************************************/

package org.openscales.proj4as.proj {
	import org.openscales.proj4as.ProjPoint;
	import org.openscales.proj4as.ProjConstants;
	import org.openscales.proj4as.Datum;

	public class ProjSinu extends AbstractProjProjection {
		private var R:Number;

		public function ProjSinu(data:ProjParams) {
			super(data);
		}

		/* Initialize the Sinusoidal projection
		 ------------------------------------*/
		override public function init():void {
			/* Place parameters in static storage for common use
			 -------------------------------------------------*/
			this.R=6370997.0; //Radius of earth
		}

		/* Sinusoidal forward equations--mapping lat,long to x,y
		 -----------------------------------------------------*/
		override public function forward(p:ProjPoint):ProjPoint {
			var x:Number, y:Number, delta_lon:Number;
			var lon:Number=p.x;
			var lat:Number=p.y;
			/* Forward equations
			 -----------------*/
			delta_lon=ProjConstants.adjust_lon(lon - this.long0);
			x=this.R * delta_lon * Math.cos(lat) + this.x0;
			y=this.R * lat + this.y0;

			p.x=x;
			p.y=y;
			return p;
		}

		override public function inverse(p:ProjPoint):ProjPoint {
			var lat:Number, temp:Number, lon:Number;

			/* Inverse equations
			 -----------------*/
			p.x-=this.x0;
			p.y-=this.y0;
			lat=p.y / this.R;
			if (Math.abs(lat) > ProjConstants.HALF_PI) {
				trace("sinu:Inv:DataError");
			}
			temp=Math.abs(lat) - ProjConstants.HALF_PI;
			if (Math.abs(temp) > ProjConstants.EPSLN) {
				temp=this.long0 + p.x / (this.R * Math.cos(lat));
				lon=ProjConstants.adjust_lon(temp);
			} else {
				lon=this.long0;
			}

			p.x=lon;
			p.y=lat;
			return p;
		}


	}
}