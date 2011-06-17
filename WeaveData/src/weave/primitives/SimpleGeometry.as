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
	import weave.api.data.ISimpleGeometry;
	import weave.api.primitives.IBounds2D;

	/**
	 * This class acts as a wrapper for a general polygon.
	 * 
	 * @author kmonico
	 */
	public class SimpleGeometry implements ISimpleGeometry
	{
		public function SimpleGeometry(type:String = CLOSED_POLYGON)
		{
			_type = type;
		}
		
		public function getVertices():Array { return _vertices; }
		public function setVertices(o:Array):void 
		{	
			_vertices = o.concat();
			
			bounds.reset();
			for each (var obj:* in _vertices)
				bounds.includeCoords(obj.x, obj.y);
		}

		public function isPolygon():Boolean { return _type == CLOSED_POLYGON; }
		public function isLine():Boolean { return _type == LINE; }
		public function isPoint():Boolean { return _type == POINT; }
		
		private var _vertices:Array = null; // [object with x and y fields, another object with x and y fields, ...]
		private var _type:String = '';
		public static const CLOSED_POLYGON:String = "CLOSED_POLYGON";
		public static const LINE:String = "LINE";
		public static const POINT:String = "POINT";
		
		public const bounds:IBounds2D = new Bounds2D(); 
		
	}
}