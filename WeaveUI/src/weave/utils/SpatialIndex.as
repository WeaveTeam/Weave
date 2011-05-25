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
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import weave.api.WeaveAPI;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	import weave.api.ui.IPlotter;
	import weave.api.ui.ISpatialIndex;
	import weave.core.CallbackCollection;
	import weave.data.AttributeColumns.GeometryColumn;
	import weave.data.QKeyManager;
	import weave.primitives.BLGNode;
	import weave.primitives.Bounds2D;
	import weave.primitives.GeneralizedGeometry;
	import weave.primitives.KDTree;
	import weave.primitives.LineRay;
	import weave.primitives.LineSegment;
	import weave.visualization.plotters.DynamicPlotter;
	import weave.visualization.plotters.GeometryPlotter;
	
	/**
	 * This class provides an interface to a collection of spatially indexed IShape objects.
	 * This class will not detect changes to the shapes you add to the index.
	 * If you change the bounds of the shapes, you will need to call SpatialIndex.createIndex().
	 * 
	 * @author adufilie
	 * @author kmonico
	 */
	public class SpatialIndex extends CallbackCollection implements ISpatialIndex
	{
		public function SpatialIndex(callback:Function = null, callbackParameters:Array = null)
		{
			addImmediateCallback(this, callback, callbackParameters);
			//_geometryIndex = new GeometrySpatialIndex(callback, callbackParameters);
			//_refinedIndex = new RefinedSpatialIndex(callback, callbackParameters);
		}

		private var _geometryIndex:GeometrySpatialIndex = null;
		private var _refinedIndex:RefinedSpatialIndex = null;
		
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
			var result:Array = _keyToBoundsMap[key] as Array;
			
			if (result == null)
			{
				trace('result null for key: ', key);
				
				return [];
			}
			return result;			
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

		private var _keyToGeometryColumn:Dictionary = new Dictionary();
		private function cacheKey(key:IQualifiedKey, plotter:IPlotter):void
		{
			_keyToBoundsMap[key] = plotter.getDataBoundsFromRecordKey(key);
			
			var dynamicPlotter:DynamicPlotter = (plotter as DynamicPlotter);
			if (dynamicPlotter != null)
			{
				var geomPlotter:GeometryPlotter = dynamicPlotter.internalObject as GeometryPlotter;
				if (geomPlotter != null)
					_keyToGeometryColumn[key] = geomPlotter.geometryColumn;
			}
		}
		
		private var _lastUsedPlotter:IPlotter = null;
		
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
					cacheKey(key, plotter);
					//_keyToBoundsMap[key] = plotter.getDataBoundsFromRecordKey(key);
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
			
			// remember the type of the plotter so we can perform the bridge actions
			if (plotter is DynamicPlotter)
				_lastUsedPlotter = (plotter as DynamicPlotter).internalObject as IPlotter;
			else
				_lastUsedPlotter = plotter;
			
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
			// set the minimum query values for shape.bounds.xMax, shape.bounds.yMax
			minKDKey[XMAX_INDEX] = bounds.getXNumericMin(); // enforce result.XMAX >= query.xNumericMin
			minKDKey[YMAX_INDEX] = bounds.getYNumericMin(); // enforce result.YMAX >= query.yNumericMin
			minKDKey[IMPORTANCE_INDEX] = minImportance; // enforce result.IMPORTANCE >= minImportance
			// set the maximum query values for shape.bounds.xMin, shape.bounds.yMin
			maxKDKey[XMIN_INDEX] = bounds.getXNumericMax(); // enforce result.XMIN <= query.xNumericMax
			maxKDKey[YMIN_INDEX] = bounds.getYNumericMax(); // enforce result.YMIN <= query.yNumericMax
			
			return kdtree.queryRange(minKDKey, maxKDKey);
		}

		private const _tempPoint1:Point = new Point(); // reusable object
		private const _tempPoint2:Point = new Point(); // reusable object
		private const _tempLineSegment:LineSegment = new LineSegment();
		
		/**
		 * This function should be used for queries on points from a GeometryPlotter only. 
		 * This function will not perform any type checking and must be used with caution.
		 * 
		 * @param bounds A bounds used to query the spatial index.
		 * @param xPrecision If specified, X distance values will be divided by this and truncated before comparing.
		 * @param yPrecision If specified, Y distance values will be divided by this and truncated before comparing.
		 * @return An array of keys with bounds that overlap the given bounds and are closest to the center of the given bounds.
		 */
		public function getKeysContainingBoundsCenter(bounds:IBounds2D, stopOnFirstFind:Boolean = false, xPrecision:Number = NaN, yPrecision:Number = NaN):Array
		{
			// TODO: make the parts be sorted by size so we check the largest part first?
			
			var xQueryCenter:Number = bounds.getXCenter();
			var yQueryCenter:Number = bounds.getYCenter();
			var queryRay:LineRay = new LineRay(xQueryCenter, yQueryCenter);
			var result:Array = [];
			var importance:Number;
			if (isNaN(xPrecision) || isNaN(yPrecision))
				importance = 0;
			else
				importance = xPrecision * yPrecision;
			
			// get the shapes that intersect with the given bounds
			var keys:Array = getOverlappingKeys(bounds);
			
			if (keys.length == 0)
				return result;
			
			var foundPart:Boolean = false;

			// for each key, get its geometries. Notice the use of the label to quickly exit the loop.
			outerLoop: for (var iKey:int = 0; iKey < keys.length; ++iKey)
			{
				var key:IQualifiedKey = keys[iKey];
				var column:IAttributeColumn = _keyToGeometryColumn[key] as IAttributeColumn;
				var geoms:Array = column.getValueFromKey(key) as Array;
				if (geoms == null)
					continue;
				
				// for each geom, check if one of its parts contains the point using ray casting
				for (var iGeom:int = 0; iGeom < geoms.length; ++iGeom)
				{
					// the current geometry
					var geom:GeneralizedGeometry = geoms[iGeom] as GeneralizedGeometry;

					// get the simplified geometry as a vector of parts
					var simplifiedGeom:Vector.<Vector.<BLGNode>> = geom.getSimplifiedGeometry(importance, bounds); 
					
					// for each part, go through the coordinates building a segment and checking if a ray from the
					// query center intersects it
					for (var iPart:int = 0; iPart < simplifiedGeom.length; ++iPart)
					{
						//_tempLineSegments.length = 0; // TODO: reuse the line segments but discard unused ones after the following part
						var currentPart:Vector.<BLGNode> = simplifiedGeom[iPart];
						var intersectionCount:int = 0;
						
						var kPoint:int = 0;
						var currentNode:BLGNode;
						// iterate through the points, two at a time
			
						while (kPoint < currentPart.length)
						{
							// store the first point of the segment
							currentNode = currentPart[kPoint];  
							_tempPoint1.x = currentNode.x;
							_tempPoint1.y = currentNode.y;
							++kPoint; // increment iterator
							
							// check if we're at the end of the vector of nodes
							if (kPoint == currentPart.length)
							{
								// set the first point of the part to be p2
								currentNode = currentPart[0];
							}
							else // still more points to read
							{
								// use the next point in the part
								currentNode = currentPart[kPoint];
							}
							
							_tempPoint2.x = currentNode.x;
							_tempPoint2.y = currentNode.y;
							
							// build the segment and check if the ray intersects it
							_tempLineSegment.beginPoint = _tempPoint1;
							_tempLineSegment.endPoint = _tempPoint2;
							_tempLineSegment.makeSlopePositive();
							if (ComputationalGeometryUtils.doesLineIntersectRay(_tempLineSegment, queryRay))
								++intersectionCount;
						}
						
						if (intersectionCount % 2 == 1 && kPoint > 0)
						{
							foundPart = true; // we found a part
							result.push(keys[iKey]); // save the key
							//trace((keys[iKey] as IQualifiedKey).keyType, (keys[iKey] as IQualifiedKey).localName);
							
							// determine whether to exit this main loop or continue
							if (stopOnFirstFind == true) 
								break outerLoop;
							else
								continue outerLoop;
						}
					}
				}
			}
			
			return result;
		}
		
		/**
		 * @param bounds A bounds used to query the spatial index.
		 * @param xPrecision If specified, X distance values will be divided by this and truncated before comparing.
		 * @param yPrecision If specified, Y distance values will be divided by this and truncated before comparing.
		 * @return An array of keys with bounds that overlap the given bounds and are closest to the center of the given bounds.
		 */
		public function getClosestOverlappingKeys(bounds:IBounds2D, xPrecision:Number = NaN, yPrecision:Number = NaN):Array
		{
			if (_lastUsedPlotter is GeometryPlotter)
				return getKeysContainingBoundsCenter(bounds, true, xPrecision, yPrecision);
			
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