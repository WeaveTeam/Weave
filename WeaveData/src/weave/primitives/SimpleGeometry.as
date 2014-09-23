/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package weave.primitives
{
	import flash.geom.Point;
	
	import weave.api.data.ISimpleGeometry;
	import weave.api.primitives.IBounds2D;

	/**
	 * This class acts as a wrapper for a general polygon.
	 * 
	 * @author kmonico
	 */
	public class SimpleGeometry implements ISimpleGeometry
	{
		/**
		 * @param type One of the constants defined in GeometryType.
		 * @param points An optional Array of Objects to pass to setVertices().
		 * @see weave.primitives.GeometryType
		 * @see #setVertices()
		 */
		public function SimpleGeometry(type:String = GeometryType.POLYGON, points:Array = null)
		{
			_type = type;
			if (points)
				setVertices(points);
		}
		
		/**
		 * Gets the points of the geometry.
		 * @return An Array of objects, each having "x" and "y" properties.
		 */
		public function getVertices():Array
		{
			return _vertices;
		}
		
		/**
		 * Initializes the geometry.
		 * @param points An Array of objects, each having "x" and "y" properties.
		 */
		public function setVertices(points:Array):void 
		{	
			_vertices = points.concat();
			
			bounds.reset();
			for each (var obj:* in _vertices)
				bounds.includeCoords(obj.x, obj.y);
		}

		public function isPolygon():Boolean { return _type == GeometryType.POLYGON; }
		public function isLine():Boolean { return _type == GeometryType.LINE; }
		public function isPoint():Boolean { return _type == GeometryType.POINT; }
		
		public const bounds:IBounds2D = new Bounds2D(); 
		
		/**
		 * An Array of objects, each having "x" and "y" properties.
		 */
		private var _vertices:Array = null;
		private var _type:String = '';
		
		
		/**
		 * A static helper function to convert a bounds object into an ISimpleGeometry object.
		 *  
		 * @param bounds The bounds to transform.
		 * @return A new ISimpleGeometry object.
		 */		
		public static function getNewGeometryFromBounds(bounds:IBounds2D):ISimpleGeometry
		{
			var xMin:Number = bounds.getXMin();
			var xMax:Number = bounds.getXMax();
			var yMin:Number = bounds.getYMin();
			var yMax:Number = bounds.getYMax();
			
			var geom:SimpleGeometry = new SimpleGeometry(GeometryType.POLYGON);
			geom.setVertices([
				new Point(xMin, yMin),
				new Point(xMax, yMin),
				new Point(xMax, yMax),
				new Point(xMin, yMax)
			]);
			
			return geom;
		}
	}
}