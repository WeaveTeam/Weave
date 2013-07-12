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
	import flash.errors.EOFError;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.linkableObjectIsBusy;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.reportError;
	import weave.core.CallbackCollection;
	import weave.primitives.Bounds2D;
	import weave.primitives.GeneralizedGeometry;
	import weave.primitives.GeometryType;
	import weave.primitives.KDNode;
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
		public static var debug:Boolean = false;
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
		 * metadataTileIDToKDNodeMapping & geometryTileIDToKDNodeMapping
		 * These vectors map a tileID to a KDNode which is used for deleting nodes from the KDTrees.
		 */
		private const metadataTileIDToKDNodeMapping:Vector.<KDNode> = new Vector.<KDNode>();
		private const geometryTileIDToKDNodeMapping:Vector.<KDNode> = new Vector.<KDNode>();
		
		private const metadataTilesChecklist:Array = [];
		private const geometryTilesChecklist:Array = [];
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
		 * getRequiredMetadataTileIDs, getRequiredGeometryTileIDs, and getRequiredTileIDs
		 * These functions return an array of tile IDs that need to be downloaded in
		 * order for shapes to be displayed at the given importance (quality) level.
		 * IDs of tiles that have already been decoded from a stream will not be returned.
		 * @return A list of tile IDs, sorted descending by maxImportance.
		 */
		public function getRequiredMetadataTileIDs(bounds:IBounds2D, minImportance:Number, removeTilesFromList:Boolean):Array
		{
			var tileIDs:Array = getRequiredTileIDs(metadataTiles, bounds, minImportance);
			if (removeTilesFromList)
				for each (var id:int in tileIDs)
					metadataTiles.remove(metadataTileIDToKDNodeMapping[id]);
			return tileIDs;
		}
		public function getRequiredGeometryTileIDs(bounds:IBounds2D, minImportance:Number, removeTilesFromList:Boolean):Array
		{
			var tileIDs:Array = getRequiredTileIDs(geometryTiles, bounds, minImportance);
			if (removeTilesFromList)
				for each (var id:int in tileIDs)
					geometryTiles.remove(geometryTileIDToKDNodeMapping[id]);
			return tileIDs;
		}
		private function getRequiredTileIDs(tileTree:KDTree, bounds:IBounds2D, minImportance:Number):Array
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
			// make a copy of the query result with Array.concat()
			// because queryRange re-uses a temporary array.
			return tileTree.queryRange(minKDKey, maxKDKey, true, IMAX_INDEX, KDTree.DESCENDING).concat();
		}

		/**
		 * This function will decode a tile list stream.
		 * @param stream A list of metadata tiles encoded in a ByteArray stream.
		 */
		public function decodeMetadataTileList(stream:ByteArray):void
		{
			decodeTileList(metadataTiles, metadataTileIDToKDNodeMapping, stream);
		}
		/**
		 * This function will decode a tile list stream.
		 * @param stream A list of geometry tiles encoded in a ByteArray stream.
		 */
		public function decodeGeometryTileList(stream:ByteArray):void
		{
			decodeTileList(geometryTiles, geometryTileIDToKDNodeMapping, stream);
		}
		/**
		 * @private
		 */
		private function decodeTileList(tileTree:KDTree, tileIDToKDNodeMapping:Vector.<KDNode>, stream:ByteArray):void
		{
			var tileDescriptors:Array = []; // array of descriptor objects containing kdKey and tileID
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
					//trace((tileTree == metadataTiles ? "metadata tile" : "geometry tile") + " " + tileID + "[" + kdKey + "]");
					tileDescriptors.push(new TileDescriptor(kdKey, tileID));
					collectiveBounds.includeCoords(kdKey[XMIN_INDEX], kdKey[YMIN_INDEX]);
					collectiveBounds.includeCoords(kdKey[XMAX_INDEX], kdKey[YMAX_INDEX]);
					tileID++;
				}
			}
			catch(e:EOFError) { }
			// randomize the order of tileDescriptors to avoid a possibly
			// poorly-performing KDTree structure due to the given ordering.
			VectorUtils.randomSort(tileDescriptors);
			// expand vector to hold all tileDescriptor nodes
			tileIDToKDNodeMapping.length = tileDescriptors.length;
			// insert tileDescriptors into tree
			var node:KDNode;
			var tileDescriptor:TileDescriptor;
			for (var i:int = tileDescriptors.length; i--;)
			{
				tileDescriptor = tileDescriptors[i] as TileDescriptor;
				// insert a new node in the tree, mapping kdKey to tileID
				node = tileTree.insert(tileDescriptor.kdKey, tileDescriptor.tileID);
				// save mapping from tile ID to KDNode so the node can be deleted from the tree later
				tileIDToKDNodeMapping[tileDescriptor.tileID] = node;
			}

			if (debug)
			{
				trace("decodeTileList(): tile counts: ",metadataTiles.nodeCount,geometryTiles.nodeCount);
				
				// generate checklists for debugging
				geometryTilesChecklist.length = 0;
				while (geometryTilesChecklist.length < geometryTileIDToKDNodeMapping.length)
					geometryTilesChecklist.push(geometryTilesChecklist.length);
				
				metadataTilesChecklist.length = 0;
				while (metadataTilesChecklist.length < metadataTileIDToKDNodeMapping.length)
					metadataTilesChecklist.push(metadataTilesChecklist.length);
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
		private function get currentGeometryType():String
		{
			return _currentGeometryType;
		}
		private function set currentGeometryType(value:String):void
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
							if (tileID < metadataTileIDToKDNodeMapping.length)
							{
								// remove tile from tree
								metadataTiles.remove(metadataTileIDToKDNodeMapping[tileID]);
								
								flag = stream.readInt();
								if (flag < 0)
									streamVersion = -flag;
								else
									stream.position -= 4; // version 0; rewind
	
								if (debug)
								{
									trace("got metadata tileID=" + tileID + "/"+metadataTileIDToKDNodeMapping.length+"; "+stream.position+'/'+stream.length);
									flag = metadataTilesChecklist.indexOf(tileID);
									if (flag >= 0)
									{
										metadataTilesChecklist.splice(flag, 1);
										trace("remaining metadata tiles: "+metadataTilesChecklist);
									}
								}
							}
							else
							{
								// something went wrong
								// either the tileDescriptors were not requested yet,
								// or the service is returning incorrect data.
								reportError("ERROR! decodeMetadataStream(): tileID is out of range ("+tileID+" >= "+metadataTileIDToKDNodeMapping.length+")");
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
								geometries[geometryID] = geometry = new GeneralizedGeometry();
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
							// set geometry type
							geometry.geomType = currentGeometryType;
						}
					}
				} 
				catch(e:EOFError) { }
	
				return 1; // done
			};
			
			// Weave automatically triggers callbacks when all tasks complete
			WeaveAPI.StageUtils.startTask(metadataCallbacks, task, WeaveAPI.TASK_PRIORITY_PARSING);
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
					currentGeometryType = GeometryType.POINT;
				//PolyLine
				case 3:
				case 23:
					currentGeometryType = GeometryType.LINE;
				//Polygon
				case 5:
				case 25:
					currentGeometryType = GeometryType.POLYGON;
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
							if (tileID < geometryTileIDToKDNodeMapping.length)
							{
								// remove tile from tree
								geometryTiles.remove(geometryTileIDToKDNodeMapping[tileID]);
	
								flag = stream.readInt();
								if (flag < 0)
									streamVersion = -flag;
								else
									stream.position -= 4; // version 0; rewind

								if (debug)
								{
									trace("got geometry tileID=" + tileID + "/" + geometryTileIDToKDNodeMapping.length + "; "+stream.length);
									flag = geometryTilesChecklist.indexOf(tileID);
									if (flag >= 0)
									{
										geometryTilesChecklist.splice(flag, 1);
										trace("remaining geometry tiles: "+geometryTilesChecklist);
									}
								}
							}
							else
							{
								// something went wrong
								// either the tileDescriptors were not requested yet,
								// or the service is returning incorrect data.
								reportError("ERROR! decodeGeometryStream(): tileID is out of range ("+tileID+" >= "+geometryTileIDToKDNodeMapping.length+")");
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
									geometries[geometryID] = geometry = new GeneralizedGeometry();
								
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
			WeaveAPI.StageUtils.startTask(this, task, WeaveAPI.TASK_PRIORITY_PARSING);
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
			var result:String = StringUtil.substitute('({0} bytes, pos={1})', bytes.length, p);
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
}
