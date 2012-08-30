package org.openscales.geometry.basetypes
{
	import flash.system.Capabilities;
	
	import org.openscales.proj4as.ProjProjection;
	
	/**
	 * The map unit
	 *
	 * @author Bouiaw
	 */
	public class Unit
	{
		public static var SEXAGESIMAL:String = "dms";
		public static var DEGREE:String = "degrees";
		public static var METER:String = "m";
		public static var KILOMETER:String = "km";
		public static var CENTIMETER:String = "cm";
		public static var FOOT:String = "ft";
		public static var MILE:String = "mi";
		public static var INCH:String = "inch";
		public static var RADIAN:String = "rad";
		
		public static var PIXEL_SIZE:Number = 0.00028;
		
		public static var DOTS_PER_INCH:Number = Capabilities.screenDPI;
		
		public function Unit(){}
		
		/**
		 * Returns the number of inches per unit
		 * 
		 * @param the unit
		 * @return the number of inches
		 */
		public static function getInchesPerUnit(unit:String):Number {
			switch(unit) {
				case Unit.INCH:
					return 1.0;
					break;
				case Unit.FOOT:
					return 12.0;
					break;
				case Unit.MILE:
					return 63360.0;
					break;
				case Unit.METER:
					return 39.3700787;
					break;
				case Unit.KILOMETER:
					return 39370.0787;
					break;
				case Unit.DEGREE:
					return 4374754;
					break;
				default:
					return 0;
			}
		}
		
		/**
		 * Returns the number of meters per unit
		 * 
		 * @param the unit
		 * @return the number of meters
		 */
		public static function getMetersPerUnit(unit:String):Number {
			switch(unit){
				case Unit.DEGREE:
					return 111319.4908;
				case Unit.METER:
					return 1;
				case Unit.FOOT:
					return 0.3048;
				default:
					return 0;
			}
		} 
		
		/**
		 * Returns the resolution from a scale
		 * 
		 * @param the scale
		 * @param the unit, if not specified Unit.DEGREE is used
		 * @param the screen dpi, if not specified  Unit.DOTS_PER_INCH is used
		 * @return the resolution
		 */
		public static function getResolutionFromScale(scale:Number, units:String = null, dpi:Number = NaN):Number {
			
			if (units == null) {
				units = Unit.DEGREE;
			}
			if (isNaN(dpi))
			{
				dpi = Unit.DOTS_PER_INCH;
			}
			
			var normScale:Number = UtilGeometry_normalizeScale(scale);
			
			var resolution:Number = 1 / (normScale * Unit.getInchesPerUnit(units)
				* dpi);
			return resolution;
		}
		
		/**
		 * Returns the scale from a resolution
		 * 
		 * @param the resolution
		 * @param the unit, if not specified Unit.DEGREE is used
		 * @param the screen dpi, if not specified  Unit.DOTS_PER_INCH is used
		 * @return the scale
		 */
		public static function getScaleFromResolution(resolution:Number, units:String = null, dpi:Number = NaN):Number {
			if (units == null) {
				units = Unit.DEGREE;
			}
			if (isNaN(dpi))
			{
				dpi = Unit.DOTS_PER_INCH;
			}
			
			var scale:Number = resolution * Unit.getInchesPerUnit(units) * dpi;

			return scale;
		}
		
		/**
		 * Returns the resolution from a scale denominator
		 * 
		 * @param the scale denominator
		 * @param the unit, if not specified Unit.DEGREE is used
		 * @return the resolution
		 */
		public static function getResolutionFromScaleDenominator(scaleDenominator:Number, units:String = null):Number {
			if (units == null) {
				units = Unit.DEGREE;
			}
			return (scaleDenominator * Unit.PIXEL_SIZE / Unit.getMetersPerUnit(units));
		}
		
		/**
		 * Returns the scale denominator from a resolution
		 * 
		 * @param the resolution
		 * @param the unit, if not specified Unit.DEGREE is used
		 * @return the scale
		 */
		public static function getScaleDenominatorFromResolution(resolution:Number, units:String = null):Number {
			if (units == null) {
				units = Unit.DEGREE;
			}
			return (resolution * Unit.getMetersPerUnit(units) / Unit.PIXEL_SIZE);
		}
		
		/**
		 * Returns the resolution approximate 
		 * 
		 * @param resolution The current map resolution
		 * @param center The current map center
		 * @param projection The current map projection
		 * 
		 * @return the resolution value at the given center
		 */
		public static function getResolutionOnCenter(resolution:Number, center:Location, projection:ProjProjection):Number
		{
			var bFound:Boolean = false;
			var res:Number = resolution;
			
			if(projection && projection.projName  == "longlat") {
				
				var a:Number = projection.a;
				var b:Number = projection.b;
				
				if (!(a && b)) {
					// approx is to calculate the resolution at the center's latitude :
					
					//res*=rayon_eq_terre*Pi*lat in radius
					//res*= 6378137*3.141592653589793238*Math.cos(center.lat*3.141592653589793238/180.0)/180.0
					res*= 111319.490793273573*Math.cos(center.lat*0.0174532925199432958);
				} else {
					// approximation of a longitudinal degree at latitude phi :
					var cosphi:Number = Math.cos(center.lat*0.0174532925199432958);
					var cosphiSquare:Number = cosphi*cosphi;
					var sinphi:Number = Math.sin(center.lat*0.0174532925199432958);
					var sinphiSquare:Number = sinphi*sinphi;
					var aSquare:Number = a*a;
					var aQuad:Number= a*a*a*a;
					var bSquare:Number= b*b;
					var bQuad:Number = b*b*b*b;
					res*= 0.0174532925199432958*cosphi*Math.sqrt((aQuad*cosphiSquare+bQuad*sinphiSquare)/(aSquare*cosphiSquare+bSquare*sinphiSquare));
				}
			}
			
			return res;
		}
		
		
		/**
		 * Normalise scale
		 *
		 * @param scale
		 *
		 * @return return a normalized scale value, in 1 / X format
		 */
		public static function UtilGeometry_normalizeScale(scale:Number):Number {
			var normScale:Number = (scale > 1.0) ? (1.0 / scale)
				: scale;
			return normScale;
		}
		
	}
}

