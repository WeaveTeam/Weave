/*******************************************************************************
   NAME                       SWISS OBLIQUE MERCATOR

   PURPOSE:	Swiss projection.
   WARNING:  X and Y are inverted (weird) in the swiss coordinate system. Not
   here, since we want X to be horizontal and Y vertical.

   ALGORITHM REFERENCES
   1. "Formules et constantes pour le Calcul pour la
   projection cylindrique conforme Г  axe oblique et pour la transformation entre
   des systГЁmes de rГ©fГ©rence".
   http://www.swisstopo.admin.ch/internet/swisstopo/fr/home/topics/survey/sys/refsys/switzerland.parsysrelated1.31216.downloadList.77004.DownloadFile.tmp/swissprojectionfr.pdf

 *******************************************************************************/


package org.openscales.proj4as.proj {
	import org.openscales.proj4as.ProjPoint;
	import org.openscales.proj4as.ProjConstants;
	import org.openscales.proj4as.Datum;

	public class ProjSoMerc extends AbstractProjProjection {
		private var lambda0:Number;
		private var R:Number;
		private var b0:Number;
		private var K:Number;


		public function ProjSoMerc(data:ProjParams) {
			super(data);
		}


		override public function init():void {
			var phy0:Number=this.lat0;
			this.lambda0=this.long0;
			var sinPhy0:Number=Math.sin(phy0);
			var semiMajorAxis:Number=this.a;
			var invF:Number=this.rf;
			var flattening:Number=1 / invF;
			var e2:Number=2 * flattening - Math.pow(flattening, 2);
			var e:Number=this.e=Math.sqrt(e2);
			this.R=semiMajorAxis * Math.sqrt(1 - e2) / (1 - e2 * Math.pow(sinPhy0, 2.0));
			this.alpha=Math.sqrt(1 + e2 / (1 - e2) * Math.pow(Math.cos(phy0), 4.0));
			this.b0=Math.asin(sinPhy0 / this.alpha);
			this.K=Math.log(Math.tan(Math.PI / 4.0 + this.b0 / 2.0)) - this.alpha * Math.log(Math.tan(Math.PI / 4.0 + phy0 / 2.0)) + this.alpha * e / 2 * Math.log((1 + e * sinPhy0) / (1 - e * sinPhy0));
		}


		override public function forward(p:ProjPoint):ProjPoint {
			var Sa1:Number=Math.log(Math.tan(Math.PI / 4.0 - p.y / 2.0));
			var Sa2:Number=this.e / 2.0 * Math.log((1 + this.e * Math.sin(p.y)) / (1 - this.e * Math.sin(p.y)));
			var S:Number=-this.alpha * (Sa1 + Sa2) + this.K;

			// spheric latitude
			var b:Number=2.0 * (Math.atan(Math.exp(S)) - Math.PI / 4.0);

			// spheric longitude
			var I:Number=this.alpha * (p.x - this.lambda0);

			// psoeudo equatorial rotation
			var rotI:Number=Math.atan(Math.sin(I) / (Math.sin(this.b0) * Math.tan(b) + Math.cos(this.b0) * Math.cos(I)));

			var rotB:Number=Math.asin(Math.cos(this.b0) * Math.sin(b) - Math.sin(this.b0) * Math.cos(b) * Math.cos(I));

			p.y=this.R / 2.0 * Math.log((1 + Math.sin(rotB)) / (1 - Math.sin(rotB))) + this.y0;
			p.x=this.R * rotI + this.x0;
			return p;
		}

		override public function inverse(p:ProjPoint):ProjPoint {
			var Y:Number=p.x - this.x0;
			var X:Number=p.y - this.y0;

			var rotI:Number=Y / this.R;
			var rotB:Number=2 * (Math.atan(Math.exp(X / this.R)) - Math.PI / 4.0);

			var b:Number=Math.asin(Math.cos(this.b0) * Math.sin(rotB) + Math.sin(this.b0) * Math.cos(rotB) * Math.cos(rotI));
			var I:Number=Math.atan(Math.sin(rotI) / (Math.cos(this.b0) * Math.cos(rotI) - Math.sin(this.b0) * Math.tan(rotB)));

			var lambda:Number=this.lambda0 + I / this.alpha;

			var S:Number=0.0;
			var phy:Number=b;
			var prevPhy:Number=-1000.0;
			var iteration:Number=0;
			while (Math.abs(phy - prevPhy) > 0.0000001) {
				if (++iteration > 20) {
					trace("omercFwdInfinity");
					return null;
				}
				//S = Math.log(Math.tan(Math.PI / 4.0 + phy / 2.0));
				S=1.0 / this.alpha * (Math.log(Math.tan(Math.PI / 4.0 + b / 2.0)) - this.K) + this.e * Math.log(Math.tan(Math.PI / 4.0 + Math.asin(this.e * Math.sin(phy)) / 2.0));
				prevPhy=phy;
				phy=2.0 * Math.atan(Math.exp(S)) - Math.PI / 2.0;
			}

			p.x=lambda;
			p.y=phy;
			return p;
		}


	}
}