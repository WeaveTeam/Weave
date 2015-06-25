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

package weave.utils
{
	import flash.errors.EOFError;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.linkableObjectIsBusy;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.reportError;
	import weave.compiler.StandardLib;
	import weave.core.CallbackCollection;
	import weave.primitives.Bounds2D;
	import weave.primitives.Dictionary2D;
	import weave.primitives.GeneralizedGeometry;
	import weave.primitives.GeometryType;
	import weave.primitives.KDTree;

	/**
	 * This class provides functions for parsing a binary geometry stream.
	 * The callbacks for this object get called when all queued decoding completes.
	 * 
	 * Throughout the code, an ID refers to an integer value, while a Key is a string value.
	 * Binary format:
	 *   tile descriptor format: [float minImportance, float maxImportance, double xMin, double yMin, double xMax, double yMax]
	 *       stream tile format: [int negativeTileID, negative streamVersion or binary stream object beginning with positive int, ...]
	 *   metadata stream object: [int geometryID, String geometryKey, '\0', double xMin, double yMin, double xMax, double yMax, int vertexID1, ..., int vertexID(n), int -1 if no shapeType follows or -2 if shapeType follows, int optionalShapeType]
	 *   geometry stream object: [int geometryID1, int vertexID1, ..., int geometryID(n-1), int vertexID(n-1), int geometryID(n), int negativeVertexID(n), double x, double y, float importance]
	 *   geometry stream marker: [int geometryID1, int vertexID1, ..., int geometryID(n), int vertexID(n), int -1]
	 *   geometry stream marker: [int geometryID, int vertexID_begin, int -2, int vertexID_end]
	 * 
	 * @author adufilie
	 */
	public class GeometryStreamDecoder implements ILinkableObject
	{
		public static var debug:Boolean = true;
		public var totalGeomTiles:int = 0;
		public var totalVertices:int = 0;
		
		private var streamVersion:int = 0;
		
		public function GeometryStreamDecoder()
		{
			if (debug)
				getCallbackCollection(this).addImmediateCallback(this, function():void { trace(totalGeomTiles,'geomTiles,',totalVertices,'vertices'); });
		}
		
		/**
		 * This is an Array of GeneralizedGeometry objects that have been decoded from a stream.
		 */
		public const geometries:Array = [];
		
		/**
		 * This is the bounding box containing all tile boundaries.
		 */
		public const collectiveBounds:IBounds2D = new Bounds2D();
		
		/**
		 * This function sets the keyType of the keys that will be
		 * added as a result of downloading the geometries.
		 */		
		public function set keyType(value:String):void
		{
			_keyType = value;
		}
		private var _keyType:String = null;

		/**
		 * This is the set of geometry keys that have been decoded so far.
		 */
		public const keys:Array = [];
		
		/**
		 * These callbacks get called when the keys or bounds change.
		 */
		public const metadataCallbacks:ICallbackCollection = newLinkableChild(this, CallbackCollection);

		/**
		 * This object maps a key to an array of geometries.
		 */
		private const _keyToGeometryMapping:Dictionary = new Dictionary();

		
		/**
		 * @param geometryKey A String identifier.
		 * @return An Array of GeneralizedGeometry objects with keys matching the specified key. 
		 */
		public function getGeometriesFromKey(geometryKey:IQualifiedKey):Array
		{
			return _keyToGeometryMapping[geometryKey] as Array;
		}

		/**
		 * metadataTiles & geometryTiles
		 * These are 6-dimensional trees of tiles that are available and have not been downloaded yet.
		 * The dimensions are minImportance, maxImportance, xMin, yMin, xMax, yMax.
		 * The objects contained in the KDNodes are integers representing tile ID numbers.
		 */
		private const metadataTiles:KDTree = new KDTree(KD_DIMENSIONALITY);
		private const geometryTiles:KDTree = new KDTree(KD_DIMENSIONALITY);
		
		/**
		 * (KDTree, int) -> TileDescriptor
		 */
		private const tileLookup:Dictionary2D = new Dictionary2D();
		
		/**
		 * These constants define indices in a KDKey corresponding to the different KDTree dimensions.
		 */
		private const XMIN_INDEX:int = 0, YMIN_INDEX:int = 1;
		private const XMAX_INDEX:int = 2, YMAX_INDEX:int = 3;
		private const IMAX_INDEX:int = 4;
		private const KD_DIMENSIONALITY:int = 5;
		/**
		 * These KDKey arrays are created once and reused to avoid unnecessary creation of objects.
		 */
		private const minKDKey:Array = [-Infinity, -Infinity, -Infinity, -Infinity, -Infinity];
		private const maxKDKey:Array = [Infinity, Infinity, Infinity, Infinity, Infinity];
		
		/**
		 * These functions return an array of tiles that need to be downloaded in
		 * order for shapes to be displayed at the given importance (quality) level.
		 * Tiles that have already been decoded from a stream will not be returned.
		 * @return A list of tiles, sorted descending by maxImportance.
		 */
		public function getRequiredMetadataTileIDs(bounds:IBounds2D, minImportance:Number, removeTilesFromList:Boolean):Array
		{
			return getRequiredTileIDs(metadataTiles, bounds, minImportance, removeTilesFromList);
		}
		public function getRequiredGeometryTileIDs(bounds:IBounds2D, minImportance:Number, removeTilesFromList:Boolean):Array
		{
			return getRequiredTileIDs(geometryTiles, bounds, minImportance, removeTilesFromList);
		}
		
		private function _filterTiles(tile:TileDescriptor, ..._):Boolean
		{
			return !tile.exclude;
		}
		private function _tileToId(tile:TileDescriptor, ..._):int
		{
			return tile.tileID;
		}
		private function _getMaxImportance(tile:TileDescriptor):Number
		{
			return tile.kdKey[IMAX_INDEX];
		}
		
		private function getRequiredTileIDs(tileTree:KDTree, bounds:IBounds2D, minImportance:Number, removeTilesFromList:Boolean):Array
		{
			//trace("getRequiredTileIDs, minImportance="+minImportance);
			// filter out tiles with maxImportance less than the specified minImportance
			minKDKey[IMAX_INDEX] = minImportance;
			// set the minimum query values for xMax, yMax
			minKDKey[XMAX_INDEX] = bounds.getXNumericMin();
			minKDKey[YMAX_INDEX] = bounds.getYNumericMin();
			// set the maximum query values for xMin, yMin
			maxKDKey[XMIN_INDEX] = bounds.getXNumericMax();
			maxKDKey[YMIN_INDEX] = bounds.getYNumericMax();
			
			var tiles:Array = tileTree.queryRange(minKDKey, maxKDKey, true);
			tiles = tiles.filter(_filterTiles);
			StandardLib.sortOn(tiles, _getMaxImportance, -1);
			
			if (removeTilesFromList)
				for each (var tile:TileDescriptor in tiles)
					tile.exclude = true;
			
			return tiles.map(_tileToId);
		}

		/**
		 * This function will decode a tile list stream.
		 * @param stream A list of metadata tiles encoded in a ByteArray stream.
		 */
		public function decodeMetadataTileList(stream:ByteArray):void
		{
			decodeTileList(metadataTiles, stream);
		}
		/**
		 * This function will decode a tile list stream.
		 * @param stream A list of geometry tiles encoded in a ByteArray stream.
		 */
		public function decodeGeometryTileList(stream:ByteArray):void
		{
			decodeTileList(geometryTiles, stream);
		}
		/**
		 * @private
		 */
		private function decodeTileList(tileTree:KDTree, stream:ByteArray):void
		{
			var tiles:Array = []; // array of descriptor objects containing kdKey and tileID
		    try {
				// read tile descriptors from stream
				var tileID:int = 0;
				while (true)
				{
					var kdKey:Array = new Array(KD_DIMENSIONALITY);
					kdKey[XMIN_INDEX] = stream.readDouble();
					kdKey[YMIN_INDEX] = stream.readDouble();
					kdKey[XMAX_INDEX] = stream.readDouble();
					kdKey[YMAX_INDEX] = stream.readDouble();
					kdKey[IMAX_INDEX] = stream.readFloat();
					if (debug)
						trace((tileTree == metadataTiles ? "metadata tile" : "geometry tile") + " " + tileID + "[" + kdKey + "]");
					tiles.push(new TileDescriptor(kdKey, tileID));
					collectiveBounds.includeCoords(kdKey[XMIN_INDEX], kdKey[YMIN_INDEX]);
					collectiveBounds.includeCoords(kdKey[XMAX_INDEX], kdKey[YMAX_INDEX]);
					tileID++;
				}
			}
			catch(e:EOFError) { }
			// randomize the order of tileDescriptors to avoid a possibly
			// poorly-performing KDTree structure due to the given ordering.
			VectorUtils.randomSort(tiles);
			// insert tileDescriptors into tree
			for each (var tile:TileDescriptor in tiles)
			{
				// insert a new node in the tree, mapping kdKey to tile
				tileTree.insert(tile.kdKey, tile);
				// save mapping from tile ID to TileDescriptor so it can be excluded later
				tileLookup.set(tileTree, tile.tileID, tile);
			}

			// collective bounds changed
			
			// Weave automatically triggers callbacks when all tasks complete
			if (!linkableObjectIsBusy(metadataCallbacks))
				metadataCallbacks.triggerCallbacks();
		}

		private var _projectionWKT:String = ""; // stores the well-known-text defining the projection
		
		
		/**
		 * This value specifies the type of the geometries currently being streamed
		 */
		
		private var _currentGeometryType:String = GeometryType.POLYGON;
		private function setGeometryType(value:String):void
		{
			if (_currentGeometryType == value)
				return;
			
			_currentGeometryType = value;
			
			//TEMPORARY SOLUTION -- copy type to all existing geometries
			var geom:GeneralizedGeometry;
			for each (geom in geometries)
				if (geom != null)
					geom.geomType = value;
		}
		
		/**
		 * This extracts metadata from a ByteArray.
		 * Callbacks are triggered when all active decoding tasks are completed.
		 */
		public function decodeMetadataStream(stream:ByteArray):void
		{
			var task:Function = function(stopTime:int):Number
			{
				//trace("decodeMetadataStream",_queuedStreamDictionary[stream],hex(stream));
			    try {
			    	// declare temp variables
					var flag:int;
					var byte:int;
					var vertexID:int;
					var geometry:GeneralizedGeometry;
					var geometryID:int;
					var key:IQualifiedKey;
					// read objects from stream
					while (true)
					{
						flag = stream.readInt();
						if (flag < 0) // flag is negativeTileID
						{
							var tileID:int = (-1 - flag); // decode negativeTileID
							var tile:TileDescriptor = tileLookup.get(metadataTiles, tileID);
							if (tile)
							{
								tile.exclude = true;
								
								flag = stream.readInt();
								if (flag < 0)
									streamVersion = -flag;
								else
									stream.position -= 4; // version 0; rewind
	
								if (debug)
									trace("got metadata tileID=" + tileID + "; "+stream.position+'/'+stream.length);
							}
							else
							{
								// something went wrong
								// either the tileDescriptors were not requested yet,
								// or the service is returning incorrect data.
								reportError("ERROR! decodeMetadataStream(): tileID "+tileID+" is out of range");
								break;
							}
							
							// allow resuming later after finding a tileID.
							if (getTimer() > stopTime)
								return stream.position / stream.length;
						}
						else // flag is geometryID
						{
							geometryID = flag;
							// read geometry key (null-terminated string)
							key = WeaveAPI.QKeyManager.getQKey(_keyType, readString(stream));
							// initialize geometry at geometryID
							geometry = geometries[geometryID] as GeneralizedGeometry;
							if (!geometry)
								geometries[geometryID] = geometry = new GeneralizedGeometry(_currentGeometryType);
							// save mapping from key to geom
							var geomsForKey:Array = _keyToGeometryMapping[key] as Array;
							if (!geomsForKey)
							{
								keys.push(key); // keep track of unique keys
								_keyToGeometryMapping[key] = geomsForKey = [];
							}
							geomsForKey.push(geometry);
							// read bounds xMin, yMin, xMax, yMax
							geometry.bounds.setBounds(
									stream.readDouble(),
									stream.readDouble(),
									stream.readDouble(),
									stream.readDouble()
								);
							//trace("got metadata: geometryID=" + flag + " key=" + key + " bounds=" + geometry.bounds);
							
							// read part markers
							var prev:int = 0;
							while (true)
							{
								vertexID = stream.readInt(); // read next vertexID
								//trace("vID=",vertexID);
								if (vertexID < 0)
									break; // there are no more vertexIDs
								geometry.addPartMarker(prev, vertexID);
								prev = vertexID;
							}
							if (prev > 0)
								geometry.addPartMarker(prev, int.MAX_VALUE);
							
							// if flag is < -1, it means the shapeType follows
							if (vertexID < -1)
							{
								readShapeType(stream);
								if (vertexID < -2)
									_projectionWKT = readString(stream);
							}
						}
					}
				} 
				catch(e:EOFError) { }
	
				return 1; // done
			};
			
			// Weave automatically triggers callbacks when all tasks complete
			// high priority because metadata affects keys and keys are a prerequisite for many things
			WeaveAPI.StageUtils.startTask(metadataCallbacks, task, WeaveAPI.TASK_PRIORITY_HIGH);
		}
		
		private function readShapeType(stream:ByteArray):void
		{
			/*
			0 	Null Shape 	Empty ST_Geometry
			
			1 	Point 	ST_Point
			21 	PointM 	ST_Point with measures
			
			8 	MultiPoint 	ST_MultiPoint
			28 	MultiPointM 	ST_MultiPoint with measures
			
			3 	PolyLine 	ST_MultiLineString
			23 	PolyLineM 	ST_MultiLineString with measures
			
			5 	Polygon 	ST_MultiPolygon
			25 	PolygonM 	ST_MultiPolygon with measures
			*/
			var type:int = stream.readInt();
			//trace("shapeType",flag);
			switch (type) // read shapeType
			{
				//Point
				case 1:
				case 21:
					//MultiPoint
				case 8:
				case 28:
					setGeometryType(GeometryType.POINT);
					break;
				//PolyLine
				case 3:
				case 23:
					setGeometryType(GeometryType.LINE);
					break;
				//Polygon
				case 5:
				case 25:
					setGeometryType(GeometryType.POLYGON);
					break;
				default:
			}
		}
		
		private function readString(stream:ByteArray):String
		{
			stringBuffer.clear();
			while (true)
			{
				var byte:int = stream.readByte();
				if (byte == 0) // if \0 char is found (end of string)
					break;
				stringBuffer.writeByte(byte);
			}
			return stringBuffer.toString();
		}

		/**
		 * This extracts points from a ByteArray.
		 * Callbacks are triggered when all active decoding tasks are completed.
		 */
		public function decodeGeometryStream(stream:ByteArray):void
		{
			var task:Function = function(stopTime:int):Number
			{
				//trace("decodeGeometryStream",_queuedStreamDictionary[stream],hex(stream));
			    try {
			    	// declare temp variables
					var i:int;
					var flag:int;
					var geometryID:int;
					var vertexID:int;
					var x:Number, y:Number, importance:Number = 0;
					// read objects from stream
					while (true)
					{
						flag = stream.readInt();
						//trace("flag",flag);
						if (flag < 0) // flag is negativeTileID
						{
							totalGeomTiles++;
							
							var tileID:int = (-1 - flag); // decode negativeTileID
							var tile:TileDescriptor = tileLookup.get(geometryTiles, tileID);
							if (tile)
							{
								tile.exclude = true;
	
								flag = stream.readInt();
								if (flag < 0)
									streamVersion = -flag;
								else
									stream.position -= 4; // version 0; rewind

								if (debug)
									trace("got geometry tileID=" + tileID + "; "+stream.length);
							}
							else
							{
								// something went wrong
								// either the tileDescriptors were not requested yet,
								// or the service is returning incorrect data.
								reportError("ERROR! decodeGeometryStream(): tileID "+tileID+" is out of range");
								break;
							}
							
							// allow resuming later after finding a tileID.
							if (getTimer() > stopTime)
								return stream.position / stream.length;
						}
						else // flag is geometryID
						{
							totalVertices++;
							
							geometryID = flag;
							// reset lists of IDs
							geometryIDArray.length = 0;
							vertexIDArray.length = 0;
							geometryIDArray.push(geometryID); // save first geometryID
							while (true)
							{
								vertexID = stream.readInt(); // read vertexID for current geometryID
								if (vertexID < 0)
								{
									vertexID = (-1 - vertexID); // decode negativeVertexID
									vertexIDArray.push(vertexID); // save vertexID for previous geometryID 
									break; // this was the last vertexID
								}
	 							vertexIDArray.push(vertexID); // save vertexID for previous geometryID
	 							geometryID = stream.readInt(); // read next geometryID
								if (geometryID == -2) // polygon marker (v2) ?
									vertexIDArray.push(stream.readInt()); // read end-of-part vertexID
								if (geometryID < 0) // polygon marker (v1 or v2)?
									break;
								geometryIDArray.push(geometryID); // save next geometryID
							}
							
							if (geometryID < 0)
							{
								importance = geometryID; // used as flag for polygon marker
								if (vertexIDArray.length == 1)
									vertexIDArray.unshift(0);
							}
							else
							{
								//trace("geomIDs",geometryIDArray);
								//trace("vIDs",vertexIDArray);
								// read coordinates and importance value
								x = stream.readDouble();
								y = stream.readDouble();
								importance = stream.readFloat();
								//trace("X,Y,I",[x,y,importance]);
							}

							// save vertex in all corresponding geometries
							for (i = geometryIDArray.length; i--;)
							{
								//trace("geom "+geometryIDArray[i]+" insert "+vertexIDArray[i]+" "+importance+" "+x+" "+y);
								geometryID = geometryIDArray[i];
								vertexID = vertexIDArray[i];
								
								var geometry:GeneralizedGeometry = geometries[geometryID] as GeneralizedGeometry;
								if (!geometry)
									geometries[geometryID] = geometry = new GeneralizedGeometry(_currentGeometryType);
								
								if (importance < 0) // part marker
									geometry.addPartMarker(vertexID, vertexIDArray[i + 1]);
								else
									geometry.addPoint(vertexID, importance, x, y);
							}
						}
					}
				}
				catch(e:EOFError) { }
	            
				return 1; // done
			}
			
			// Weave automatically triggers callbacks when all tasks complete
			// low priority because the geometries can still be used even without all the detail.
			WeaveAPI.StageUtils.startTask(this, task, WeaveAPI.TASK_PRIORITY_LOW);
		}

		
		// reusable temporary objects to reduce GC activity
		private static const stringBuffer:ByteArray = new ByteArray(); // for reading null-terminated strings
		private static const geometryIDArray:Array = []; // temporary list of geometryIDs
		private static const vertexIDArray:Array = []; // temporary list of vertexIDs
		
		/*
		private static function hex(bytes:ByteArray):String
		{
			var p:int = bytes.position;
			var h:String = '0123456789ABCDEF';
			var result:String = StandardLib.substitute('({0} bytes, pos={1})', bytes.length, p);
			bytes.position = 0;
			while (bytes.bytesAvailable)
			{
				var b:int = bytes.readByte();
				result += h.charAt(b>>4) + h.charAt(b&15);
			}
			bytes.position = p;
			return result;
		}
		*/
	}
}

internal class TileDescriptor
{
	public function TileDescriptor(kdKey:Array, tileID:int)
	{
		this.kdKey = kdKey;
		this.tileID = tileID;
	}
	public var kdKey:Array;
	public var tileID:int;
	public var exclude:Boolean = false;
}
