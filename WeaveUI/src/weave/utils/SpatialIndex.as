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
	import weave.api.ui.ISpatialIndexImplementation;
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
		}

		/**
		 * This is the implementation of an index for a specific IPlotter.
		 */
		private var _indexImplementation:ISpatialIndexImplementation = null;
		
		/**
		 * collectiveBounds
		 * This bounds represents the full extent of the shape index.
		 */
		public const collectiveBounds:IBounds2D = new Bounds2D();

		/**
		 * This function gets a list of Bounds2D objects associated with a key.
		 * @param key A record key.
		 * @result An Array of Bounds2D objects associated with the key.
		 */
		public function getBoundsFromKey(key:IQualifiedKey):Array
		{
			return _indexImplementation.getBoundsFromKey(key);
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
						
			_indexImplementation = SpatialIndexFactory.getImplementation(plotter);

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
					_indexImplementation.cacheKey(key);
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
					for each (bounds in _indexImplementation.getBoundsFromKey(key))
					{
						// do not index shapes with undefined bounds
						//TODO: index shapes with missing bounds values into a different index
						if (!bounds.isUndefined())
						{
							kdtree.insert([bounds.getXNumericMin(), bounds.getYNumericMin(), bounds.getXNumericMax(), bounds.getYNumericMax(), bounds.getArea()], key); 
							collectiveBounds.includeBounds(bounds);
						}
					}
				}
			}
			
			// if there are keys
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
		public function getKeysOverlappingPoint(point:Point):Array
		{
			// this function isn't used
			
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
			var keys:Array = getKeysInRectangularRange(bounds, minImportance);
			return _indexImplementation.getKeysOverlappingBounds(keys, bounds, 1, minImportance);
		}


		/**
		 * This function will find all keys whose collective bounds overlap the given bounds object.
		 * The collective bounds is defined as a rectangle which contains every point in the key.
		 * 
		 * @param bounds The bounds for the spatial query.
		 * @param minImportance The minimum importance of which to query.
		 * @return An array of keys with bounds that overlap the given bounds with the specific importance.
		 */		
		private function getKeysInRectangularRange(bounds:IBounds2D, minImportance:Number = 0):Array
		{
			// TEMPORARY: Make this be performed by the implementations so they can ignore the importance value or not
			if (!(_indexImplementation is GeometrySpatialIndex))
				minImportance = 0;
			
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
		 * This function will return the keys closest to the center of the bounds object.
		 * 
		 * @param bounds A bounds used to query the spatial index.
		 * @param xPrecision If specified, X distance values will be divided by this and truncated before comparing.
		 * @param yPrecision If specified, Y distance values will be divided by this and truncated before comparing.
		 * @return An array of keys with bounds that overlap the given bounds and are closest to the center of the given bounds.
		 */
		public function getClosestOverlappingKeys(bounds:IBounds2D, xPrecision:Number = NaN, yPrecision:Number = NaN):Array
		{
			var keys:Array = getKeysInRectangularRange(bounds);
			return _indexImplementation.getKeysContainingBoundsCenter(keys, bounds, true, xPrecision, yPrecision);
		}
		
		// reusable temporary objects
		private static const tempBounds:IBounds2D = new Bounds2D();
	}
}