/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weavejs.geom
{
	import weavejs.api.data.ISimpleGeometry;

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
		public function SimpleGeometry(type:String = "Polygon", points:Array = null)
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
		
		public var bounds:Bounds2D = new Bounds2D(); 
		
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
		public static function getNewGeometryFromBounds(bounds:Bounds2D):ISimpleGeometry
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