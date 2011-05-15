/*******************************************************************************
   NAME                             EQUIRECTANGULAR

   PURPOSE:	Transforms input longitude and latitude to Easting and
   Northing for the Equirectangular projection.  The
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
	import org.openscales.proj4as.Datum;
	import org.openscales.proj4as.ProjConstants;
	import org.openscales.proj4as.ProjPoint;

	public class ProjEqui extends AbstractProjProjection {
		public function ProjEqui(data:ProjParams) {
			super(data);
		}



		override public function init():void {
			if (!this.x0)
				this.x0=0;
			if (!this.y0)
				this.y0=0;
			if (!this.lat0)
				this.lat0=0;
			if (!this.long0)
				this.long0=0;
			///this.t2;
		}



		/* Equirectangular forward equations--mapping lat,long to x,y
		 ---------------------------------------------------------*/
		override public function forward(p:ProjPoint):ProjPoint {

			var lon:Number=p.x;
			var lat:Number=p.y;

			var dlon:Number=ProjConstants.adjust_lon(lon - this.long0);
			var x:Number=this.x0 + this.a * dlon * Math.cos(this.lat0);
			var y:Number=this.y0 + this.a * lat;

			this.t1=x;
			this.t2=Math.cos(this.lat0);
			p.x=x;
			p.y=y;
			return p;
		} //equiFwd()



		/* Equirectangular inverse equations--mapping x,y to lat/long
		 ---------------------------------------------------------*/
		override public function inverse(p:ProjPoint):ProjPoint {

			p.x-=this.x0;
			p.y-=this.y0;
			var lat:Number=p.y / this.a;

			if (Math.abs(lat) > ProjConstants.HALF_PI) {
				trace("equi:Inv:DataError");
			}
			var lon:Number=ProjConstants.adjust_lon(this.long0 + p.x / (this.a * Math.cos(this.lat0)));
			p.x=lon;
			p.y=lat;

			return p;
		} //equiInv()

	}
}