/* Proj4as3
 *  German Osin (Gradoservice ltd.)
 *  LGPL Licencse
 *
 */


package org.openscales.proj4as {

	public class ProjConstants {

		static public const PI:Number=3.141592653589793238; //Math.PI,
		static public const HALF_PI:Number=1.570796326794896619; //Math.PI*0.5,
		static public const TWO_PI:Number=6.283185307179586477; //Math.PI*2,
		static public const FORTPI:Number=0.78539816339744833;
		static public const R2D:Number=57.29577951308232088;
		static public const D2R:Number=0.01745329251994329577;
		static public const SEC_TO_RAD:Number=4.84813681109535993589914102357e-6; /* SEC_TO_RAD = Pi/180/3600 */
		static public const EPSLN:Number=1.0e-10;
		static public const MAX_ITER:Number=20;
		// following constants from geocent.c
		static public const COS_67P5:Number=0.38268343236508977; /* cosine of 67.5 degrees */
		static public const AD_C:Number=1.0026000; /* Toms region 1 constant */

		/* datum_type values */
		static public const PJD_UNKNOWN:int=0;
		static public const PJD_3PARAM:int=1;
		static public const PJD_7PARAM:int=2;
		static public const PJD_GRIDSHIFT:int=3;
		static public const PJD_WGS84:int=4; // WGS84 or equivalent
		static public const PJD_NODATUM:int=5; // WGS84 or equivalent
		static public const SRS_WGS84_SEMIMAJOR:int=6378137; // only used in grid shift transforms

		// ellipoid pj_set_ell.c
		static public const SIXTH:Number=0.1666666666666666667; /* 1/6 */
		static public const RA4:Number=0.04722222222222222222; /* 17/360 */
		static public const RA6:Number=0.02215608465608465608; /* 67/3024 */
		static public const RV4:Number=0.06944444444444444444; /* 5/72 */
		static public const RV6:Number=0.04243827160493827160; /* 55/1296 */



		static public const PrimeMeridian:Object={"greenwich": 0.0, //"0dE",
				"lisbon": -9.131906111111, //"9d07'54.862\"W",
				"paris": 2.337229166667, //"2d20'14.025\"E",
				"bogota": -74.080916666667, //"74d04'51.3\"W",
				"madrid": -3.687938888889, //"3d41'16.58\"W",
				"rome": 12.452333333333, //"12d27'8.4\"E",
				"bern": 7.439583333333, //"7d26'22.5\"E",
				"jakarta": 106.807719444444, //"106d48'27.79\"E",
				"ferro": -17.666666666667, //"17d40'W",
				"brussels": 4.367975, //"4d22'4.71\"E",
				"stockholm": 18.058277777778, //"18d3'29.8\"E",
				"athens": 23.7163375, //"23d42'58.815\"E",
				"oslo": 10.722916666667 //"10d43'22.5\"E"
			};

		static public const Ellipsoid:Object={"MERIT": {a: 6378137.0, rf: 298.257, ellipseName: "MERIT 1983"}, "SGS85": {a: 6378136.0, rf: 298.257, ellipseName: "Soviet Geodetic System 85"}, "GRS80": {a: 6378137.0, rf: 298.257222101, ellipseName: "GRS 1980(IUGG, 1980)"}, "IAU76": {a: 6378140.0, rf: 298.257, ellipseName: "IAU 1976"}, "airy": {a: 6377563.396, b: 6356256.910, ellipseName: "Airy 1830"}, "APL4.": {a: 6378137, rf: 298.25, ellipseName: "Appl. Physics. 1965"}, "NWL9D": {a: 6378145.0, rf: 298.25, ellipseName: "Naval Weapons Lab., 1965"}, "mod_airy": {a: 6377340.189, b: 6356034.446, ellipseName: "Modified Airy"}, "andrae": {a: 6377104.43, rf: 300.0, ellipseName: "Andrae 1876 (Den., Iclnd.)"}, "aust_SA": {a: 6378160.0, rf: 298.25, ellipseName: "Australian Natl & S. Amer. 1969"}, "GRS67": {a: 6378160.0, rf: 298.2471674270, ellipseName: "GRS 67(IUGG 1967)"}, "bessel": {a: 6377397.155, rf: 299.1528128, ellipseName: "Bessel 1841"}, "bess_nam": {a: 6377483.865, rf: 299.1528128, ellipseName: "Bessel 1841 (Namibia)"}, "clrk66": {a: 6378206.4, b: 6356583.8, ellipseName: "Clarke 1866"}, "clrk80": {a: 6378249.145, rf: 293.4663, ellipseName: "Clarke 1880 mod."}, "CPM": {a: 6375738.7, rf: 334.29, ellipseName: "Comm. des Poids et Mesures 1799"}, "delmbr": {a: 6376428.0, rf: 311.5, ellipseName: "Delambre 1810 (Belgium)"}, "engelis": {a: 6378136.05, rf: 298.2566, ellipseName: "Engelis 1985"}, "evrst30": {a: 6377276.345, rf: 300.8017, ellipseName: "Everest 1830"}, "evrst48": {a: 6377304.063, rf: 300.8017, ellipseName: "Everest 1948"}, "evrst56": {a: 6377301.243, rf: 300.8017, ellipseName: "Everest 1956"}, "evrst69": {a: 6377295.664, rf: 300.8017, ellipseName: "Everest 1969"}, "evrstSS": {a: 6377298.556, rf: 300.8017, ellipseName: "Everest (Sabah & Sarawak)"}, "fschr60": {a: 6378166.0, rf: 298.3, ellipseName: "Fischer (Mercury Datum) 1960"}, "fschr60m": {a: 6378155.0, rf: 298.3, ellipseName: "Fischer 1960"}, "fschr68": {a: 6378150.0, rf: 298.3, ellipseName: "Fischer 1968"}, "helmert": {a: 6378200.0, rf: 298.3, ellipseName: "Helmert 1906"}, "hough": {a: 6378270.0, rf: 297.0, ellipseName: "Hough"}, "intl": {a: 6378388.0, rf: 297.0, ellipseName: "International 1909 (Hayford)"}, "kaula": {a: 6378163.0, rf: 298.24, ellipseName: "Kaula 1961"}, "lerch": {a: 6378139.0, rf: 298.257, ellipseName: "Lerch 1979"}, "mprts": {a: 6397300.0, rf: 191.0, ellipseName: "Maupertius 1738"}, "new_intl": {a: 6378157.5, b: 6356772.2, ellipseName: "New International 1967"}, "plessis": {a: 6376523.0, rf: 6355863.0, ellipseName: "Plessis 1817 (France)"}, "krass": {a: 6378245.0, rf: 298.3, ellipseName: "Krassovsky, 1942"}, "SEasia": {a: 6378155.0, b: 6356773.3205, ellipseName: "Southeast Asia"}, "walbeck": {a: 6376896.0, b: 6355834.8467, ellipseName: "Walbeck"}, "WGS60": {a: 6378165.0, rf: 298.3, ellipseName: "WGS 60"}, "WGS66": {a: 6378145.0, rf: 298.25, ellipseName: "WGS 66"}, "WGS72": {a: 6378135.0, rf: 298.26, ellipseName: "WGS 72"}, "WGS84": {a: 6378137.0, rf: 298.257223563, ellipseName: "WGS 84"}, "sphere": {a: 6370997.0, b: 6370997.0, ellipseName: "Normal Sphere (r=6370997)"}};

		static public const Datum:Object={"WGS84": {towgs84: "0,0,0", ellipse: "WGS84", datumName: "WGS84"}, "GGRS87": {towgs84: "-199.87,74.79,246.62", ellipse: "GRS80", datumName: "Greek_Geodetic_Reference_System_1987"}, "NAD83": {towgs84: "0,0,0", ellipse: "GRS80", datumName: "North_American_Datum_1983"}, "NAD27": {nadgrids: "@conus,@alaska,@ntv2_0.gsb,@ntv1_can.dat", ellipse: "clrk66", datumName: "North_American_Datum_1927"}, "potsdam": {towgs84: "606.0,23.0,413.0", ellipse: "bessel", datumName: "Potsdam Rauenberg 1950 DHDN"}, "carthage": {towgs84: "-263.0,6.0,431.0", ellipse: "clark80", datumName: "Carthage 1934 Tunisia"}, "hermannskogel": {towgs84: "653.0,-212.0,449.0", ellipse: "bessel", datumName: "Hermannskogel"}, "ire65": {towgs84: "482.530,-130.596,564.557,-1.042,-0.214,-0.631,8.15", ellipse: "mod_airy", datumName: "Ireland 1965"}, "nzgd49": {towgs84: "59.47,-5.04,187.44,0.47,-0.1,1.024,-4.5993", ellipse: "intl", datumName: "New Zealand Geodetic Datum 1949"}, "OSGB36": {towgs84: "446.448,-125.157,542.060,0.1502,0.2470,0.8421,-20.4894", ellipse: "airy", datumName: "Airy 1830"}};



		public function ProjConstants() {
		}


		// Function to compute the constant small m which is the radius of
		//   a parallel of latitude, phi, divided by the semimajor axis.
		// -----------------------------------------------------------------
		static public function msfnz(eccent:Number, sinphi:Number, cosphi:Number):Number {
			var con:Number=eccent * sinphi;
			return cosphi / (Math.sqrt(1.0 - con * con));
		}

		// Function to compute the constant small t for use in the forward
		//   computations in the Lambert Conformal Conic and the Polar
		//   Stereographic projections.
		// -----------------------------------------------------------------
		static public function tsfnz(eccent:Number, phi:Number, sinphi:Number):Number {
			var con:Number=eccent * sinphi;
			var com:Number=0.5 * eccent;
			con=Math.pow(((1.0 - con) / (1.0 + con)), com);
			return (Math.tan(0.5 * (ProjConstants.HALF_PI - phi)) / con);
		}

		// Function to compute the latitude angle, phi2, for the inverse of the
		//   Lambert Conformal Conic and Polar Stereographic projections.
		// ----------------------------------------------------------------
		static public function phi2z(eccent:Number, ts:Number):Number {
			var eccnth:Number=.5 * eccent;
			var con:Number=0;
			var dphi:Number=0;
			var phi:Number=ProjConstants.HALF_PI - 2 * Math.atan(ts);
			for (var i:int=0; i <= 15; i++) {
				con=eccent * Math.sin(phi);
				dphi=ProjConstants.HALF_PI - 2 * Math.atan(ts * (Math.pow(((1.0 - con) / (1.0 + con)), eccnth))) - phi;
				phi+=dphi;
				if (Math.abs(dphi) <= .0000000001)
					return phi;
			}
			trace("phi2z has NoConvergence");
			return -9999;
		}

		/* Function to compute constant small q which is the radius of a
		   parallel of latitude, phi, divided by the semimajor axis.
		 ------------------------------------------------------------*/
		static public function qsfnz(eccent:Number, sinphi:Number, cosphi:Number):Number {
			var con:Number=0;
			if (eccent > 1.0e-7) {
				con=eccent * sinphi;
				return ((1.0 - eccent * eccent) * (sinphi / (1.0 - con * con) - (.5 / eccent) * Math.log((1.0 - con) / (1.0 + con))));
			} else {
				return 2.0 * sinphi;
			}
		}

		/* Function to eliminate roundoff errors in asin
		 ----------------------------------------------*/
		static public function asinz(x:Number):Number {
			if (Math.abs(x) > 1.0) {
				x=(x > 1.0) ? 1.0 : -1.0;
			}
			return Math.asin(x);
		}

		// following functions from gctpc cproj.c for transverse mercator projections
		static public function e0fn(x:Number):Number {
			return (1.0 - 0.25 * x * (1.0 + x / 16.0 * (3.0 + 1.25 * x)));
		}

		static public function e1fn(x:Number):Number {
			return (0.375 * x * (1.0 + 0.25 * x * (1.0 + 0.46875 * x)));
		}

		static public function e2fn(x:Number):Number {
			return (0.05859375 * x * x * (1.0 + 0.75 * x));
		}

		static public function e3fn(x:Number):Number {
			return (x * x * x * (35.0 / 3072.0));
		}

		static public function mlfn(e0:Number, e1:Number, e2:Number, e3:Number, phi:Number):Number {
			return (e0 * phi - e1 * Math.sin(2.0 * phi) + e2 * Math.sin(4.0 * phi) - e3 * Math.sin(6.0 * phi));
		}

		static public function srat(esinp:Number, exp:Number):Number {
			return (Math.pow((1.0 - esinp) / (1.0 + esinp), exp));
		}

// Function to return the sign of an argument
		static public function sign(x:Number):Number {
			if (x < 0.0)
				return (-1);
			else
				return (1);
		}

// Function to adjust longitude to -180 to 180; input in radians
// revised by KM on Feb 10, 2011--range includes -PI and +PI
		static public function adjust_lon(x:Number):Number {
			x=(Math.abs(x) <= ProjConstants.PI) ? x : (x - (ProjConstants.sign(x) * ProjConstants.TWO_PI));
			return x;
		}

// IGNF - DGR : algorithms used by IGN France

// Function to adjust latitude to -90 to 90; input in radians
// revised by KM on Feb 10, 2011--range includes -PI and +PI
		static public function adjust_lat(x:Number):Number {
			x=(Math.abs(x) <= ProjConstants.HALF_PI) ? x : (x - (ProjConstants.sign(x) * ProjConstants.PI));
			return x;
		}

// Latitude Isometrique - close to tsfnz ...
		static public function latiso(eccent:Number, phi:Number, sinphi:Number):Number {
			if (Math.abs(phi) > ProjConstants.HALF_PI)
				return +Number.NaN;
			if (phi == ProjConstants.HALF_PI)
				return Number.POSITIVE_INFINITY;
			if (phi == -1.0 * ProjConstants.HALF_PI)
				return -1.0 * Number.POSITIVE_INFINITY;

			var con:Number=eccent * sinphi;
			return Math.log(Math.tan((ProjConstants.HALF_PI + phi) / 2.0)) + eccent * Math.log((1.0 - con) / (1.0 + con)) / 2.0;
		}

		static public function fL(x:Number, L:Number):Number {
			return 2.0 * Math.atan(x * Math.exp(L)) - ProjConstants.HALF_PI;
		}

// Inverse Latitude Isometrique - close to ph2z
		static public function invlatiso(eccent:Number, ts:Number):Number {
			var phi:Number=ProjConstants.fL(1.0, ts);
			var Iphi:Number=0.0;
			var con:Number=0.0;
			do {
				Iphi=phi;
				con=eccent * Math.sin(Iphi);
				phi=ProjConstants.fL(Math.exp(eccent * Math.log((1.0 + con) / (1.0 - con)) / 2.0), ts)
			} while (Math.abs(phi - Iphi) > 1.0e-12);
			return phi;
		}

// Needed for Gauss Laborde
// Original:  Denis Makarov (info@binarythings.com)
// Web Site:  http://www.binarythings.com
		static public function sinh(x:Number):Number {
			var r:Number=Math.exp(x);
			r=(r - 1.0 / r) / 2.0;
			return r;
		}

		static public function cosh(x:Number):Number {
			var r:Number=Math.exp(x);
			r=(r + 1.0 / r) / 2.0;
			return r;
		}

		static public function tanh(x:Number):Number {
			var r:Number=Math.exp(x);
			r=(r - 1.0 / r) / (r + 1.0 / r);
			return r;
		}

		static public function asinh(x:Number):Number {
			var s:Number=(x >= 0 ? 1.0 : -1.0);
			return s * (Math.log(Math.abs(x) + Math.sqrt(x * x + 1.0)));
		}

		static public function acosh(x:Number):Number {
			return 2.0 * Math.log(Math.sqrt((x + 1.0) / 2.0) + Math.sqrt((x - 1.0) / 2.0));
		}

		static public function atanh(x:Number):Number {
			return Math.log((x - 1.0) / (x + 1.0)) / 2.0;
		}

// Grande Normale
		static public function gN(a:Number, e:Number, sinphi:Number):Number {
			var temp:Number=e * sinphi;
			return a / Math.sqrt(1.0 - temp * temp);
		}


	}
}