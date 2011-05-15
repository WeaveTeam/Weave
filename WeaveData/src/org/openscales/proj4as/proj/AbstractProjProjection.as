package org.openscales.proj4as.proj {
	import org.openscales.proj4as.ProjPoint;

	public class AbstractProjProjection extends ProjParams implements IProjection {
		protected var sinphi:Number;
		protected var cosphi:Number;
		protected var temp:Number;
		protected var e0:Number;
		protected var e1:Number;
		protected var e2:Number;
		protected var e3:Number;
		protected var sin_po:Number;
		protected var cos_po:Number;
		protected var t1:Number;
		protected var t2:Number;
		protected var t3:Number;
		protected var con:Number;
		protected var ms1:Number;
		protected var ms2:Number;
		protected var ns:Number;
		protected var ns0:Number;
		protected var qs0:Number;
		protected var qs1:Number;
		protected var qs2:Number;
		protected var c:Number;
		protected var rh:Number;
		protected var cos_phi:Number;
		protected var sin_phi:Number;
		protected var g:Number;
		protected var ml:Number;
		protected var ml0:Number;
		protected var ml1:Number;
		protected var ml2:Number;
		protected var mode:int;

		protected var cos_p12:Number;
		protected var sin_p12:Number;

		protected var rc:Number;


		public function AbstractProjProjection(data:ProjParams) {
			this.extend(data);
		}

		public function init():void {

		}

		public function forward(p:ProjPoint):ProjPoint {
			return p;
		}

		public function inverse(p:ProjPoint):ProjPoint {
			return p;
		}

		protected function extend(source:ProjParams):void {

			this.title=source.title;
			this.projName=source.projName;
			this.units=source.units;
			this.datum=source.datum;
			this.datumCode=source.datumCode;
			this.datumName=source.datumName;
			this.nagrids=source.nagrids;
			this.ellps=source.ellps;
			this.a=source.a;
			this.b=source.b;
			this.a2=source.a2;
			this.b2=source.b2;
			this.e=source.e;
			this.es=source.es;
			this.ep2=source.ep2;
			this.rf=source.rf;
			this.long0=source.long0;
			this.lat0=source.lat0;
			this.lat1=source.lat1;
			this.lat2=source.lat2;
			this.lat_ts=source.lat_ts;
			this.alpha=source.alpha;
			this.longc=source.longc;
			this.x0=source.x0;
			this.y0=source.y0;
			this.k0=source.k0;
			this.k=source.k;
			this.R_A=source.R_A;
			this.zone=source.zone;
			this.utmSouth=source.utmSouth;
			this.to_meter=source.to_meter;
			this.from_greenwich=source.from_greenwich;
			this.datum_params=source.datum_params;
			this.sphere=source.sphere;
			this.ellipseName=source.ellipseName;

			this.srsCode=source.srsCode;
			this.srsAuth=source.srsAuth;
			this.srsProjNumber=source.srsProjNumber;

		}

	}



}