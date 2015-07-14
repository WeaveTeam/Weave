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
	import flash.utils.Dictionary;
	
	import weave.api.core.IDisposableObject;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerDisposableChild;
	
	/**
	 * This class provides an interface to query a collection of spatially indexed objects.
	 * 
	 * @author adufilie
	 */
	public class Bounds2DIndex implements IDisposableObject
	{
		public function Bounds2DIndex()
		{
		}
		
		public function dispose():void
		{
			// _kdTree will be automatically disposed
		}
		
		private const _kdTree:KDTree = registerDisposableChild(this, new KDTree(4));
		
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
					// if this is the first record that overlaps the query center, reset the result
					if (!foundQueryCenterOverlap && overlapsQueryCenter)
					{
						foundQueryCenterOverlap = true;
						resultCount = 0;
						closestDistanceSq = Infinity;
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
		
		public static function test():void
		{
			var a:Bounds2D = new Bounds2D(69, 110, 121, 129);
			var b:Bounds2D = new Bounds2D(92, 120, 117, 139);
			var i:Bounds2DIndex = new Bounds2DIndex();
			i.insert(a, 'a');
			i.insert(b, 'b');
			var p:Bounds2D = new Bounds2D(108, 120, 110, 122);
			trace(i.probe(p)); // returns b because b's center is closest to the query bounds center
		}
	}
}
