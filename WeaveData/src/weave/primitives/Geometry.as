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

package weave.primitives
{
	import weave.api.data.ISimpleGeometry;

	/**
	 * This class acts as a wrapper for a general polygon.
	 * 
	 * @author kmonico
	 */
	public class Geometry implements ISimpleGeometry
	{
		public function Geometry(type:String = CLOSED_POLYGON)
		{
			_type = type;
		}
		
		public function getVertices():Array { return _vertices; }
		public function setVertices(o:Array):void 
		{	
			_vertices = o.concat();
		}

		public function isPolygon():Boolean { return _type == CLOSED_POLYGON; }
		public function isLine():Boolean { return _type == LINE; }
		public function isPoint():Boolean { return _type == POINT; }
		
		private var _vertices:Array = null; // [object with x and y fields, another object, ...]
		private var _type:String = '';
		public static const CLOSED_POLYGON:String = "CLOSED_POLYGON";
		public static const LINE:String = "LINE";
		public static const POINT:String = "POINT";
		
		
		
	}
}