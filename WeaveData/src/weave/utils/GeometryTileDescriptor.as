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

package weave.utils
{
	import weave.primitives.Bounds2D;
	import weave.primitives.Range;
	
	public class GeometryTileDescriptor
	{
		public function GeometryTileDescriptor(kdKey:Array, tileID:int, queryBounds:Bounds2D, pointBounds:Bounds2D, importanceRange:Range)
		{
			this.kdKey = kdKey;
			this.tileID = tileID;
			this.queryBounds = queryBounds;
			this.pointBounds = pointBounds;
			this.importanceRange = importanceRange;
		}
		public var kdKey:Array;
		public var tileID:int;
		public var queryBounds:Bounds2D;
		public var pointBounds:Bounds2D;
		public var importanceRange:Range;
	}
}
