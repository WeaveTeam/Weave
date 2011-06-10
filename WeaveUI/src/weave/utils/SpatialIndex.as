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
	import flash.ui.KeyLocation;
	import flash.utils.Dictionary;
	import flash.utils.clearTimeout;
	
	import weave.Weave;
	import weave.WeaveProperties;
	import weave.api.WeaveAPI;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.ISimpleGeometry;
	import weave.api.linkBindableProperty;
	import weave.api.primitives.IBounds2D;
	import weave.api.ui.IPlotter;
	import weave.api.ui.IPlotterWithGeometries;
	import weave.api.ui.ISpatialIndex;
	import weave.core.CallbackCollection;
	import weave.core.LinkableBoolean;
	import weave.data.AttributeColumns.GeometryColumn;
	import weave.data.QKeyManager;
	import weave.primitives.BLGNode;
	import weave.primitives.Bounds2D;
	import weave.primitives.GeneralizedGeometry;
	import weave.primitives.SimpleGeometry;
	import weave.primitives.KDTree;
	import weave.ui.probing.WeaveProbeTemplate;
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
		
		/**
		 * This function fills the spatial index with the data bounds of each record in a plotter.
		 * 
		 * @param plotter An IPlotter object to index.
		 */
		public function createIndex(plotter:IPlotter):void
		{
			delayCallbacks();
						
			var key:IQualifiedKey;
			var bounds:IBounds2D;
			var i:int;
			
			if (plotter is DynamicPlotter)
			{
				if ((plotter as DynamicPlotter).internalObject is IPlotterWithGeometries)
					_keyToGeometriesMap = new Dictionary();
				else 
					_keyToGeometriesMap = null;
			}
			
			_tempBounds.copyFrom(collectiveBounds);

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
					
					if (_keyToGeometriesMap != null)
					{
						var geoms:Array = ((plotter as DynamicPlotter).internalObject as IPlotterWithGeometries).getGeometriesFromRecordKey(key);
						_keyToGeometriesMap[key] = geoms;
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
				i = _keysArray.length;
				while (--i > -1)
				{
					key = _keysArray[i] as IQualifiedKey;
					for each (bounds in getBoundsFromKey(key))
					{
						// do not index shapes with undefined bounds
						//TODO: index shapes with missing bounds values into a different index
						if (!bounds.isUndefined())
						{
							_kdTree.insert([bounds.getXNumericMin(), bounds.getYNumericMin(), bounds.getXNumericMax(), bounds.getYNumericMax(), bounds.getArea()], key);
							collectiveBounds.includeBounds(bounds);
						}
					}
				}
			}
			
			// if there are keys
			if (_keysArray.length > 0 || !_tempBounds.equals(collectiveBounds))
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
			_kdTree.clear();
			collectiveBounds.reset();

			resumeCallbacks();
		}

		
		/**
		 * This function will get all keys whose collective bounds overlap the given bounds.
		 * 
		 * @param bounds A bounds used to query the spatial index.
		 * @return An array of keys with bounds that overlap the given bounds.
		 */
		public function getOverlappingKeys(bounds:IBounds2D, minImportance:Number = 0):Array
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
		 * This function will get the keys which intersect with the bounds.
		 * 
		 * @param bounds A bounds used to query the spatial index.
		 * @return An array of keys with bounds that overlap the given bounds.
		 */
		public function getKeysContainingBounds(bounds:IBounds2D, minImportance:Number = 0):Array
		{
			// first get the keys whose collective bounds overlap the bounds
			var keys:Array = getOverlappingKeys(bounds, 0);
			
			// if there are 0 keys
			if (keys.length == 0)
				return keys;
			
			// if this index isn't for an IPlotterWithGeometries OR the user wants legacy probing
			if (_keyToGeometriesMap == null || !Weave.properties.enableGeometryProbing.value == true)
				return keys;
			
			// define the bounds as a polygon
			setTempBounds(bounds);

			var result:Array = [];

			// for each key, look up its geometries 
			keyLoop: for (var i:int = keys.length - 1; i >= 0; --i)
			{
				var key:IQualifiedKey = keys[i];
				var geoms:Array = _keyToGeometriesMap[key];

				// for each geometry, get vertices, check type, and do proper geometric overlap
				for (var iGeom:int = 0; iGeom < geoms.length; ++iGeom)
				{
					var geom:Object = geoms[iGeom];

					if (geom is GeneralizedGeometry)
					{
						var genGeom:GeneralizedGeometry = geom as GeneralizedGeometry;
						var simplifiedGeom:Vector.<Vector.<BLGNode>> = genGeom.getSimplifiedGeometry(minImportance, bounds);
						
						// for each part, build the vertices polygon and check for the overlap
						for (var iPart:int = 0; iPart < simplifiedGeom.length; ++iPart)
						{
							// get the part
							var part:Vector.<BLGNode> = simplifiedGeom[iPart];
							if (part.length == 0) // if no points, continue
								continue;
							
							// determine the type of the GeneralizedGeometry
							switch (genGeom.geomType)
							{
								// if a line, check for bounds intersecting the line
								case GeneralizedGeometry.GEOM_TYPE_LINE:
									if (ComputationalGeometryUtils.polygonOverlapsLine(
										_tempBoundsPolygon, /* bounds polygon */ 
										part[0].x, part[0].y,
										part[1].x, part[1].y))
									{
										result.push(key);
										continue keyLoop;
									}
									break;
								
								// if a point, check for bounds overlapping the point
								case GeneralizedGeometry.GEOM_TYPE_POINT:
									if (ComputationalGeometryUtils.polygonOverlapsPoint(
										_tempBoundsPolygon, /* bounds polygon */ 
										part[0].x, part[0].x))
									{
										result.push(key);
										continue keyLoop;
									}
									break;
								
								// if a polygon, check for polygon overlap
								case GeneralizedGeometry.GEOM_TYPE_POLYGON:
									if (ComputationalGeometryUtils.polygonOverlapsPolygon(
										_tempBoundsPolygon, /* bounds polygon */
										part))
									{
										result.push(key);
										continue keyLoop;
									}
									break;
								
							}
						}
					}
					else // NOT a generalized geometry
					{
						var simpleGeom:ISimpleGeometry = geom as ISimpleGeometry;
						// get its vertices
						var vertices:Array = simpleGeom.getVertices();
						
						if (simpleGeom.isLine()) // if a line, check for bounds intersect line
						{
							if (ComputationalGeometryUtils.polygonOverlapsLine(
								_tempBoundsPolygon, /* polygon */ 
								vertices[0].x, vertices[0].y, /* point A on AB */
								vertices[1].x, vertices[1].y /* point B on AB */ ))
							{
								result.push(key);
								continue keyLoop;
							}
						}
						else if (simpleGeom.isPoint()) // if a point, check for point polygon overlap
						{
							if (ComputationalGeometryUtils.polygonOverlapsPoint(
								_tempBoundsPolygon, /* polygon */ 
								vertices[0].x, vertices[0].y /* point */))
							{
								result.push(key);
								continue keyLoop;
							}
						}
						else // a polygon, check for polygon overlap
						{
							if (ComputationalGeometryUtils.polygonOverlapsPolygon(
								_tempBoundsPolygon, /* bounds polygon */
								_tempGeometryPolygon /* vertices polygon */ ))
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
			// get the keys whose collective bounds overlap bounds (using importance 0)
			var keys:Array = getOverlappingKeys(bounds, 0);
			
			// if no keys, return the empty array
			if (keys.length == 0)
				return keys;
			
			// if this index is not for an IPlotterWithGeometries OR the user wants legacy probing, do the old function
			if (_keyToGeometriesMap == null || !Weave.properties.enableGeometryProbing.value == true)
				return getClosestKeys(keys, bounds, xPrecision, yPrecision);
			
			// the below code is only used for plotters which implement IPlotterWithGeometries and if the enableGeometryProbing property is true

			// calculate the importance value
			var importance:Number = (isNaN(xPrecision) || isNaN(yPrecision)) ? 0 : xPrecision * yPrecision;
			
			// get the center of the bounds which will be used for polygon and point overlap
			var xQueryCenter:Number = bounds.getXCenter();
			var yQueryCenter:Number = bounds.getYCenter();
			
			// define the _tempBoundsPolygon
			setTempBounds(bounds);
			
			var result:Array = [];
			
			var xVerticesCenter:Number;
			var yVerticesCenter:Number;
			
			// for each key, get its geometries
			keyLoop: for (var iKey:int = keys.length - 1; iKey >= 0; --iKey)
			{
				var key:IQualifiedKey = keys[iKey];
				var geoms:Array = _keyToGeometriesMap[key];
				
				// for each geom, check if one of its parts contains the query point using ray casting
				for (var iGeom:int = geoms.length - 1; iGeom >= 0; --iGeom)
				{
					// the current geometry
					var geom:Object = geoms[iGeom];

					// if it's a generalizedGeometry
					if (geom is GeneralizedGeometry)
					{
						var genGeom:GeneralizedGeometry = geom as GeneralizedGeometry;
						var simplifiedGeom:Vector.<Vector.<BLGNode>> = (geom as GeneralizedGeometry).getSimplifiedGeometry(importance, bounds); 
						
						for (var iPart:int = simplifiedGeom.length - 1; iPart >= 0; --iPart)
						{
							var currentPart:Vector.<BLGNode> = simplifiedGeom[iPart];
							
							if (currentPart.length == 0) 
								continue;
							
							if (genGeom.isPolygon())
							{
								if (ComputationalGeometryUtils.polygonOverlapsPolygon(currentPart, _tempBoundsPolygon))
								{
									result.push(key);
									continue keyLoop;
								}
							}
							else if (genGeom.isLine())
							{
								if (ComputationalGeometryUtils.polygonOverlapsLine(
									_tempBoundsPolygon,
									currentPart[0].x, currentPart[0].y, currentPart[1].x, currentPart[1].y))
								{
									result.push(key);
									continue keyLoop;
								}
							}
							else if (genGeom.isPoint())
							{
								if (ComputationalGeometryUtils.polygonOverlapsPoint(
									_tempBoundsPolygon,
									currentPart[0].x, currentPart[0].y))
								{
									result.push(key);
									continue keyLoop;
								}
							}
						} 
					} 
					else // not a generalized geometry
					{
						// get the simple geometry object
						var simpleGeom:ISimpleGeometry = geom as ISimpleGeometry;
						var vertices:Array = simpleGeom.getVertices();
						
						// if it's a polygon, check point in polygon with query center
						if (simpleGeom.isPolygon())
						{
							if (ComputationalGeometryUtils.polygonOverlapsPolygon(
								vertices, /* polygon */ 
								_tempBoundsPolygon /* bounds polygon */ ))
							{
								result.push(key);								
								continue keyLoop; // break because it's the closest
							}
						}
						else if (simpleGeom.isLine()) // if line, check overlap with the polygon 
						{
							if (ComputationalGeometryUtils.polygonOverlapsLine(
								_tempBoundsPolygon,
								vertices[0].x, vertices[0].y,
								vertices[1].x, vertices[1].y))
							{
								result.push(key);									
								continue keyLoop; 
							}								
						}
						else if (simpleGeom.isPoint()) // if point, check overlap with polygon
						{
							if (ComputationalGeometryUtils.polygonOverlapsPoint(
								_tempBoundsPolygon,
								vertices[0].x, vertices[0].y))
							{
								result.push(key);										
								continue keyLoop;
							}	
						}
					} 					
				} // end geom loop
			} // end key loop
			
			// get the closest using exact containment algorithms
			return getClosestKeys(result, bounds, xPrecision, yPrecision);
		}
		
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
		 * This function will get the keys closest the center of the bounds object. This function is used primarily
		 * for plotters whose records are drawn as points, rectangles, and circles. 
		 * 
		 * @param keys An array of keys whose collective bounds overlaps the bounds.
		 * @param bounds A bounds used to query the spatial index.
		 * @param xPrecision If specified, X distance values will be divided by this and truncated before comparing.
		 * @param yPrecision If specified, Y distance values will be divided by this and truncated before comparing.
		 * @return An array of IQualifiedKey objects. 
		 */		
		public function getClosestKeys(keys:Array, bounds:IBounds2D, xPrecision:Number, yPrecision:Number):Array
		{
			var importance:Number = xPrecision * yPrecision;
			
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
			var tempDistance:Number;
			// begin with a result of zero shapes
			var result:Array = [];
			var resultCount:int = 0;
			for (var iKey:int = 0; iKey < keys.length; ++iKey)
			{
				var key:IQualifiedKey = keys[iKey];
				var overlapsQueryCenter:Boolean = false;
				
				// if the plotter wasn't an IPlotterWithGeometries or if the user wants the old probing
				if (_keyToGeometriesMap == null || Weave.properties.enableGeometryProbing.value == false)
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
						for each (var geom:Object in geoms)
						{
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
								var genGeomBounds:IBounds2D = genGeom.bounds;
								
								var simplifiedGeom:Vector.<Vector.<BLGNode>> = (geom as GeneralizedGeometry).getSimplifiedGeometry(importance, bounds);

								for (var i:int = 0; i < simplifiedGeom.length; ++i)
								{
									var part:Vector.<BLGNode> = simplifiedGeom[i];
									
									if (genGeom.isPolygon())
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
									else if (genGeom.isLine())
									{
										distanceSq = ComputationalGeometryUtils.getUnscaledDistanceFromLine(
											part[0].x, part[0].y, part[1].x, part[1].y,
											xQueryCenter, yQueryCenter);
										
										if (distanceSq <= Number.MIN_VALUE)
											overlapsQueryCenter = true;
										else
											overlapsQueryCenter = false;
									}
									else if (genGeom.isPoint())
									{
										distanceSq = ComputationalGeometryUtils.getDistanceFromPointSq(
											part[0].x, part[0].y, xQueryCenter, yQueryCenter);
										if (distanceSq <= Number.MIN_VALUE)
											overlapsQueryCenter = true;
										else 
											overlapsQueryCenter = false;										
									}
									
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
							else  
							{
								var simpleGeom:ISimpleGeometry = geom as ISimpleGeometry;
								var vertices:Array = simpleGeom.getVertices();
								
								// calculate the distanceSq and overlapsQueryCenter
								if (simpleGeom.isPolygon())
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
								else if (simpleGeom.isLine())
								{
									distanceSq = ComputationalGeometryUtils.getUnscaledDistanceFromLine(
										vertices[0].x, vertices[0].y, vertices[1].x, vertices[1].y,
										xQueryCenter, yQueryCenter);
									if (distanceSq <= Number.MIN_VALUE)
										overlapsQueryCenter = true;
									else
										overlapsQueryCenter = false;
								}
								else if (simpleGeom.isPoint())
								{
									distanceSq = ComputationalGeometryUtils.getDistanceFromPointSq(
										vertices[0].x, vertices[0].y, xQueryCenter, yQueryCenter);
									if (distanceSq <= Number.MIN_VALUE)
										overlapsQueryCenter = true;
									else 
										overlapsQueryCenter = false;
								}
								
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
					} // geomLoop
				} // if else
			} // keyLoop
			
			result.length = resultCount;
			return result;
		}

		private const _tempCenterPoint:Point = new Point();
		private function getCenterPoint(polygon:Array, output:Point = null):Point
		{
			var x:Number = 0;
			var y:Number = 0;
			var numNodes:int = polygon.length;
			
			for each (var obj:Object in polygon)
			{
				x += obj.x;
				y += obj.y;
			}
			
			if (output == null)
				output = new Point();
			
			output.x = x / numNodes;
			output.y = y / numNodes;
			return output;
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
		private const _tempArray:Array = [];
		private const _tempBoundsPolygon:Array = [new Point(), new Point(), new Point(), new Point(), new Point()];
		private const _tempGeometryPolygon:Array = [];
		private const _tempVertices:Array = [];
	}
}