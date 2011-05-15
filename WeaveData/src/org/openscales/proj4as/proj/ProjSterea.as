package org.openscales.proj4as.proj {
	import org.openscales.proj4as.ProjPoint;
	import org.openscales.proj4as.ProjConstants;
	import org.openscales.proj4as.Datum;

	public class ProjSterea extends ProjGauss {

		protected var sinc0:Number;
		protected var cosc0:Number;
		protected var R2:Number;

		public function ProjSterea(data:ProjParams) {
			super(data);
		}

		override public function init():void {
			super.init();
			if (!this.rc) {
				trace("sterea:init:E_ERROR_0");
				return;
			}
			this.sinc0=Math.sin(this.phic0);
			this.cosc0=Math.cos(this.phic0);
			this.R2=2.0 * this.rc;
			if (!this.title)
				this.title="Oblique Stereographic Alternative";
		}

		override public function forward(p:ProjPoint):ProjPoint {
			p.x=ProjConstants.adjust_lon(p.x - this.long0); /* adjust del longitude */
			super.forward(p);
			var sinc:Number=Math.sin(p.y);
			var cosc:Number=Math.cos(p.y);
			var cosl:Number=Math.cos(p.x);
			k=this.k0 * this.R2 / (1.0 + this.sinc0 * sinc + this.cosc0 * cosc * cosl);
			p.x=k * cosc * Math.sin(p.x);
			p.y=k * (this.cosc0 * sinc - this.sinc0 * cosc * cosl);
			p.x=this.a * p.x + this.x0;
			p.y=this.a * p.y + this.y0;
			return p;
		}

		override public function inverse(p:ProjPoint):ProjPoint {
			var lon:Number, lat:Number, rho:Number, sinc:Number, cosc:Number;
			p.x=(p.x - this.x0) / this.a; /* descale and de-offset */
			p.y=(p.y - this.y0) / this.a;

			p.x/=this.k0;
			p.y/=this.k0;
			if ((rho=Math.sqrt(p.x * p.x + p.y * p.y))) {
				c=2.0 * Math.atan2(rho, this.R2);
				sinc=Math.sin(c);
				cosc=Math.cos(c);
				lat=Math.asin(cosc * this.sinc0 + p.y * sinc * this.cosc0 / rho);
				lon=Math.atan2(p.x * sinc, rho * this.cosc0 * cosc - p.y * this.sinc0 * sinc);
			} else {
				lat=this.phic0;
				lon=0.;
			}

			p.x=lon;
			p.y=lat;
			super.inverse(p);
			p.x=ProjConstants.adjust_lon(p.x + this.long0); /* adjust longitude to CM */
			return p;
		}

	}
}