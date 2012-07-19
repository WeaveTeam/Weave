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
	import flash.utils.Dictionary;
	
	import weave.api.primitives.IBounds2D;
	import weave.primitives.KDTree;
	
	/**
	 * This class provides an interface to query a collection of spatially indexed objects.
	 * 
	 * @author adufilie
	 */
	public class Bounds2DIndex
	{
		public function Bounds2DIndex()
		{
		}
		
		private const _kdTree:KDTree = new KDTree(4);
		
		/**
		 * These constants define indices in a KDKey corresponding to xmin,ymin,xmax,ymax,importance values.
		 */
		private const XMIN_INDEX:int = 0, YMIN_INDEX:int = 1;
		private const XMAX_INDEX:int = 2, YMAX_INDEX:int = 3;
		
		/**
		 * These KDKey arrays are created once and reused to avoid unnecessary creation of objects.
		 * The only values that change are the ones that are undefined here.
		 */
		private const minKDKey:Array = [Number.NEGATIVE_INFINITY, Number.NEGATIVE_INFINITY, NaN, NaN];
		private const maxKDKey:Array = [NaN, NaN, Number.POSITIVE_INFINITY, Number.POSITIVE_INFINITY];
		
		// provides a reverse lookup for probe()
		private var objectToCoords:Dictionary = new Dictionary(true);
		
		private var _tempBounds:Bounds2D = new Bounds2D();
		
		/**
		 * Removes all entries from the index.
		 * 
		 */		
		public function clear():void
		{
			objectToCoords = new Dictionary(true);
			_kdTree.clear();
		}
		
		/**
		 * Inserts an entry into the index
		 * @param bounds A bounds associated with an object.
		 * @param object The object to insert in the index.
		 * 
		 */		
		public function insert(bounds:IBounds2D, object:Object):void
		{
			var coords:Array = [bounds.getXNumericMin(), bounds.getYNumericMin(), bounds.getXNumericMax(), bounds.getYNumericMax()];
			objectToCoords[object] = coords;
			_kdTree.insert(coords, object);
		}
		
		/**
		 * This function will return a list of objects whose bounds overlap a query bounds.
		 * @param bounds A bounds used to query the spatial index.
		 * @return An array of objects.
		 */
		public function select(bounds:IBounds2D):Array
		{
			// This is a filter for bounding boxes and should be used for getting fast results
			// during panning and zooming.
			
			// set the minimum query values for shape.bounds.xMax, shape.bounds.yMax
			minKDKey[XMAX_INDEX] = bounds.getXNumericMin(); // enforce result.XMAX >= query.xNumericMin
			minKDKey[YMAX_INDEX] = bounds.getYNumericMin(); // enforce result.YMAX >= query.yNumericMin
			// set the maximum query values for shape.bounds.xMin, shape.bounds.yMin
			maxKDKey[XMIN_INDEX] = bounds.getXNumericMax(); // enforce result.XMIN <= query.xNumericMax
			maxKDKey[YMIN_INDEX] = bounds.getYNumericMax(); // enforce result.YMIN <= query.yNumericMax
			
			return _kdTree.queryRange(minKDKey, maxKDKey);
		}
		
		
		/**
		 * This function will get the objects whose bounds are closest to the center of the queryBounds object.
		 * Generally this function will return an array of at most one object.  Sometimes, it may return more
		 * than one object if there are multiple objects with equivalent distance to the center of the bounds object.
		 * 
		 * @param queryBounds A bounds used to query the spatial index.
		 * @return An array of objects. 
		 */		
		public function probe(queryBounds:IBounds2D):Array
		{
			var selectedObjects:Array = select(queryBounds);
			
			// init local vars
			var closestDistanceSq:Number = Infinity;
			var xDistance:Number;
			var yDistance:Number;
			var distanceSq:Number;
			var xQueryCenter:Number = queryBounds.getXCenter();
			var yQueryCenter:Number = queryBounds.getYCenter();
			var foundQueryCenterOverlap:Boolean = false; // true when we found a key that overlaps the center of the given bounds
			// begin with a result of zero objects
			var result:Array = [];
			var resultCount:int = 0;
			for (var i:int = 0; i < selectedObjects.length; ++i)
			{
				var object:Object = selectedObjects[i];
				var overlapsQueryCenter:Boolean = false;
				
				// get the bounds associated with the selected object
				_tempBounds.setBounds.apply(null, objectToCoords[object] as Array);
				
				// find the distance squared from the query center point to the center of the object's bounds
				xDistance = _tempBounds.getXCenter() - xQueryCenter;
				yDistance = _tempBounds.getYCenter() - yQueryCenter;
				distanceSq = xDistance * xDistance + yDistance * yDistance;
				
				overlapsQueryCenter = _tempBounds.contains(xQueryCenter, yQueryCenter);
				
				// Consider all keys until we have found one that overlaps the query center.
				// After that, only consider keys that overlap query center.
				if (!foundQueryCenterOverlap || overlapsQueryCenter)
				{
					// if this is the first record that overlaps the query center, reset the list of keys
					if (!foundQueryCenterOverlap && overlapsQueryCenter)
					{
						resultCount = 0;
						closestDistanceSq = distanceSq;
						foundQueryCenterOverlap = true;
					}
					// if this distance is closer than any previous distance, clear all previous keys
					if (distanceSq < closestDistanceSq)
					{
						// clear previous result and update closest distance
						resultCount = 0;
						closestDistanceSq = distanceSq;
					}
					// add keys to the result if they are the closest so far
					if (distanceSq == closestDistanceSq && (resultCount == 0 || result[resultCount - 1] != object))
						result[resultCount++] = object;
				}
			}
			
			result.length = resultCount;
			return result;
		}
	}
}
