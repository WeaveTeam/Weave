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

package org.oicweave.utils
{
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import org.oicweave.api.data.IQualifiedKey;
	import org.oicweave.api.primitives.IBounds2D;
	import org.oicweave.api.ui.IPlotter;
	import org.oicweave.api.ui.ISpatialIndex;
	import org.oicweave.core.CallbackCollection;
	import org.oicweave.primitives.Bounds2D;
	import org.oicweave.primitives.KDTree;
	
	/**
	 * This class provides an interface to a collection of spatially indexed IShape objects.
	 * This class will not detect changes to the shapes you add to the index.
	 * If you change the bounds of the shapes, you will need to call ShapeIndex.createIndex().
	 * 
	 * @author adufilie
	 */
	public class SpatialIndex extends CallbackCollection implements ISpatialIndex
	{
		public function SpatialIndex(callback:Function = null, callbackParameters:Array = null)
		{
			addImmediateCallback(this, callback, callbackParameters);
		}

		/**
		 * collectiveBounds
		 * This bounds represents the full extent of the shape index.
		 */
		public const collectiveBounds:IBounds2D = new Bounds2D();

		/**
		 * Indexes shapes by key (Unique string identifier, not a K-Dimensional key)
		 * keyToBoundsMapping[key] returns an Array of Bounds2D objects.
		 */
		private var _keyToBoundsMap:Dictionary = new Dictionary();
		
		/**
		 * This function gets a list of Bounds2D objects associated with a key.
		 * @param key A record key.
		 * @result An Array of Bounds2D objects associated with the key.
		 */
		public function getBoundsFromKey(key:IQualifiedKey):Array
		{
			return _keyToBoundsMap[key] as Array;
		}
		
		/**
		 * The list of all the IQualifiedKey objects (record identifiers) referenced in this index.
		 */
		public function get keys():Array
		{
			return _keysArray;
		}
		private const _keysArray:Array = new Array();
		
		/**
		 * The number of records in the index
		 */
		public function get recordCount():int
		{
			return kdtree.nodeCount;
		}
		
		/**
		 * kdtree
		 * This provides the internal indexing method.
		 */
		private var kdtree:KDTree = new KDTree(5); // KDkeys should be of the form: [xmin, ymin, xmax, ymax, importance]
		/**
		 * These constants define indices in a KDKey corresponding to xmin,ymin,xmax,ymax,importance values.
		 */
		private const XMIN_INDEX:int = 0, YMIN_INDEX:int = 1;
		private const XMAX_INDEX:int = 2, YMAX_INDEX:int = 3;
		private const IMPORTANCE_INDEX:int = 4;

		
		/**
		 * This function fills the spatial index with the data bounds of each record in a plotter.
		 * @param plotter An IPlotter object to create a spatial index for.
		 */
		public function createIndex(plotter:IPlotter):void
		{
			delayCallbacks();

			var key:IQualifiedKey;
			var bounds:IBounds2D;
			var i:int;
			
			tempBounds.copyFrom(collectiveBounds);

			clear();
			
			if (plotter != null)
			{
				collectiveBounds.copyFrom(plotter.getBackgroundDataBounds());
				
				
				// make a copy of the keys vector
				VectorUtils.copy(plotter.keySet.keys, _keysArray);

				// save dataBounds for each key
				i = _keysArray.length;
				while (--i > -1)
				{
					key = _keysArray[i] as IQualifiedKey;
					_keyToBoundsMap[key] = plotter.getDataBoundsFromRecordKey(key);
				}

				// if auto-balance is disabled, randomize insertion order
				if (!kdtree.autoBalance)
				{
					// randomize the order of the shapes to avoid a possibly poorly-performing
					// KDTree structure due to the given ordering of the records
					VectorUtils.randomSort(_keysArray);
				}
				// insert bounds-to-key mappings in the kdtree
				i = _keysArray.length;
				while (--i > -1)
				{
					key = _keysArray[i] as IQualifiedKey;
					for each (bounds in _keyToBoundsMap[key])
					{
						// do not index shapes with undefined bounds
						//TODO: index shapes with missing bounds values into a different index
						if (!bounds.isUndefined())
						{
							kdtree.insert([bounds.getXNumericMin(), bounds.getYNumericMin(), bounds.getXNumericMax(), bounds.getYNumericMax(), bounds.getArea()], key); //TODO: avoid creating new Array?
							collectiveBounds.includeBounds(bounds);
						}
					}
				}
			}
			
			// if there are 
			if (_keysArray.length > 0 || !tempBounds.equals(collectiveBounds))
				triggerCallbacks();
			
			resumeCallbacks();
		}

		/**
		 * This function empties the spatial index.
		 */
		public function clear():void
		{
			delayCallbacks();
			
			if (_keysArray.length > 0)
				triggerCallbacks();
			
			_keysArray.length = 0;
			_keyToBoundsMap = new Dictionary();
			kdtree.clear();
			collectiveBounds.reset();

			resumeCallbacks();
		}

		/**
		 * These KDKey arrays are created once and reused to avoid unnecessary creation of objects.
		 * The only values that change are the ones that are undefined here.
		 */
		private var minKDKey:Array = [Number.NEGATIVE_INFINITY, Number.NEGATIVE_INFINITY, NaN, NaN, 0];
		private var maxKDKey:Array = [NaN, NaN, Number.POSITIVE_INFINITY, Number.POSITIVE_INFINITY, Number.POSITIVE_INFINITY];
		
		/**
		 * @param point A point used to query the spatial index.
		 * @return An array of keys with bounds that contain the given point.
		 */
		public function getKeysContainingPoint(point:Point):Array
		{
			//TODO: use polygon containment test on query results

			// set the minimum query values for shape.bounds.xMax, shape.bounds.yMax
			minKDKey[XMAX_INDEX] = point.x;
			minKDKey[YMAX_INDEX] = point.y;
			minKDKey[IMPORTANCE_INDEX] = 0;
			// set the maximum query values for shape.bounds.xMin, shape.bounds.yMin
			maxKDKey[XMIN_INDEX] = point.x;
			maxKDKey[YMIN_INDEX] = point.y;

			return kdtree.queryRange(minKDKey, maxKDKey);
		}

		/**
		 * @param bounds A bounds used to query the spatial index.
		 * @return An array of keys with bounds that overlap the given bounds.
		 */
		public function getOverlappingKeys(bounds:IBounds2D, minImportance:Number = 0):Array
		{
			//TODO: use polygon containment test on query results

			// set the minimum query values for shape.bounds.xMax, shape.bounds.yMax
			minKDKey[XMAX_INDEX] = bounds.getXNumericMin(); // enforce result.XMAX >= query.xNumericMin
			minKDKey[YMAX_INDEX] = bounds.getYNumericMin(); // enforce result.YMAX >= query.yNumericMin
			minKDKey[IMPORTANCE_INDEX] = minImportance; // enforce result.IMPORTANCE >= minImportance
			// set the maximum query values for shape.bounds.xMin, shape.bounds.yMin
			maxKDKey[XMIN_INDEX] = bounds.getXNumericMax(); // enforce result.XMIN <= query.xNumericMax
			maxKDKey[YMIN_INDEX] = bounds.getYNumericMax(); // enforce result.YMIN <= query.yNumericMax
			
			return kdtree.queryRange(minKDKey, maxKDKey);
		}

		/**
		 * @param bounds A bounds used to query the spatial index.
		 * @param xPrecision If specified, X distance values will be divided by this and truncated before comparing.
		 * @param yPrecision If specified, Y distance values will be divided by this and truncated before comparing.
		 * @return An array of keys with bounds that overlap the given bounds and are closest to the center of the given bounds.
		 */
		public function getClosestOverlappingKeys(bounds:IBounds2D, xPrecision:Number = NaN, yPrecision:Number = NaN):Array
		{
			// get the shapes that intersect with the given bounds
			var keys:Array = getOverlappingKeys(bounds);
			// init local vars
			var closestDistanceSq:Number = Infinity;
			var xDistance:Number;
			var yDistance:Number;
			var distanceSq:Number;
			var xRecordCenter:Number;
			var yRecordCenter:Number;
			var recordBounds:IBounds2D;
			var xQueryCenter:Number = bounds.getXCenter();
			var yQueryCenter:Number = bounds.getYCenter();
			var foundQueryCenterOverlap:Boolean = false; // true when we found a key that overlaps the center of the given bounds
			// begin with a result of zero shapes
			var result:Array = [];
			var resultCount:int = 0;
			for each (var key:IQualifiedKey in keys)
			{
				for each (recordBounds in _keyToBoundsMap[key])
				{
					// find the distance squared from the query point to the center of the shape
					xDistance = recordBounds.getXCenter() - xQueryCenter;
					yDistance = recordBounds.getYCenter() - yQueryCenter;
					if (!isNaN(xPrecision) && xPrecision != 0)
						xDistance = int(xDistance / xPrecision);
					if (!isNaN(yPrecision) && yPrecision != 0)
						yDistance = int(yDistance / yPrecision);
					distanceSq = xDistance * xDistance + yDistance * yDistance;
					var overlapsQueryCenter:Boolean = recordBounds.contains(xQueryCenter, yQueryCenter);
					// Consider all keys until we have found one that overlaps the query center.
					// After that, only consider keys that overlap query center.
					if (!foundQueryCenterOverlap || overlapsQueryCenter)
					{
						// if this is the first record that overlaps the query center, reset the list of keys
						if (!foundQueryCenterOverlap && overlapsQueryCenter)
						{
							resultCount = 0;
							closestDistanceSq = Infinity;
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
						if (distanceSq == closestDistanceSq && (resultCount == 0 || result[resultCount - 1] != key))
							result[resultCount++] = key;
					}
				}
			}
			result.length = resultCount;
			return result;
		}
		
		// reusable temporary objects
		private static const tempPoint:Point = new Point();
		private static const tempBounds:IBounds2D = new Bounds2D();
	}
}
