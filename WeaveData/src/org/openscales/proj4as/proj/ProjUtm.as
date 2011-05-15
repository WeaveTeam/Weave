/*******************************************************************************
   NAME                            TRANSVERSE MERCATOR

   PURPOSE:	Transforms input longitude and latitude to Easting and
   Northing for the Transverse Mercator projection.  The
   longitude and latitude must be in radians.  The Easting
   and Northing values will be returned in meters.

   ALGORITHM REFERENCES

   1.  Snyder, John P., "Map Projections--A Working Manual", U.S. Geological
   Survey Professional Paper 1395 (Supersedes USGS Bulletin 1532), United
   State Government Printing Office, Washington D.C., 1987.

   2.  Snyder, John P. and Voxland, Philip M., "An Album of Map Projections",
   U.S. Geological Survey Professional Paper 1453 , United State Government
   Printing Office, Washington D.C., 1989.
 *******************************************************************************/


package org.openscales.proj4as.proj {
	import org.openscales.proj4as.ProjConstants;
	import org.openscales.proj4as.Datum;

	public class ProjUtm extends ProjTmerc {
		public function ProjUtm(data:ProjParams) {
			super(data);
		}

		override public function init():void {
			if (!this.zone) {
				trace("utm:init: zone must be specified for UTM");
				return;
			}
			this.lat0=0.0;
			this.long0=((6 * Math.abs(this.zone)) - 183) * ProjConstants.D2R;
			this.x0=500000.0;
			this.y0=this.utmSouth ? 10000000.0 : 0.0;
			this.k0=0.9996;

			super.init();
		}


	}
}