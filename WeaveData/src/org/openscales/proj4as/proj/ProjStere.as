package org.openscales.proj4as.proj {
	import org.openscales.proj4as.ProjPoint;
	import org.openscales.proj4as.ProjConstants;
	import org.openscales.proj4as.Datum;

	public class ProjStere extends AbstractProjProjection {
		private const TOL:Number=1.e-8;
		private const NITER:Number=8;
		private const CONV:Number=1.e-10;
		private const S_POLE:Number=0;
		private const N_POLE:Number=1;
		private const OBLIQ:Number=2;
		private const EQUIT:Number=3;

		private var akm1:Number;
		private var cosph0:Number;
		private var cosX1:Number;
		private var sinX1:Number;
		private var phi0:Number;
		private var phits:Number;
		private var sinph0:Number;

		public function ProjStere(data:ProjParams) {
			super(data);
		}

		private function ssfn_(phit:Number, sinphi:Number, eccen:Number):Number {
			sinphi*=eccen;
			return (Math.tan(.5 * (ProjConstants.HALF_PI + phit)) * Math.pow((1. - sinphi) / (1. + sinphi), .5 * eccen));
		}


		override public function init():void {
			this.phits=this.lat_ts ? this.lat_ts : ProjConstants.HALF_PI;
			var t:Number=Math.abs(this.lat0);
			if ((Math.abs(t) - ProjConstants.HALF_PI) < ProjConstants.EPSLN) {
				this.mode=this.lat0 < 0. ? this.S_POLE : this.N_POLE;
			} else {
				this.mode=t > ProjConstants.EPSLN ? this.OBLIQ : this.EQUIT;
			}
			this.phits=Math.abs(this.phits);
			if (this.es) {
				var X:Number;

				switch (this.mode) {
					case this.N_POLE:
					case this.S_POLE:
						if (Math.abs(this.phits - ProjConstants.HALF_PI) < ProjConstants.EPSLN) {
							this.akm1=2. * this.k0 / Math.sqrt(Math.pow(1 + this.e, 1 + this.e) * Math.pow(1 - this.e, 1 - this.e));
						} else {
							t=Math.sin(this.phits);
							this.akm1=Math.cos(this.phits) / ProjConstants.tsfnz(this.e, this.phits, t);
							t*=this.e;
							this.akm1/=Math.sqrt(1. - t * t);
						}
						break;
					case this.EQUIT:
						this.akm1=2. * this.k0;
						break;
					case this.OBLIQ:
						t=Math.sin(this.lat0);
						X=2. * Math.atan(this.ssfn_(this.lat0, t, this.e)) - ProjConstants.HALF_PI;
						t*=this.e;
						this.akm1=2. * this.k0 * Math.cos(this.lat0) / Math.sqrt(1. - t * t);
						this.sinX1=Math.sin(X);
						this.cosX1=Math.cos(X);
						break;
				}
			} else {
				switch (this.mode) {
					case this.OBLIQ:
						this.sinph0=Math.sin(this.lat0);
						this.cosph0=Math.cos(this.lat0);
					case this.EQUIT:
						this.akm1=2. * this.k0;
						break;
					case this.S_POLE:
					case this.N_POLE:
						this.akm1=Math.abs(this.phits - ProjConstants.HALF_PI) >= ProjConstants.EPSLN ? Math.cos(this.phits) / Math.tan(ProjConstants.FORTPI - .5 * this.phits) : 2. * this.k0;
						break;
				}
			}
		}

		// Stereographic forward equations--mapping lat,long to x,y
		override public function forward(p:ProjPoint):ProjPoint {
			var lon:Number=p.x;
			var lat:Number=p.y;
			var x:Number, y:Number, A:Number, X:Number;
			var sinX:Number, cosX:Number;

			if (this.sphere) {
				var sinphi:Number, cosphi:Number, coslam:Number, sinlam:Number;

				sinphi=Math.sin(lat);
				cosphi=Math.cos(lat);
				coslam=Math.cos(lon);
				sinlam=Math.sin(lon);
				switch (this.mode) {
					case this.EQUIT:
						y=1. + cosphi * coslam;
						if (y <= ProjConstants.EPSLN) {
							trace('ERROR');
								//F_ERROR;
						}
						y=this.akm1 / y;
						x=y * cosphi * sinlam;
						y*=sinphi;
						break;
					case this.OBLIQ:
						y=1. + this.sinph0 * sinphi + this.cosph0 * cosphi * coslam;
						if (y <= ProjConstants.EPSLN) {
							trace('ERROR');
								//F_ERROR;
						}
						y=this.akm1 / y;
						x=y * cosphi * sinlam;
						y*=this.cosph0 * sinphi - this.sinph0 * cosphi * coslam;
						break;
					case this.N_POLE:
						coslam=-coslam;
						lat=-lat;
					//Note  no break here so it conitnues through S_POLE
					case this.S_POLE:
						if (Math.abs(lat - ProjConstants.HALF_PI) < this.TOL) {
							trace('ERROR');
								//F_ERROR;
						}
						y=this.akm1 * Math.tan(ProjConstants.FORTPI + .5 * lat)
						x=sinlam * y;
						y*=coslam;
						break;
				}
			} else {
				coslam=Math.cos(lon);
				sinlam=Math.sin(lon);
				sinphi=Math.sin(lat);
				if (this.mode == this.OBLIQ || this.mode == this.EQUIT) {
					X=2. * Math.atan(this.ssfn_(lat, sinphi, this.e));
					sinX=Math.sin(X - ProjConstants.HALF_PI);
					cosX=Math.cos(X);
				}
				switch (this.mode) {
					case this.OBLIQ:
						A=this.akm1 / (this.cosX1 * (1. + this.sinX1 * sinX + this.cosX1 * cosX * coslam));
						y=A * (this.cosX1 * sinX - this.sinX1 * cosX * coslam);
						x=A * cosX;
						break;
					case this.EQUIT:
						A=2. * this.akm1 / (1. + cosX * coslam);
						y=A * sinX;
						x=A * cosX;
						break;
					case this.S_POLE:
						lat=-lat;
						coslam=-coslam;
						sinphi=-sinphi;
					case this.N_POLE:
						x=this.akm1 * ProjConstants.tsfnz(this.e, lat, sinphi);
						y=-x * coslam;
						break;
				}
				x=x * sinlam;
			}
			p.x=x * this.a + this.x0;
			p.y=y * this.a + this.y0;
			return p;
		}


		//* Stereographic inverse equations--mapping x,y to lat/long
		override public function inverse(p:ProjPoint):ProjPoint {
			var x:Number=(p.x - this.x0) / this.a; /* descale and de-offset */
			var y:Number=(p.y - this.y0) / this.a;
			var lon:Number, lat:Number;

			var cosphi:Number, sinphi:Number, tp:Number=0.0, phi_l:Number=0.0, rho:Number, halfe:Number=0.0, pi2:Number=0.0;
			var i:int;

			if (this.sphere) {
				var c:Number, rh:Number, sinc:Number, cosc:Number;

				rh=Math.sqrt(x * x + y * y);
				c=2. * Math.atan(rh / this.akm1);
				sinc=Math.sin(c);
				cosc=Math.cos(c);
				lon=0.;
				switch (this.mode) {
					case this.EQUIT:
						if (Math.abs(rh) <= ProjConstants.EPSLN) {
							lat=0.;
						} else {
							lat=Math.asin(y * sinc / rh);
						}
						if (cosc != 0. || x != 0.)
							lon=Math.atan2(x * sinc, cosc * rh);
						break;
					case this.OBLIQ:
						if (Math.abs(rh) <= ProjConstants.EPSLN) {
							lat=this.phi0;
						} else {
							lat=Math.asin(cosc * sinph0 + y * sinc * cosph0 / rh);
						}
						c=cosc - sinph0 * Math.sin(lat);
						if (c != 0. || x != 0.) {
							lon=Math.atan2(x * sinc * cosph0, c * rh);
						}
						break;
					case this.N_POLE:
						y=-y;
					case this.S_POLE:
						if (Math.abs(rh) <= ProjConstants.EPSLN) {
							lat=this.phi0;
						} else {
							lat=Math.asin(this.mode == this.S_POLE ? -cosc : cosc);
						}
						lon=(x == 0. && y == 0.) ? 0. : Math.atan2(x, y);
						break;
				}
			} else {
				rho=Math.sqrt(x * x + y * y);
				switch (this.mode) {
					case this.OBLIQ:
					case this.EQUIT:
						tp=2. * Math.atan2(rho * this.cosX1, this.akm1);
						cosphi=Math.cos(tp);
						sinphi=Math.sin(tp);
						if (rho == 0.0) {
							phi_l=Math.asin(cosphi * this.sinX1);
						} else {
							phi_l=Math.asin(cosphi * this.sinX1 + (y * sinphi * this.cosX1 / rho));
						}

						tp=Math.tan(.5 * (ProjConstants.HALF_PI + phi_l));
						x*=sinphi;
						y=rho * this.cosX1 * cosphi - y * this.sinX1 * sinphi;
						pi2=ProjConstants.HALF_PI;
						halfe=.5 * this.e;
						break;
					case this.N_POLE:
						y=-y;
					case this.S_POLE:
						tp=-rho / this.akm1
						phi_l=ProjConstants.HALF_PI - 2. * Math.atan(tp);
						pi2=-ProjConstants.HALF_PI;
						halfe=-.5 * this.e;
						break;
				}
				for (i=this.NITER; i--; phi_l=lat) { //check this
					sinphi=this.e * Math.sin(phi_l);
					lat=2. * Math.atan(tp * Math.pow((1. + sinphi) / (1. - sinphi), halfe)) - pi2;
					if (Math.abs(phi_l - lat) < this.CONV) {
						if (this.mode == this.S_POLE)
							lat=-lat;
						lon=(x == 0. && y == 0.) ? 0. : Math.atan2(x, y);
						p.x=lon;
						p.y=lat
						return p;
					}
				}
			}
			return null;
		}




	}
}