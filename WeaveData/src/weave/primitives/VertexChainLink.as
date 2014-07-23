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
	/**
	 * VertexChainLink
	 * @author adufilie
	 */	
	public class VertexChainLink
	{
		public function VertexChainLink(vertexID:int, x:Number, y:Number)
		{
			initialize(vertexID, x, y);
		}
		
		public function initialize(vertexID:int, x:Number, y:Number):void
		{
			this.vertexID = vertexID;
			this.x = x;
			this.y = y;
			this.importance = -1;
			importanceIsValid = false;
			// make this vertex adjacent to itself
			prev = this;
			next = this;
		}

		public var vertexID:int;
		public var x:Number;
		public var y:Number;
		public var importance:Number;
		public var prev:VertexChainLink;
		public var next:VertexChainLink;
		public var importanceIsValid:Boolean;

		/**
		 * insert
		 * Adds a new vertex to the end of the chain.
		 */		
		public function insert(newVertex:VertexChainLink):void
		{
			prev.next = newVertex; // add new vertex to end of chain
			newVertex.prev = this.prev; // the current last vertex appears before the new one
			newVertex.next = this; // the new vertex wraps around to this one
			this.prev = newVertex; // this vertex wraps backwards around to the new one
		}

		/**
		 * equals2D
		 * Returns true if x and y are equal between two VertexChainLink objects.
		 */
		public function equals2D(other:VertexChainLink):Boolean
		{
			return this.x == other.x && this.y == other.y;
		}
		
		/**
		 * removeFromChain
		 * Updates prev and next pointers on adjacent VertexChainLinks so this link is removed.
		 */
		public function removeFromChain():void
		{
			// promote adjacent vertices and invalidate their importance
			prev.promoteAndInvalidateImportance(importance);
			next.promoteAndInvalidateImportance(importance);
			// make next and prev adjacent to each other
			prev.next = next;
			next.prev = prev;
			// make this vertex adjacent to itself
			prev = this;
			next = this;
			saveUnusedInstance(this);
		}

		/**
		 * promoteAndInvalidateImportance
		 * @param minImportance If the importance value of this vertex is less than minImportance, it will be set to minImportance.
		 */
		private function promoteAndInvalidateImportance(minImportance:Number):void
		{
			importance = Math.max(importance, minImportance);
			importanceIsValid = false;
		}

		/**
		 * updateImportance
		 * This function re-calculates the importance of the current point.
		 * It may only increase the importance, not decrease it.
		 */
		public function validateImportance():void
		{
			importanceIsValid = true;
			
			// stop if already marked required
			if (importance == Infinity)
				return;
	
			// the importance of a point is the area formed by it and its two neighboring points
			// update importance
			
			//TODO: use distance as well as area in determining importance?
			
			var area:Number = areaOfTriangle(prev, this, next);
			importance = Math.max(importance, area);
		}

		/**
		 * areaOfTriangle
		 * @param a First point in a triangle.
		 * @param b Second point in a triangle.
		 * @param c Third point in a triangle.
		 * @return The area of the triangle ABC.
		 */
		private function areaOfTriangle(a:VertexChainLink, b:VertexChainLink, c:VertexChainLink):Number
		{
			// http://www.softsurfer.com/Archive/algorithm_0101/algorithm_0101.htm
			// get signed area of the triangle formed by three points
			var signedArea:Number = ((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)) / 2;
			// return absolute value
			if (signedArea < 0)
				return -signedArea;
			return signedArea;
		}

		private static const unusedInstances:Vector.<VertexChainLink> = new Vector.<VertexChainLink>();
		public static function getUnusedInstance(vertexID:int, x:Number, y:Number):VertexChainLink
		{
			if (unusedInstances.length > 0)
			{
				var link:VertexChainLink = unusedInstances.pop();
				link.initialize(vertexID, x, y);
			}
			return new VertexChainLink(vertexID, x, y);
		}
		public static function saveUnusedInstance(vertex:VertexChainLink):void
		{
			vertex.prev = vertex.next = null;
			unusedInstances.push(vertex);
		}
		public static function clearUnusedInstances():void
		{
			unusedInstances.length = 0;
		}
	}
}
