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
	
	import weave.Weave;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.ISimpleGeometry;
	import weave.api.primitives.IBounds2D;
	import weave.api.ui.IPlotter;
	import weave.api.ui.IPlotterWithGeometries;
	import weave.api.ui.ISpatialIndex;
	import weave.core.CallbackCollection;
	import weave.core.StageUtils;
	import weave.primitives.BLGNode;
	import weave.primitives.Bounds2D;
	import weave.primitives.GeneralizedGeometry;
	import weave.primitives.KDTree;
	import weave.primitives.SimpleGeometry;
	import weave.visualization.plotters.DynamicPlotter;
	
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
		// TODO: Refactor to use image/color hits instead. The image hits should use some sort of trapezoidal or triangular grid.
		
		public function SpatialIndex(callback:Function = null, callbackParameters:Array = null)
		{
			addImmediateCallback(this, callback, callbackParameters);
		}
		
		private var _kdTree:KDTree = new KDTree(5);
		private var _keyToBoundsMap:Dictionary = new Dictionary();
		
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
			var result:Array = _keyToBoundsMap[key] as Array;
			
			if (result == null)
				result = [];
			
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
			return _kdTree.nodeCount;
		}
		
		private var _keyToGeometriesMap:Dictionary = new Dictionary();
		private var _plotter:IPlotter;
		private var _queryMissingBounds:Boolean;
		private var _spatialCallbacksTriggerCounter:uint = 0;
		
		/**
		 * This function fills the spatial index with the data bounds of each record in a plotter.
		 * 
		 * @param plotter An IPlotter object to index.
		 */
		public function createIndex(plotter:IPlotter, queryMissingBounds:Boolean = false):void
		{
			_plotter = plotter;
			_queryMissingBounds = queryMissingBounds;
			
			delayCallbacks();
			
			var key:IQualifiedKey;
			var bounds:IBounds2D;
			var i:int;
			
			if (_plotter is DynamicPlotter)
			{
				if ((_plotter as DynamicPlotter).internalObject is IPlotterWithGeometries)
					_keyToGeometriesMap = new Dictionary();
				else 
					_keyToGeometriesMap = null;
			}
			
			_tempBounds.copyFrom(collectiveBounds);
			
			clear();
			
			if (_plotter != null)
			{
				collectiveBounds.copyFrom(_plotter.getBackgroundDataBounds());
				
				// make a copy of the keys vector
				VectorUtils.copy(_plotter.keySet.keys, _keysArray);
				
				// save dataBounds for each key
				i = _keysArray.length;
				while (--i > -1)
				{
					key = _keysArray[i] as IQualifiedKey;
					_keyToBoundsMap[key] = _plotter.getDataBoundsFromRecordKey(key);
					
					if (_keyToGeometriesMap != null)
					{
						var geoms:Array = ((_plotter as DynamicPlotter).internalObject as IPlotterWithGeometries).getGeometriesFromRecordKey(key);
						_keyToGeometriesMap[key] = geoms;
					}
				}
			}
			
			// if auto-balance is disabled, randomize insertion order
			if (!_kdTree.autoBalance)
			{
				// randomize the order of the shapes to avoid a possibly poorly-performing
				// KDTree structure due to the given ordering of the records
				VectorUtils.randomSort(_keysArray);
			}
			
			// insert bounds-to-key mappings in the kdtree
			StageUtils.startTask(this, _insertNext);
			
			if (!_tempBounds.equals(collectiveBounds))
				triggerCallbacks();
			
			resumeCallbacks();
		}
		private function _insertNext():Number
		{
			if (_keysArrayIndex >= _keysArray.length) // in case length is zero
				return 1; // done
			
			var key:IQualifiedKey = _keysArray[_keysArrayIndex] as IQualifiedKey;
			if (!_boundsArray) // is there an existing nested array?
			{
				//trace(key.keyType,key.localName,'(',_keysArrayIndex,'/',_keysArray.length,')');
				_boundsArray = getBoundsFromKey(key);
				_boundsArrayIndex = 0;
			}
			if (_boundsArrayIndex < _boundsArray.length) // iterate on nested array
			{
				//trace('bounds(',_boundsArrayIndex,'/',_boundsArray.length,')');
				var bounds:IBounds2D = _boundsArray[_boundsArrayIndex] as IBounds2D;
				// do not index shapes with undefined bounds
				//TODO: index shapes with missing bounds values into a different index
				// TEMPORARY SOLUTION: store missing bounds if queryMissingBounds == true
				if (!bounds.isUndefined() || _queryMissingBounds)
				{
					_kdTree.insert([bounds.getXNumericMin(), bounds.getYNumericMin(), bounds.getXNumericMax(), bounds.getYNumericMax(), bounds.getArea()], key);
					collectiveBounds.includeBounds(bounds);
				}
				// increment inner index
				_boundsArrayIndex++;
			}
			if (_boundsArrayIndex == _boundsArray.length)
			{
				// all done with nested array
				_boundsArray = null;
				// increment outer index
				_keysArrayIndex++;
			}
			
			var progress:Number = _keysArrayIndex / _keysArray.length;
			if (progress == 1) // done?
				triggerCallbacks();
			return progress;
		}
		
		private var _keysArrayIndex:int;
		private var _boundsArrayIndex:int;
		private var _boundsArray:Array;
		
		
		/**
		 * This function empties the spatial index.
		 */
		public function clear():void
		{
			delayCallbacks();
			
			if (_keysArray.length > 0)
				triggerCallbacks();
			
			_boundsArray = null;
			_keysArrayIndex = 0;
			_keysArray.length = 0;
			_kdTree.clear();
			collectiveBounds.reset();
			
			resumeCallbacks();
		}
		
		private function polygonOverlapsPolyLine(polygon:Array, line:Object):Boolean
		{
			for (var i:int = 0; i < line.length - 1; ++i)
			{
				if (ComputationalGeometryUtils.polygonOverlapsLine(_tempBoundsPolygon, line[i].x, line[i].y, line[i + 1].x, line[i + 1].y))
				{
					return true;
				}
			}
			
			return false;		
		}
		private function polygonOverlapsPolyPoint(polygon:Array, point:Object):Boolean
		{
			for (var i:int = 0; i < point.length; ++i)
			{
				if (ComputationalGeometryUtils.polygonOverlapsPoint(_tempBoundsPolygon, point[i].x, point[i].y))
					return true;
			}
			
			return false;
		}
		private function getMinimumUnscaledDistanceFromPolyLine(line:Object, x:Number, y:Number):Number
		{
			var min:Number = Number.POSITIVE_INFINITY;
			for (var i:int = 0; i < line.length - 1; ++i)
			{
				var distance:Number = ComputationalGeometryUtils.getUnscaledDistanceFromLine(line[i].x, line[i].y, line[i + 1].x, line[i + 1].y, x, y);
				min = Math.min(distance, min);
			}			
			return min;
		}
		private function getMinimumUnscaledDistanceFromPolyPoint(line:Object, x:Number, y:Number):Number
		{
			var min:Number = Number.POSITIVE_INFINITY;
			for (var i:int = 0; i < line.length; ++i)
			{
				var distance:Number = ComputationalGeometryUtils.getDistanceFromPointSq(line[i].x, line[i].y, x, y);
				min = Math.min(distance, min);
			}			
			return min;
		}
		/**
		 * This function will get the keys whose bounding boxes intersect with the given bounds.
		 * 
		 * @param bounds A bounds used to query the spatial index.
		 * @param minImportance The minimum importance value imposed on the resulting keys. 
		 * @return An array of keys.
		 */
		public function getKeysBoundingBoxOverlap(bounds:IBounds2D, minImportance:Number = 0):Array
		{
			// This is a filter for bounding boxes and should be used for getting fast results
			// during panning and zooming.
			
			// set the minimum query values for shape.bounds.xMax, shape.bounds.yMax
			minKDKey[XMAX_INDEX] = bounds.getXNumericMin(); // enforce result.XMAX >= query.xNumericMin
			minKDKey[YMAX_INDEX] = bounds.getYNumericMin(); // enforce result.YMAX >= query.yNumericMin
			minKDKey[IMPORTANCE_INDEX] = minImportance; // enforce result.IMPORTANCE >= minImportance
			// set the maximum query values for shape.bounds.xMin, shape.bounds.yMin
			maxKDKey[XMIN_INDEX] = bounds.getXNumericMax(); // enforce result.XMIN <= query.xNumericMax
			maxKDKey[YMIN_INDEX] = bounds.getYNumericMax(); // enforce result.YMIN <= query.yNumericMax
			
			return _kdTree.queryRange(minKDKey, maxKDKey);
		}
		
		/**
		 * This function will get the keys whose geometries intersect with the given bounds.
		 * 
		 * @param bounds A bounds used to query the spatial index.
		 * @param minImportance The minimum importance value to use when determining geometry overlap.
		 * @param filterBoundingBoxesByImportance If true, bounding boxes will be pre-filtered by importance before checking geometry overlap.
		 * @return An array of keys.
		 */
		public function getKeysGeometryOverlap(queryBounds:IBounds2D, minImportance:Number = 0, filterBoundingBoxesByImportance:Boolean = false, dataBounds:IBounds2D = null):Array
		{
			var keys:Array = getKeysBoundingBoxOverlap(queryBounds, filterBoundingBoxesByImportance ? minImportance : 0);
			
			// if this index isn't for an IPlotterWithGeometries OR the user wants legacy probing
			if (_keyToGeometriesMap == null || !Weave.properties.enableGeometryProbing.value)
				return keys;
			
			// if there are 0 keys
			if (keys.length == 0)
				return keys;
			
			// define the bounds as a polygon
			setTempBounds(queryBounds);
			
			var result:Array = [];
			
			// for each key, look up its geometries 
			keyLoop: for (var i:int = keys.length - 1; i >= 0; --i)
			{
				var key:IQualifiedKey = keys[i];
				var geoms:Array = _keyToGeometriesMap[key];
				
				if (geoms.length == 0)
				{
					result.push(key);
					continue keyLoop;
				}
				
				// for each geometry, get vertices, check type, and do proper geometric overlap
				for (var iGeom:int = 0; iGeom < geoms.length; ++iGeom)
				{
					var geom:Object = geoms[iGeom];
					
					if (geom is GeneralizedGeometry)
					{
						var genGeom:GeneralizedGeometry = geom as GeneralizedGeometry;
						var genGeomIsPoly:Boolean = genGeom.isPolygon();
						var genGeomIsLine:Boolean = genGeom.isLine();
						var genGeomIsPoint:Boolean = genGeom.isPoint();
						var simplifiedGeom:Vector.<Vector.<BLGNode>> = genGeom.getSimplifiedGeometry(minImportance, dataBounds);
						
						if (simplifiedGeom.length == 0)
						{
							result.push(key);
							continue keyLoop;
						}
						
						// for each part, build the vertices polygon and check for the overlap
						for (var iPart:int = 0; iPart < simplifiedGeom.length; ++iPart)
						{
							// get the part
							var part:Vector.<BLGNode> = simplifiedGeom[iPart];
							if (part.length == 0) // if no points, continue
								continue;
							
							// if a polygon, check for polygon overlap
							if (genGeomIsPoly)
							{
								if (ComputationalGeometryUtils.polygonOverlapsPolygon(_tempBoundsPolygon, part))
								{
									result.push(key);
									continue keyLoop;
								}
							}
							else if (genGeomIsLine)
							{
								if (polygonOverlapsPolyLine(_tempBoundsPolygon, part))
								{
									result.push(key);
									continue keyLoop;
								}
							}
							else // point
							{
								if (polygonOverlapsPolyPoint(_tempBoundsPolygon, part))
								{
									result.push(key);
									continue keyLoop;
								}
							}
						}
					}
					else // NOT a generalized geometry
					{
						var simpleGeom:ISimpleGeometry = geom as ISimpleGeometry;
						var simpleGeomIsPoly:Boolean = simpleGeom.isPolygon();
						var simpleGeomIsLine:Boolean = simpleGeom.isLine();
						var simpleGeomIsPoint:Boolean = simpleGeom.isPoint();
						// get its vertices
						var vertices:Array = simpleGeom.getVertices();
						
						if (simpleGeomIsPoly)// a polygon, check for polygon overlap
						{
							if (ComputationalGeometryUtils.polygonOverlapsPolygon(_tempBoundsPolygon, vertices))
							{
								result.push(key);
								continue keyLoop;
							}
						}
						else if (simpleGeomIsLine) // if a line, check for bounds intersect line
						{
							if (polygonOverlapsPolyLine(_tempBoundsPolygon, vertices))
							{
								result.push(key);
								continue keyLoop;
							}
						}
						else
						{
							if (polygonOverlapsPolyPoint(_tempBoundsPolygon, vertices))
							{
								result.push(key);
								continue keyLoop;
							}
						}
						
					}
				} // end for each (var geom...
			} // end for each (var key...
			
			return result; 
		} // end function
		
		private var _keyToDistance:Dictionary = null;
		private function setTempBounds(bounds:IBounds2D):void
		{
			var b:Bounds2D = bounds as Bounds2D;
			var xMin:Number = b.xMin;
			var yMin:Number = b.yMin;
			var xMax:Number = b.xMax;
			var yMax:Number = b.yMax;
			_tempBoundsPolygon[0].x = xMin; _tempBoundsPolygon[0].y = yMin;
			_tempBoundsPolygon[1].x = xMin; _tempBoundsPolygon[1].y = yMax;
			_tempBoundsPolygon[2].x = xMax; _tempBoundsPolygon[2].y = yMax;
			_tempBoundsPolygon[3].x = xMax; _tempBoundsPolygon[3].y = yMin;
			_tempBoundsPolygon[4].x = xMin; _tempBoundsPolygon[4].y = yMin;
		}
		
		/**
		 * This function will get the keys closest the center of the bounds object. Generally this function will
		 * return an array of at most one key. Sometimes, it may return more than one key if there are multiple keys
		 * with equivalent distance to the center of the bounds object.
		 * 
		 * @param bounds A bounds used to query the spatial index.
		 * @param xPrecision If specified, X distance values will be divided by this and truncated before comparing.
		 * @param yPrecision If specified, Y distance values will be divided by this and truncated before comparing.
		 * @return An array of IQualifiedKey objects. 
		 */		
		public function getClosestOverlappingKeys(queryBounds:IBounds2D, xPrecision:Number, yPrecision:Number, dataBounds:IBounds2D):Array
		{
			var importance:Number = xPrecision * yPrecision;
			var keys:Array = getKeysGeometryOverlap(queryBounds, importance, false, dataBounds);
			
			// init local vars
			var closestDistanceSq:Number = Infinity;
			var xDistance:Number;
			var yDistance:Number;
			var distanceSq:Number;
			var xRecordCenter:Number;
			var yRecordCenter:Number;
			var recordBounds:IBounds2D;
			var xQueryCenter:Number = queryBounds.getXCenter();
			var yQueryCenter:Number = queryBounds.getYCenter();
			var foundQueryCenterOverlap:Boolean = false; // true when we found a key that overlaps the center of the given bounds
			var tempDistance:Number;
			// begin with a result of zero shapes
			var result:Array = [];
			var resultCount:int = 0;
			for (var iKey:int = 0; iKey < keys.length; ++iKey)
			{
				var key:IQualifiedKey = keys[iKey];
				var overlapsQueryCenter:Boolean = false;
				
				// if the plotter wasn't an IPlotterWithGeometries or if the user wants the old probing
				if (_keyToGeometriesMap == null || !Weave.properties.enableGeometryProbing.value)
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
						
						overlapsQueryCenter = recordBounds.contains(xQueryCenter, yQueryCenter);
						
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
				else // the plotter is an IPlotterWithGeometries and the user wants geometry probing
				{
					var geoms:Array = _keyToGeometriesMap[key];
					
					for (var iGeom:int = 0; iGeom < geoms.length; ++iGeom)
					{
						var geom:Object = geoms[iGeom];
						xDistance = geom.bounds.getXCenter() - xQueryCenter;
						yDistance = geom.bounds.getYCenter() - yQueryCenter;
						if (!isNaN(xPrecision) && xPrecision != 0)
							xDistance = int(xDistance / xPrecision);
						if (!isNaN(yPrecision) && yPrecision != 0)
							yDistance = int(yDistance / yPrecision);
						var geomDistance:Number = xDistance * xDistance + yDistance * yDistance; 
						
						if (geom is GeneralizedGeometry)
						{
							var genGeom:GeneralizedGeometry = geom as GeneralizedGeometry;
							var genGeomIsPoly:Boolean = genGeom.isPolygon();
							var genGeomIsLine:Boolean = genGeom.isLine();
							var genGeomIsPoint:Boolean = genGeom.isPoint();
							var genGeomBounds:IBounds2D = genGeom.bounds;
							var simplifiedGeom:Vector.<Vector.<BLGNode>> = (geom as GeneralizedGeometry).getSimplifiedGeometry(importance, dataBounds);
							
							for (var i:int = 0; i < simplifiedGeom.length; ++i)
							{
								var part:Vector.<BLGNode> = simplifiedGeom[i];
								
								if (genGeomIsPoly)
								{
									// if the polygon contains the point, this key is probably what we want
									if (ComputationalGeometryUtils.polygonOverlapsPoint(part, xQueryCenter, yQueryCenter))
									{
										distanceSq = 0;
										overlapsQueryCenter = true;
									}
									else
									{
										distanceSq = geomDistance;
										overlapsQueryCenter = false;
									}
								}
								else if (genGeomIsLine)
								{
									distanceSq = getMinimumUnscaledDistanceFromPolyLine(part, xQueryCenter, yQueryCenter);
									
									if (distanceSq <= Number.MIN_VALUE)
										overlapsQueryCenter = true;
									else
										overlapsQueryCenter = false;
								}
								else if (genGeomIsPoint)
								{
									distanceSq = getMinimumUnscaledDistanceFromPolyPoint(part, xQueryCenter, yQueryCenter);
									if (distanceSq <= Number.MIN_VALUE)
										overlapsQueryCenter = true;
									else 
										overlapsQueryCenter = false;										
								}
								
								// Consider all keys until we have found one that overlaps the query center.
								// Consider lines and points because although they may not overlap, it's very likely that no points or lines
								// will overlap. If we consider all of them, we can still find the closest.
								// After that, only consider keys that overlap query center.
								if (!foundQueryCenterOverlap || overlapsQueryCenter || genGeomIsLine || genGeomIsPoint)
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
						else  
						{
							var simpleGeom:ISimpleGeometry = geom as ISimpleGeometry;
							var simpleGeomIsPoly:Boolean = simpleGeom.isPolygon();
							var simpleGeomIsLine:Boolean = simpleGeom.isLine();
							var simpleGeomIsPoint:Boolean = simpleGeom.isPoint();
							var vertices:Array = simpleGeom.getVertices();
							
							// calculate the distanceSq and overlapsQueryCenter
							if (simpleGeomIsPoly)
							{
								if (ComputationalGeometryUtils.polygonOverlapsPoint(
									vertices, xQueryCenter, yQueryCenter))
								{
									distanceSq = 0;
									overlapsQueryCenter = true;
								}
								else 
								{
									distanceSq = geomDistance;
									overlapsQueryCenter = false;
								}
							}
							else if (simpleGeomIsLine)
							{
								distanceSq = getMinimumUnscaledDistanceFromPolyLine(vertices, xQueryCenter, yQueryCenter);
								if (distanceSq <= Number.MIN_VALUE)
									overlapsQueryCenter = true;
								else
									overlapsQueryCenter = false;
							}
							else if (simpleGeomIsPoint)
							{
								distanceSq = getMinimumUnscaledDistanceFromPolyPoint(vertices, xQueryCenter, yQueryCenter);
								if (distanceSq <= Number.MIN_VALUE)
									overlapsQueryCenter = true;
								else 
									overlapsQueryCenter = false;
							}
							
							// Consider all keys until we have found one that overlaps the query center.
							// Consider lines and points because although they may not overlap, it's very likely that no points or lines
							// will overlap. If we consider all of them, we can still find the closest.
							// After that, only consider keys that overlap query center.
							if (!foundQueryCenterOverlap || overlapsQueryCenter || simpleGeomIsLine || simpleGeomIsPoint)
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
					} // geomLoop
				} // if else
			} // keyLoop
			
			result.length = resultCount;
			return result;
		}

		/**
		 * This function will get the keys whose geometries intersect with the given geometry.
		 * 
		 * @param geometry An ISimpleGeometry object used to query the spatial index.
		 * @param minImportance The minimum importance value to use when determining geometry overlap.
		 * @param filterBoundingBoxesByImportance If true, bounding boxes will be pre-filtered by importance before checking geometry overlap.
		 * @return An array of keys.
		 */		
		public function getKeysGeometryOverlapGeometry(geometry:ISimpleGeometry, minImportance:Number = 0, filterBoundingBoxesByImportance:Boolean = false):Array
		{
			// first filter by bounds
			var point:Object;
			var queryGeomVertices:Array = geometry.getVertices();
			var keys:Array = getKeysBoundingBoxOverlap((geometry as SimpleGeometry).bounds, filterBoundingBoxesByImportance ? minImportance : 0);
			
			if (!Weave.properties.enableGeometryProbing.value || _keyToGeometriesMap == null)
				return keys;
			
			var result:Array = [];
			
			// for each key, look up its geometries 
			keyLoop: for (var i:int = keys.length - 1; i >= 0; --i)
			{
				var key:IQualifiedKey = keys[i];
				var geoms:Array = _keyToGeometriesMap[key];
				
				if (geoms.length == 0)
				{
					result.push(key);
					continue keyLoop;
				}
				
				// for each geometry, get vertices, check type, and do proper geometric overlap
				for (var iGeom:int = 0; iGeom < geoms.length; ++iGeom)
				{
					var geom:Object = geoms[iGeom];
					
					if (geom is GeneralizedGeometry)
					{
						var genGeom:GeneralizedGeometry = geom as GeneralizedGeometry;
						var genGeomIsPoly:Boolean = genGeom.isPolygon();
						var genGeomIsLine:Boolean = genGeom.isLine();
						var genGeomIsPoint:Boolean = genGeom.isPoint();
						var simplifiedGeom:Vector.<Vector.<BLGNode>> = genGeom.getSimplifiedGeometry(minImportance, _tempSimpleGeomBounds);
						
						if (simplifiedGeom.length == 0)
						{
							result.push(key);
							continue keyLoop;
						}
						
						// for each part, build the vertices polygon and check for the overlap
						for (var iPart:int = 0; iPart < simplifiedGeom.length; ++iPart)
						{
							// get the part
							var part:Vector.<BLGNode> = simplifiedGeom[iPart];
							if (part.length == 0) // if no points, continue
								continue;
							
							// if a polygon, check for polygon overlap
							if (genGeomIsPoly)
							{
								if (ComputationalGeometryUtils.polygonOverlapsPolygon(queryGeomVertices, part))
								{
									result.push(key);
									continue keyLoop;
								}
							}
							else if (genGeomIsLine)
							{
								if (polygonOverlapsPolyLine(queryGeomVertices, part))
								{
									result.push(key);
									continue keyLoop;
								}
							}
							else // point
							{
								if (polygonOverlapsPolyPoint(queryGeomVertices, part))
								{
									result.push(key);
									continue keyLoop;
								}
							}
						}
					}
					else // NOT a generalized geometry
					{
						var simpleGeom:ISimpleGeometry = geom as ISimpleGeometry;
						var simpleGeomIsPoly:Boolean = simpleGeom.isPolygon();
						var simpleGeomIsLine:Boolean = simpleGeom.isLine();
						var simpleGeomIsPoint:Boolean = simpleGeom.isPoint();
						// get its vertices
						var vertices:Array = simpleGeom.getVertices();
						
						if (simpleGeomIsPoly)// a polygon, check for polygon overlap
						{
							if (ComputationalGeometryUtils.polygonOverlapsPolygon(queryGeomVertices, vertices))
							{
								result.push(key);
								continue keyLoop;
							}
						}
						else if (simpleGeomIsLine) // if a line, check for bounds intersect line
						{
							if (polygonOverlapsPolyLine(queryGeomVertices, vertices))
							{
								result.push(key);
								continue keyLoop;
							}
						}
						else
						{
							if (polygonOverlapsPolyPoint(queryGeomVertices, vertices))
							{
								result.push(key);
								continue keyLoop;
							}
						}
						
					}
				} // end for each (var geom...
			} // end for each (var key...
			
			return result; 
		}
		
		/**
		 * These constants define indices in a KDKey corresponding to xmin,ymin,xmax,ymax,importance values.
		 */
		private const XMIN_INDEX:int = 0, YMIN_INDEX:int = 1;
		private const XMAX_INDEX:int = 2, YMAX_INDEX:int = 3;
		private const IMPORTANCE_INDEX:int = 4;
		
		/**
		 * These KDKey arrays are created once and reused to avoid unnecessary creation of objects.
		 * The only values that change are the ones that are undefined here.
		 */
		private var minKDKey:Array = [Number.NEGATIVE_INFINITY, Number.NEGATIVE_INFINITY, NaN, NaN, 0];
		private var maxKDKey:Array = [NaN, NaN, Number.POSITIVE_INFINITY, Number.POSITIVE_INFINITY, Number.POSITIVE_INFINITY];

		
		// reusable temporary objects
		private const _tempBounds:IBounds2D = new Bounds2D();
		private const _tempSimpleGeomBounds:IBounds2D = new Bounds2D();			
		private const _tempArray:Array = [];
		private const _tempBoundsPolygon:Array = [new Point(), new Point(), new Point(), new Point(), new Point()];
		private const _tempGeometryPolygon:Array = [];
		private const _tempVertices:Array = [];
	}
}
