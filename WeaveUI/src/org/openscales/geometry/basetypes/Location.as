package org.openscales.geometry.basetypes
{
	import org.openscales.proj4as.Proj4as;
	import org.openscales.proj4as.ProjPoint;
	import org.openscales.proj4as.ProjProjection;
	
	/**
	 * This class represents a location defined by:
	 * an x coordinate
	 * an y coordinate
	 * a projection defined by its SRS code
	 * 
	 * @author slopez
	 */
	public class Location
	{
		private const Geometry_DEFAULT_SRS_CODE:String = "EPSG:4326";
		
		private var _projection:ProjProjection = null;
		private var _x:Number;
		private var _y:Number;
		
		/**
		 * Constructor
		 * 
		 * @param x:Number the X coordinate of the location
		 * @param y:Number the Y coordinate of the location
		 * @param projection the ProjProjection or the SRS code defining the projection of the coordinates, default is Geometry.DEFAULT_SRS_CODE
		 */
		public function Location(x:Number,y:Number,projection:*=null)
		{
			this._x = x;
			this._y = y;
			
			if(projection is ProjProjection)
				this._projection = projection as ProjProjection;
			else if(projection is String)
				this._projection = ProjProjection.getProjProjection(projection as String);
			if(this._projection == null)
				this._projection = ProjProjection.getProjProjection(Geometry_DEFAULT_SRS_CODE);
		}
		
		/**
		 * Clones the current location
		 * 
		 * @return IProjectable a clone of the current location
		 */
		public function clone():Location {
			return new Location(this._x,this._y,this._projection);
		}
		
		/**
		 * Indicates the x coordinate
		 */
		public function get x():Number {
			return this._x;
		}
		
		/**
		 * Indicates the y coordinate
		 */
		public function get y():Number {
			return this._y;
		}
		
		/**
		 * Indicates the projection defining projection of the Location
		 */
		public function get projection():ProjProjection {
			return this._projection;
		}
		
		/**
		 * Indicates the lon coordinate
		 */
		public function get lon():Number {
			return this._x;
		}
		
		/**
		 * Indicates the lat coordinate
		 */
		public function get lat():Number {
			return this._y;
		}
		
		/**
		 * Reprojects the current location in another projection
		 * 
		 * @param the target projection
		 * @return Location the equivalent Location of this location in the new projection
		 */
		public function reprojectTo(projection:*):Location {
			var newProjection:ProjProjection = ProjProjection.getProjProjection(projection);

			if (!newProjection || newProjection == this._projection) {
				return this;
			}
			var p:ProjPoint = new ProjPoint(this._x, this._y);
			Proj4as.transform(this._projection, newProjection, p);
			return new Location(p.x,p.y,newProjection);
		}
		
		/**
		 * Gives the equivalent string of the current location
		 * 
		 * @return String the current location
		 */
		public function toString():String {
			return "lon=" + this._x + ",lat=" + this._y;
		}
		
		/**
		 * Gives the equivalent short string of the current location
		 * 
		 * @return String the current location
		 */
		public function toShortString():String {
			return this._x + ", " + this._y;
		}
		
		/**
		 * Adds delta derivation to the current Location
		 * 
		 * @param x:Number the X derivation
		 * @param y:Number the Y derivation
		 * 
		 * @return Location the new Location
		 */
		public function add(x:Number, y:Number):Location {
			return new Location(this._x + x, this._y + y, this._projection);
		}
		
		/**
		 * Compares a Location with the current one
		 * 
		 * @param loc:Location the Location to compare with
		 * 
		 * @return Boolean is equal
		 */
		public function equals(loc:Location):Boolean {
			var equals:Boolean = false;
			if (loc != null) {
				equals = this._x == loc.x
					&& this._y == loc.y
					&& this._projection == loc.projection;
			}
			return equals;
		}
		
		/**
		 * Creates a Location from a string
		 * @param str:String the string representing the coordinates
		 * @param projection:String the SRS code defining the projection of the coordinate
		 * 
		 * @return Location the location.
		 */
		public static function getLocationFromString(str:String,projection:String=null):Location {
			var pair:Array = str.split(",");
			return new Location(Number(pair[0]), Number(pair[1]), projection);
		}
		
	}
}