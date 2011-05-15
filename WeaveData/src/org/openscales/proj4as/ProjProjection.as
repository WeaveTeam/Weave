package org.openscales.proj4as {
	import org.openscales.proj4as.proj.*;

	public class ProjProjection {
		/**
		 * Property: readyToUse
		 * Flag to indicate if initialization is complete for this Proj object
		 */
		public var readyToUse:Boolean=false;

		/**
		 * Property: title
		 * The title to describe the projection
		 */
		public var projParams:ProjParams=new ProjParams();

		static public const defs:Object={
			'EPSG:900913': "+title=Google Mercator EPSG:900913 +proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +no_defs",
			'WGS84': "+title=long/lat:WGS84 +proj=longlat +ellps=WGS84 +datum=WGS84 +units=degrees",
			'EPSG:4326': "+title=long/lat:WGS84 +proj=longlat +a=6378137.0 +b=6356752.31424518 +ellps=WGS84 +datum=WGS84 +units=degrees",
			'EPSG:4269': "+title=long/lat:NAD83 +proj=longlat +a=6378137.0 +b=6356752.31414036 +ellps=GRS80 +datum=NAD83 +units=degrees",
			'EPSG:27700': "+title=OSGB36/British National Grid +proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +datum=OSGB36 +units=m +no_defs",
			'EPSG:32639': "+title=WGS 84 / UTM zone 39N +proj=utm +zone=39 +ellps=WGS84 +datum=WGS84 +units=m +no_defs",
			'EPSG:28992': "+title=RD2004 +proj=sterea +lat_0=52.15616055555555 +lon_0=5.38763888888889 +k=0.999908 +x_0=155000 +y_0=463000 +ellps=bessel +units=m +towgs84=565.2369,50.0087,465.658,-0.406857330322398,0.350732676542563,-1.8703473836068,4.0812 +no_defs",
			'EPSG:2154'	: "+title=RGF93 / Lambert-93 +proj=lcc +lat_1=49 +lat_2=44 +lat_0=46.5 +lon_0=3 +x_0=700000 +y_0=6600000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs",
			
            // DGR 2009-08-27 : IGNF, Geoportal cache projections :
            'IGNF:GEOPORTALANF': "+title=Geoportail - Antilles francaises +proj=eqc +nadgrids=null +towgs84=0.0000,0.0000,0.0000 +a=6378137.0000 +rf=298.2572221010000 +lat_0=0.000000000 +lon_0=0.000000000 +lat_ts=15.000000000 +x_0=0.000 +y_0=0.000 +units=m +no_defs",
            'IGNF:GEOPORTALASP': "+title=Geoportail - Saint Paul et Amsterdam (Iles) +proj=eqc +nadgrids=null +towgs84=0.0000,0.0000,0.0000 +a=6378137.0000 +rf=298.2572221010000 +lat_0=0.000000000 +lon_0=0.000000000 +lat_ts=38.000000000 +x_0=0.000 +y_0=0.000 +units=m +no_defs",
            'IGNF:GEOPORTALCRZ': "+title=Geoportail - Crozet +proj=eqc +nadgrids=null +towgs84=0.0000,0.0000,0.0000,0.0000,0.0000,0.0000,0.000000 +a=6378137.0000 +rf=298.2572221010000 +lat_0=0.000000000 +lon_0=0.000000000 +lat_ts=-46.000000000 +x_0=0.000 +y_0=0.000 +units=m +no_defs",
            'IGNF:GEOPORTALFXX': "+title=Geoportail - France metropolitaine +proj=eqc +nadgrids=null +towgs84=0.0000,0.0000,0.0000 +a=6378137.0000 +rf=298.2572221010000 +lat_0=0.000000000 +lon_0=0.000000000 +lat_ts=46.500000000 +x_0=0.000 +y_0=0.000 +units=m +no_defs",
            'IGNF:GEOPORTALGUF': "+title=Geoportail - Guyane +proj=eqc +nadgrids=null +towgs84=0.0000,0.0000,0.0000 +a=6378137.0000 +rf=298.2572221010000 +lat_0=0.000000000 +lon_0=0.000000000 +lat_ts=4.000000000 +x_0=0.000 +y_0=0.000 +units=m +no_defs",
            'IGNF:GEOPORTALKER': "+title=Geoportail - Kerguelen +proj=eqc +nadgrids=null +towgs84=0.0000,0.0000,0.0000,0.0000,0.0000,0.0000,0.000000 +a=6378137.0000 +rf=298.2572221010000 +lat_0=0.000000000 +lon_0=0.000000000 +lat_ts=-49.500000000 +x_0=0.000 +y_0=0.000 +units=m +no_defs",
            'IGNF:GEOPORTALMYT': "+title=Geoportail - Mayotte +proj=eqc +nadgrids=null +towgs84=0.0000,0.0000,0.0000 +a=6378137.0000 +rf=298.2572221010000 +lat_0=0.000000000 +lon_0=0.000000000 +lat_ts=-12.000000000 +x_0=0.000 +y_0=0.000 +units=m +no_defs",
            'IGNF:GEOPORTALNCL': "+title=Geoportail - Nouvelle-Caledonie +proj=eqc +nadgrids=null +towgs84=0.0000,0.0000,0.0000 +a=6378137.0000 +rf=298.2572221010000 +lat_0=0.000000000 +lon_0=0.000000000 +lat_ts=-22.000000000 +x_0=0.000 +y_0=0.000 +units=m +no_defs",
            'IGNF:GEOPORTALPYF': "+title=Geoportail - Polynesie francaise +proj=eqc +nadgrids=null +towgs84=0.0000,0.0000,0.0000 +a=6378137.0000 +rf=298.2572221010000 +lat_0=0.000000000 +lon_0=0.000000000 +lat_ts=-15.000000000 +x_0=0.000 +y_0=0.000 +units=m +no_defs",
            'IGNF:GEOPORTALREU': "+title=Geoportail - Reunion et dependances +proj=eqc +nadgrids=null +towgs84=0.0000,0.0000,0.0000 +a=6378137.0000 +rf=298.2572221010000 +lat_0=0.000000000 +lon_0=0.000000000 +lat_ts=-21.000000000 +x_0=0.000 +y_0=0.000 +units=m +no_defs",
            'IGNF:GEOPORTALSPA': "+title=Geoportail - Saint-Paul et Amsterdam +proj=eqc +nadgrids=null +towgs84=0.0000,0.0000,0.0000 +a=6378137.0000 +rf=298.2572221010000 +lat_0=0.000000000 +lon_0=0.000000000 +lat_ts=-38.000000000 +x_0=0.000 +y_0=0.000 +units=m +no_defs",
            'IGNF:GEOPORTALSPM': "+title=Geoportail - Saint-Pierre et Miquelon +proj=eqc +nadgrids=null +towgs84=0.0000,0.0000,0.0000 +a=6378137.0000 +rf=298.2572221010000 +lat_0=0.000000000 +lon_0=0.000000000 +lat_ts=47.000000000 +x_0=0.000 +y_0=0.000 +units=m +no_defs",
            'IGNF:GEOPORTALWLF': "+title=Geoportail - Wallis et Futuna +proj=eqc +nadgrids=null +towgs84=0.0000,0.0000,0.0000,0.0000,0.0000,0.0000,0.000000 +a=6378137.0000 +rf=298.2572221010000 +lat_0=0.000000000 +lon_0=0.000000000 +lat_ts=-14.000000000 +x_0=0.000 +y_0=0.000 +units=m +no_defs",

            'CRS:84': "+title=WGS 84 longitude-latitude +proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
		}



		protected var proj:IProjection;

		public function get srsCode():String {
			return projParams.srsCode;
		}

		public function get srsProjNumber():String {
			return projParams.srsProjNumber;
		}

		public function get projName():String {
			return projParams.projName;
		}

		public function get datum():Datum {
			return projParams.datum;
		}

		public function get datumCode():String {
			return projParams.datumCode;
		}

		public function get from_greenwich():Number {
			return projParams.from_greenwich;
		}

		public function get to_meter():Number {
			return projParams.to_meter;
		}

		public function get a():Number {
			return projParams.a;
		}

		public function get b():Number {
			return projParams.b;
		}

		public function get ep2():Number {
			return projParams.ep2;
		}

		public function get es():Number {
			return projParams.es;
		}

		public function get datum_params():Array {
			return projParams.datum_params;
		}

		public function ProjProjection(srsCode:String) {
			this.projParams.srsCode=srsCode.toUpperCase();
			if (this.projParams.srsCode.indexOf("EPSG") == 0) {
				this.projParams.srsAuth='epsg';
				this.projParams.srsProjNumber=this.projParams.srsCode.substring(5);
					// DGR 2007-11-20 : authority IGNF
			} else if (this.projParams.srsCode.indexOf("IGNF") == 0) {
				this.projParams.srsAuth='IGNF';
				this.projParams.srsProjNumber=this.projParams.srsCode.substring(5);
					// DGR 2008-06-19 : pseudo-authority CRS for WMS
			} else if (this.projParams.srsCode.indexOf("CRS") == 0) {
				this.projParams.srsAuth='CRS';
				this.projParams.srsProjNumber=this.projParams.srsCode.substring(4);
			} else {
				this.projParams.srsAuth='';
				this.projParams.srsProjNumber=this.projParams.srsCode;
			}
			this.loadProjDefinition();
		}

		public function clone():ProjProjection {
			return new ProjProjection(this.srsCode);
		}
		
		private function loadProjDefinition():void {
			if (this.srsCode != null && ProjProjection.defs[this.srsCode] != null) {
				this.parseDef(ProjProjection.defs[this.projParams.srsCode]);
				this.initTransforms();
			}
		}

		protected function initTransforms():void {
			switch (this.projParams.projName) {
				case "aea":
					this.proj=new ProjAea(this.projParams);
					break;
				case "aeqd":
					this.proj=new ProjAeqd(this.projParams);
					break;
				case "eqc":
					this.proj=new ProjEqc(this.projParams);
					break;
				case "eqdc":
					this.proj=new ProjEqdc(this.projParams);
					break;
				case "equi":
					this.proj=new ProjEqui(this.projParams);
					break;
				case "gauss":
					this.proj=new ProjGauss(this.projParams);
					break;
				case "gstmerc":
					this.proj=new ProjGstmerc(this.projParams);
					break;
				case "laea":
					this.proj=new ProjLaea(this.projParams);
					break;
				case "lcc":
					this.proj=new ProjLcc(this.projParams);
					break;
				case "longlat":
					this.proj=new ProjLonglat(this.projParams);
					break;
				case "merc":
					this.proj=new ProjMerc(this.projParams);
					break;
				case "mill":
					this.proj=new ProjMill(this.projParams);
					break;
				case "moll":
					this.proj=new ProjMoll(this.projParams);
					break;
				case "nzmg":
					this.proj=new ProjNzmg(this.projParams);
					break;
				case "omerc":
					this.proj=new ProjOmerc(this.projParams);
					break;
				case "ortho":
					this.proj=new ProjOrtho(this.projParams);
					break;
				case "sinu":
					this.proj=new ProjSinu(this.projParams);
					break;
				case "omerc":
					this.proj=new ProjOmerc(this.projParams);
					break;
				case "stere":
					this.proj=new ProjStere(this.projParams);
					break;
				case "sterea":
					this.proj=new ProjSterea(this.projParams);
					break;
				case "tmerc":
					this.proj=new ProjTmerc(this.projParams);
					break;
				case "utm":
					this.proj=new ProjUtm(this.projParams);
					break;
				case "vandg":
					this.proj=new ProjVandg(this.projParams);
					break;
			}
			if (this.proj != null) {
				this.proj.init();
				this.readyToUse=true;
			}
		}

		private function parseDef(definition:String):void {
			var paramName:String='';
			var paramVal:String='';
			var paramArray:Array=definition.split("+");
			for (var prop:int=0; prop < paramArray.length; prop++) {
				var property:Array=paramArray[prop].split("=");
				paramName=property[0].toLowerCase();
				paramVal=property[1];

				switch (paramName.replace(/\s/gi, "")) { // trim out spaces
					case "":
						break; // throw away nameless parameter
					case "title":
						this.projParams.title=paramVal;
						break;
					case "proj":
						this.projParams.projName=paramVal.replace(/\s/gi, "");
						break;
					case "units":
						this.projParams.units=paramVal.replace(/\s/gi, "");
						break;
					case "datum":
						this.projParams.datumCode=paramVal.replace(/\s/gi, "");
						break;
					case "nadgrids":
						this.projParams.nagrids=paramVal.replace(/\s/gi, "");
						break;
					case "ellps":
						this.projParams.ellps=paramVal.replace(/\s/gi, "");
						break;
					case "a":
						this.projParams.a=parseFloat(paramVal);
						break; // semi-major radius
					case "b":
						this.projParams.b=parseFloat(paramVal);
						break; // semi-minor radius
					// DGR 2007-11-20
					case "rf":
						this.projParams.rf=parseFloat(paramVal);
						break; // inverse flattening rf= a/(a-b)
					case "lat_0":
						this.projParams.lat0=parseFloat(paramVal) * ProjConstants.D2R;
						break; // phi0, central latitude
					case "lat_1":
						this.projParams.lat1=parseFloat(paramVal) * ProjConstants.D2R;
						break; //standard parallel 1
					case "lat_2":
						this.projParams.lat2=parseFloat(paramVal) * ProjConstants.D2R;
						break; //standard parallel 2
					case "lat_ts":
						this.projParams.lat_ts=parseFloat(paramVal) * ProjConstants.D2R;
						break; // used in merc and eqc
					case "lon_0":
						this.projParams.long0=parseFloat(paramVal) * ProjConstants.D2R;
						break; // lam0, central longitude
					case "alpha":
						this.projParams.alpha=parseFloat(paramVal) * ProjConstants.D2R;
						break; //for somerc projection
					case "lonc":
						this.projParams.longc=parseFloat(paramVal) * ProjConstants.D2R;
						break; //for somerc projection
					case "x_0":
						this.projParams.x0=parseFloat(paramVal);
						break; // false easting
					case "y_0":
						this.projParams.y0=parseFloat(paramVal);
						break; // false northing
					case "k_0":
						this.projParams.k0=parseFloat(paramVal);
						break; // projection scale factor
					case "k":
						this.projParams.k0=parseFloat(paramVal);
						break; // both forms returned
					case "R_A":
						this.projParams.R_A=true;
						break; //Spheroid radius 
					case "zone":
						this.projParams.zone=parseInt(paramVal);
						break; // UTM Zone
					case "south":
						this.projParams.utmSouth=true;
						break; // UTM north/south
					case "towgs84":
						this.projParams.datum_params=paramVal.split(",");
						break;
					case "to_meter":
						this.projParams.to_meter=parseFloat(paramVal);
						break; // cartesian scaling
					case "from_greenwich":
						this.projParams.from_greenwich=parseFloat(paramVal) * ProjConstants.D2R;
						break;
					// DGR 2008-07-09 : if pm is not a well-known prime meridian take
					// the value instead of 0.0, then convert to radians
					case "pm":
						paramVal=paramVal.replace(/\s/gi, "");
						this.projParams.from_greenwich=ProjConstants.PrimeMeridian[paramVal] ? ProjConstants.PrimeMeridian[paramVal] : parseFloat(paramVal);
						this.projParams.from_greenwich*=ProjConstants.D2R;
						break;
					case "no_defs":
						break;

					// kmonico May 7, 2011: some projections obtained from epsg.org have this parameter
					case "wktext":
						break;
					
					default:
						trace("Unrecognized parameter: " + paramName);
						break;
				} // switch()
			} // for paramArray
			this.deriveConstants();
		}

		private function deriveConstants():void {
			if (this.projParams.nagrids == '@null')
				this.projParams.datumCode='none';
			if (this.projParams.datumCode && this.projParams.datumCode != 'none') {
				var datumDef:Object=ProjConstants.Datum[this.projParams.datumCode];
				if (datumDef) {
					this.projParams.datum_params=datumDef.towgs84.split(',');
					this.projParams.ellps=datumDef.ellipse;
					this.projParams.datumName=datumDef.datumName ? datumDef.datumName : this.projParams.datumCode;
				}
			}

			if (!this.projParams.a) { // do we have an ellipsoid?
				var ellipse:Object=ProjConstants.Ellipsoid[this.projParams.ellps] ? ProjConstants.Ellipsoid[this.projParams.ellps] : ProjConstants.Ellipsoid['WGS84'];
				extend(this.projParams, ellipse);
			}
			if (this.projParams.rf && !this.projParams.b)
				this.projParams.b=(1.0 - 1.0 / this.projParams.rf) * this.projParams.a;
			if (Math.abs(this.projParams.a - this.projParams.b) < ProjConstants.EPSLN) {
				this.projParams.sphere=true;
				this.projParams.b=this.projParams.a;
			}
			this.projParams.a2=this.projParams.a * this.projParams.a; // used in geocentric
			this.projParams.b2=this.projParams.b * this.projParams.b; // used in geocentric
			this.projParams.es=(this.projParams.a2 - this.projParams.b2) / this.projParams.a2; // e ^ 2
			this.projParams.e=Math.sqrt(this.projParams.es); // eccentricity
			if (this.projParams.R_A) {
				this.projParams.a*=1. - this.projParams.es * (ProjConstants.SIXTH + this.projParams.es * (ProjConstants.RA4 + this.projParams.es * ProjConstants.RA6));
				this.projParams.a2=this.projParams.a * this.projParams.a;
				this.projParams.b2=this.projParams.b * this.projParams.b;
				this.projParams.es=0.;
			}
			this.projParams.ep2=(this.projParams.a2 - this.projParams.b2) / this.projParams.b2; // used in geocentric
			if (!this.projParams.k0)
				this.projParams.k0=1.0; //default value

			this.projParams.datum=new Datum(this);
		}

		private function extend(destination:Object, source:Object):void {
			destination=destination || {};
			if (source) {
				for (var property:String in source) {
					var value:Object=source[property];
					if (value != null) {
						destination[property]=value;
					}
				}
			}
		}

		public function forward(p:ProjPoint):ProjPoint {
			if (this.proj != null) {
				return this.proj.forward(p);
			}
			return p;
		}

		public function inverse(p:ProjPoint):ProjPoint {
			if (this.proj != null) {
				return this.proj.inverse(p);
			}
			return p;
		}

	}
}
