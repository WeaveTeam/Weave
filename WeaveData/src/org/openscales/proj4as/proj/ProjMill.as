/*******************************************************************************
   NAME                    MILLER CYLINDRICAL

   PURPOSE:	Transforms input longitude and latitude to Easting and
   Northing for the Miller Cylindrical projection.  The
   longitude and latitude must be in radians.  The Easting
   and Northing values will be returned in meters.

   PROGRAMMER              DATE
   ----------              ----
   T. Mittan		March, 1993

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

	public class ProjMill extends AbstractProjProjection {
		public function ProjMill(data:ProjParams) {
			super(data);
		}

		override public function init():void {
			//no-op
		}


		/* Miller Cylindrical forward equations--mapping lat,long to x,y
		 ------------------------------------------------------------*/
		override public function forward(p:ProjPoint):ProjPoint {
			var lon:Number=p.x;
			var lat:Number=p.y;
			/* Forward equations
			 -----------------*/
			var dlon:Number=ProjConstants.adjust_lon(lon - this.long0);
			var x:Number=this.x0 + this.a * dlon;
			var y:Number=this.y0 + this.a * Math.log(Math.tan((ProjConstants.PI / 4.0) + (lat / 2.5))) * 1.25;

			p.x=x;
			p.y=y;
			return p;
		} //millFwd()

		/* Miller Cylindrical inverse equations--mapping x,y to lat/long
		 ------------------------------------------------------------*/
		override public function inverse(p:ProjPoint):ProjPoint {
			p.x-=this.x0;
			p.y-=this.y0;

			var lon:Number=ProjConstants.adjust_lon(this.long0 + p.x / this.a);
			var lat:Number=2.5 * (Math.atan(Math.exp(0.8 * p.y / this.a)) - ProjConstants.PI / 4.0);

			p.x=lon;
			p.y=lat;
			return p;
		} //millInv()		

	}
}