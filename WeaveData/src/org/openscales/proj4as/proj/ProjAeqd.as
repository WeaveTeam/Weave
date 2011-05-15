package org.openscales.proj4as.proj {
	import org.openscales.proj4as.ProjPoint;
	import org.openscales.proj4as.ProjConstants;
	import org.openscales.proj4as.Datum;

	public class ProjAeqd extends AbstractProjProjection {
		public function ProjAeqd(data:ProjParams) {
			super(data);
		}

		override public function init():void {
			this.sin_p12=Math.sin(this.lat0)
			this.cos_p12=Math.cos(this.lat0)
		}

		override public function forward(p:ProjPoint):ProjPoint {
			var lon:Number=p.x;
			var lat:Number=p.y;
			var ksp:Number;

			var sinphi:Number=Math.sin(p.y);
			var cosphi:Number=Math.cos(p.y);
			var dlon:Number=ProjConstants.adjust_lon(lon - this.long0);
			var coslon:Number=Math.cos(dlon);
			var g:Number=this.sin_p12 * sinphi + this.cos_p12 * cosphi * coslon;
			if (Math.abs(Math.abs(g) - 1.0) < ProjConstants.EPSLN) {
				ksp=1.0;
				if (g < 0.0) {
					trace("aeqd:Fwd:PointError");
					return null;
				}
			} else {
				var z:Number=Math.acos(g);
				ksp=z / Math.sin(z);
			}
			p.x=this.x0 + this.a * ksp * cosphi * Math.sin(dlon);
			p.y=this.y0 + this.a * ksp * (this.cos_p12 * sinphi - this.sin_p12 * cosphi * coslon);
			return p;
		}

		override public function inverse(p:ProjPoint):ProjPoint {
			p.x-=this.x0;
			p.y-=this.y0;

			var rh:Number=Math.sqrt(p.x * p.x + p.y * p.y);
			if (rh > (2.0 * ProjConstants.HALF_PI * this.a)) {
				trace("aeqdInvDataError");
				return null;
			}
			var z:Number=rh / this.a;

			var sinz:Number=Math.sin(z)
			var cosz:Number=Math.cos(z)

			var lon:Number=this.long0;
			var lat:Number;
			if (Math.abs(rh) <= ProjConstants.EPSLN) {
				lat=this.lat0;
			} else {
				lat=ProjConstants.asinz(cosz * this.sin_p12 + (p.y * sinz * this.cos_p12) / rh);
				var con:Number=Math.abs(this.lat0) - ProjConstants.HALF_PI;
				if (Math.abs(con) <= ProjConstants.EPSLN) {
					if (lat0 >= 0.0) {
						lon=ProjConstants.adjust_lon(this.long0 + Math.atan2(p.x, -p.y));
					} else {
						lon=ProjConstants.adjust_lon(this.long0 - Math.atan2(-p.x, p.y));
					}
				} else {
					con=cosz - this.sin_p12 * Math.sin(lat);
					if ((Math.abs(con) < ProjConstants.EPSLN) && (Math.abs(p.x) < ProjConstants.EPSLN)) {
						//no-op, just keep the lon value as is
					} else {
						var temp:Number=Math.atan2((p.x * sinz * this.cos_p12), (con * rh));
						lon=ProjConstants.adjust_lon(this.long0 + Math.atan2((p.x * sinz * this.cos_p12), (con * rh)));
					}
				}
			}

			p.x=lon;
			p.y=lat;
			return p;
		}


	}
}