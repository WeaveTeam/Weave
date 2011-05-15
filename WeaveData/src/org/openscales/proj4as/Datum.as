package org.openscales.proj4as {
	import org.openscales.proj4as.proj.AbstractProjProjection;
	import org.openscales.proj4as.ProjConstants;

	public class Datum {
		public var datum_type:int;
		public var a:Number;
		public var b:Number;
		public var es:Number;
		public var ep2:Number;
		public var datum_params:Array;
		public var params:Array;

		public function Datum(proj:ProjProjection) {
			this.datum_type=ProjConstants.PJD_WGS84; //default setting
			if (proj.datumCode && proj.datumCode == 'none') {
				this.datum_type=ProjConstants.PJD_NODATUM;
			}
			if (proj && proj.datum_params) {
				for (var i:int=0; i < proj.datum_params.length; i++) {
					proj.datum_params[i]=parseFloat(proj.datum_params[i]);
				}
				if (proj.datum_params[0] != 0 || proj.datum_params[1] != 0 || proj.datum_params[2] != 0) {
					this.datum_type=ProjConstants.PJD_3PARAM;
				}
				if (proj.datum_params.length > 3) {
					if (proj.datum_params[3] != 0 || proj.datum_params[4] != 0 || proj.datum_params[5] != 0 || proj.datum_params[6] != 0) {
						this.datum_type=ProjConstants.PJD_7PARAM;
						proj.datum_params[3]*=ProjConstants.SEC_TO_RAD;
						proj.datum_params[4]*=ProjConstants.SEC_TO_RAD;
						proj.datum_params[5]*=ProjConstants.SEC_TO_RAD;
						proj.datum_params[6]=(proj.datum_params[6] / 1000000.0) + 1.0;
					}
				}
			}
			if (proj) {
				this.a=proj.a; //datum object also uses these values
				this.b=proj.b;
				this.es=proj.es;
				this.ep2=proj.ep2;
				this.datum_params=proj.datum_params;
			}
		}

		/****************************************************************/
		// cs_compare_datums()
		//   Returns 1 (TRUE) if the two datums match, otherwise 0 (FALSE).
		public function compare_datums(dest:Datum):Boolean {
			if (this.datum_type != dest.datum_type) {
				return false; // false, datums are not equal
			} else if (this.a != dest.a || Math.abs(this.es - dest.es) > 0.000000000050) {
				// the tolerence for es is to ensure that GRS80 and WGS84
				// are considered identical
				return false;
			} else if (this.datum_type == ProjConstants.PJD_3PARAM) {
				return (this.datum_params[0] == dest.datum_params[0] && this.datum_params[1] == dest.datum_params[1] && this.datum_params[2] == dest.datum_params[2]);
			} else if (this.datum_type == ProjConstants.PJD_7PARAM) {
				return (this.datum_params[0] == dest.datum_params[0] && this.datum_params[1] == dest.datum_params[1] && this.datum_params[2] == dest.datum_params[2] && this.datum_params[3] == dest.datum_params[3] && this.datum_params[4] == dest.datum_params[4] && this.datum_params[5] == dest.datum_params[5] && this.datum_params[6] == dest.datum_params[6]);
			} else if (this.datum_type == ProjConstants.PJD_GRIDSHIFT) {
				/*return strcmp( pj_param(this.params,"snadgrids").s,
				 pj_param(dest.params,"snadgrids").s ) == 0; */
				return false;
			} else {
				return true; // datums are equal
			}
		} // cs_compare_datums()


		public function geodetic_to_geocentric(p:ProjPoint):int {
			var Longitude:Number=p.x;
			var Latitude:Number=p.y;
			var Height:Number=p.z ? p.z : 0; //Z value not always supplied
			var X:Number; // output
			var Y:Number;
			var Z:Number;

			var Error_Code:int=0; //  GEOCENT_NO_ERROR;
			var Rn:Number; /*  Earth radius at location  */
			var Sin_Lat:Number; /*  Math.sin(Latitude)  */
			var Sin2_Lat:Number; /*  Square of Math.sin(Latitude)  */
			var Cos_Lat:Number; /*  Math.cos(Latitude)  */

			/*
			 ** Don't blow up if Latitude is just a little out of the value
			 ** range as it may just be a rounding issue.  Also removed longitude
			 ** test, it should be wrapped by Math.cos() and Math.sin().  NFW for PROJ.4, Sep/2001.
			 */
			if (Latitude < -ProjConstants.HALF_PI && Latitude > -1.001 * ProjConstants.HALF_PI) {
				Latitude=-ProjConstants.HALF_PI;
			} else if (Latitude > ProjConstants.HALF_PI && Latitude < 1.001 * ProjConstants.HALF_PI) {
				Latitude=ProjConstants.HALF_PI;
			} else if ((Latitude < -ProjConstants.HALF_PI) || (Latitude > ProjConstants.HALF_PI)) {
				/* Latitude out of range */
				trace('geocent:lat out of range:' + Latitude);
				return 0;
			}

			if (Longitude > ProjConstants.PI) {
				Longitude-=(2 * ProjConstants.PI);
			}
			Sin_Lat=Math.sin(Latitude);
			Cos_Lat=Math.cos(Latitude);
			Sin2_Lat=Sin_Lat * Sin_Lat;
			Rn=this.a / (Math.sqrt(1.0e0 - this.es * Sin2_Lat));
			X=(Rn + Height) * Cos_Lat * Math.cos(Longitude);
			Y=(Rn + Height) * Cos_Lat * Math.sin(Longitude);
			Z=((Rn * (1 - this.es)) + Height) * Sin_Lat;

			p.x=X;
			p.y=Y;
			p.z=Z;
			return Error_Code;
		} // cs_geodetic_to_geocentric()


		public function geocentric_to_geodetic(p:ProjPoint):ProjPoint {
			/* local defintions and variables */ /* end-criterium of loop, accuracy of sin(Latitude) */
			var genau:Number=1.E-12;
			var genau2:Number=(genau * genau);
			var maxiter:int=30;

			var P:Number; /* distance between semi-minor axis and location */
			var RR:Number; /* distance between center and location */
			var CT:Number; /* sin of geocentric latitude */
			var ST:Number; /* cos of geocentric latitude */
			var RX:Number;
			var RK:Number;
			var RN:Number; /* Earth radius at location */
			var CPHI0:Number; /* cos of start or old geodetic latitude in iterations */
			var SPHI0:Number; /* sin of start or old geodetic latitude in iterations */
			var CPHI:Number; /* cos of searched geodetic latitude */
			var SPHI:Number; /* sin of searched geodetic latitude */
			var SDPHI:Number; /* end-criterium: addition-theorem of sin(Latitude(iter)-Latitude(iter-1)) */
			var At_Pole:Boolean; /* indicates location is in polar region */
			var iter:Number; /* # of continous iteration, max. 30 is always enough (s.a.) */

			var X:Number=p.x;
			var Y:Number=p.y;
			var Z:Number=p.z ? p.z : 0.0; //Z value not always supplied
			var Longitude:Number;
			var Latitude:Number;
			var Height:Number;

			At_Pole=false;
			P=Math.sqrt(X * X + Y * Y);
			RR=Math.sqrt(X * X + Y * Y + Z * Z);

			/*      special cases for latitude and longitude */
			if (P / this.a < genau) {
				/*  special case, if P=0. (X=0., Y=0.) */
				At_Pole=true;
				Longitude=0.0;
				/*  if (X,Y,Z)=(0.,0.,0.) then Height becomes semi-minor axis
				 *  of ellipsoid (=center of mass), Latitude becomes PI/2 */
				if (RR / this.a < genau) {
					Latitude=ProjConstants.HALF_PI;
					Height=-this.b;
					return null;
				}
			} else {
				/*  ellipsoidal (geodetic) longitude
				 *  interval: -PI < Longitude <= +PI */
				Longitude=Math.atan2(Y, X);
			}

			/* --------------------------------------------------------------
			 * Following iterative algorithm was developped by
			 * "Institut fьr Erdmessung", University of Hannover, July 1988.
			 * Internet: www.ife.uni-hannover.de
			 * Iterative computation of CPHI,SPHI and Height.
			 * Iteration of CPHI and SPHI to 10**-12 radian resp.
			 * 2*10**-7 arcsec.
			 * --------------------------------------------------------------
			 */
			CT=Z / RR;
			ST=P / RR;
			RX=1.0 / Math.sqrt(1.0 - this.es * (2.0 - this.es) * ST * ST);
			CPHI0=ST * (1.0 - this.es) * RX;
			SPHI0=CT * RX;
			iter=0;

			/* loop to find sin(Latitude) resp. Latitude
			 * until |sin(Latitude(iter)-Latitude(iter-1))| < genau */
			do {
				iter++;
				RN=this.a / Math.sqrt(1.0 - this.es * SPHI0 * SPHI0);

				/*  ellipsoidal (geodetic) height */
				Height=P * CPHI0 + Z * SPHI0 - RN * (1.0 - this.es * SPHI0 * SPHI0);

				RK=this.es * RN / (RN + Height);
				RX=1.0 / Math.sqrt(1.0 - RK * (2.0 - RK) * ST * ST);
				CPHI=ST * (1.0 - RK) * RX;
				SPHI=CT * RX;
				SDPHI=SPHI * CPHI0 - CPHI * SPHI0;
				CPHI0=CPHI;
				SPHI0=SPHI;
			} while (SDPHI * SDPHI > genau2 && iter < maxiter);

			/*      ellipsoidal (geodetic) latitude */
			Latitude=Math.atan(SPHI / Math.abs(CPHI));

			p.x=Longitude;
			p.y=Latitude;
			p.z=Height;
			return p;
		} // cs_geocentric_to_geodetic()


		public function geocentric_to_geodetic_noniter(p:ProjPoint):ProjPoint {
			var X:Number=p.x;
			var Y:Number=p.y;
			var Z:Number=p.z ? p.z : 0; //Z value not always supplied
			var Longitude:Number;
			var Latitude:Number;
			var Height:Number;

			var W:Number; /* distance from Z axis */
			var W2:Number; /* square of distance from Z axis */
			var T0:Number; /* initial estimate of vertical component */
			var T1:Number; /* corrected estimate of vertical component */
			var S0:Number; /* initial estimate of horizontal component */
			var S1:Number; /* corrected estimate of horizontal component */
			var Sin_B0:Number; /* Math.sin(B0), B0 is estimate of Bowring aux variable */
			var Sin3_B0:Number; /* cube of Math.sin(B0) */
			var Cos_B0:Number; /* Math.cos(B0) */
			var Sin_p1:Number; /* Math.sin(phi1), phi1 is estimated latitude */
			var Cos_p1:Number; /* Math.cos(phi1) */
			var Rn:Number; /* Earth radius at location */
			var Sum:Number; /* numerator of Math.cos(phi1) */
			var At_Pole:Boolean; /* indicates location is in polar region */

			At_Pole=false;
			if (X != 0.0) {
				Longitude=Math.atan2(Y, X);
			} else {
				if (Y > 0) {
					Longitude=ProjConstants.HALF_PI;
				} else if (Y < 0) {
					Longitude=-ProjConstants.HALF_PI;
				} else {
					At_Pole=true;
					Longitude=0.0;
					if (Z > 0.0) { /* north pole */
						Latitude=ProjConstants.HALF_PI;
					} else if (Z < 0.0) { /* south pole */
						Latitude=-ProjConstants.HALF_PI;
					} else { /* center of earth */
						Latitude=ProjConstants.HALF_PI;
						Height=-this.b;
						return null;
					}
				}
			}
			W2=X * X + Y * Y;
			W=Math.sqrt(W2);
			T0=Z * ProjConstants.AD_C;
			S0=Math.sqrt(T0 * T0 + W2);
			Sin_B0=T0 / S0;
			Cos_B0=W / S0;
			Sin3_B0=Sin_B0 * Sin_B0 * Sin_B0;
			T1=Z + this.b * this.ep2 * Sin3_B0;
			Sum=W - this.a * this.es * Cos_B0 * Cos_B0 * Cos_B0;
			S1=Math.sqrt(T1 * T1 + Sum * Sum);
			Sin_p1=T1 / S1;
			Cos_p1=Sum / S1;
			Rn=this.a / Math.sqrt(1.0 - this.es * Sin_p1 * Sin_p1);
			if (Cos_p1 >= ProjConstants.COS_67P5) {
				Height=W / Cos_p1 - Rn;
			} else if (Cos_p1 <= -ProjConstants.COS_67P5) {
				Height=W / -Cos_p1 - Rn;
			} else {
				Height=Z / Sin_p1 + Rn * (this.es - 1.0);
			}
			if (At_Pole == false) {
				Latitude=Math.atan(Sin_p1 / Cos_p1);
			}

			p.x=Longitude;
			p.y=Latitude;
			p.z=Height;
			return p;
		} // geocentric_to_geodetic_noniter()

		/****************************************************************/
		// pj_geocentic_to_wgs84( p )
		//  p = point to transform in geocentric coordinates (x,y,z)
		public function geocentric_to_wgs84(p:ProjPoint):void {

			if (this.datum_type == ProjConstants.PJD_3PARAM) {
				// if( x[io] == HUGE_VAL )
				//    continue;
				p.x+=this.datum_params[0];
				p.y+=this.datum_params[1];
				p.z+=this.datum_params[2];

			} else if (this.datum_type == ProjConstants.PJD_7PARAM) {
				var Dx_BF:Number=this.datum_params[0];
				var Dy_BF:Number=this.datum_params[1];
				var Dz_BF:Number=this.datum_params[2];
				var Rx_BF:Number=this.datum_params[3];
				var Ry_BF:Number=this.datum_params[4];
				var Rz_BF:Number=this.datum_params[5];
				var M_BF:Number=this.datum_params[6];
				// if( x[io] == HUGE_VAL )
				//    continue;
				var x_out:Number=M_BF * (p.x - Rz_BF * p.y + Ry_BF * p.z) + Dx_BF;
				var y_out:Number=M_BF * (Rz_BF * p.x + p.y - Rx_BF * p.z) + Dy_BF;
				var z_out:Number=M_BF * (-Ry_BF * p.x + Rx_BF * p.y + p.z) + Dz_BF;
				p.x=x_out;
				p.y=y_out;
				p.z=z_out;
			}
		} // cs_geocentric_to_wgs84

		/****************************************************************/
		// pj_geocentic_from_wgs84()
		//  coordinate system definition,
		//  point to transform in geocentric coordinates (x,y,z)
		public function geocentric_from_wgs84(p:ProjPoint):void {

			if (this.datum_type == ProjConstants.PJD_3PARAM) {
				//if( x[io] == HUGE_VAL )
				//    continue;
				p.x-=this.datum_params[0];
				p.y-=this.datum_params[1];
				p.z-=this.datum_params[2];

			} else if (this.datum_type == ProjConstants.PJD_7PARAM) {
				var Dx_BF:Number=this.datum_params[0];
				var Dy_BF:Number=this.datum_params[1];
				var Dz_BF:Number=this.datum_params[2];
				var Rx_BF:Number=this.datum_params[3];
				var Ry_BF:Number=this.datum_params[4];
				var Rz_BF:Number=this.datum_params[5];
				var M_BF:Number=this.datum_params[6];
				var x_tmp:Number=(p.x - Dx_BF) / M_BF;
				var y_tmp:Number=(p.y - Dy_BF) / M_BF;
				var z_tmp:Number=(p.z - Dz_BF) / M_BF;
				//if( x[io] == HUGE_VAL )
				//    continue;

				p.x=x_tmp + Rz_BF * y_tmp - Ry_BF * z_tmp;
				p.y=-Rz_BF * x_tmp + y_tmp + Rx_BF * z_tmp;
				p.z=Ry_BF * x_tmp - Rx_BF * y_tmp + z_tmp;
			} //cs_geocentric_from_wgs84()
		}



	}
}