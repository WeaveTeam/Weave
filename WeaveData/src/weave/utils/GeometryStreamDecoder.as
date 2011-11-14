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
	
	import mx.utils.NameUtil;
	import mx.utils.StringUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.newDisposableChild;
	import weave.api.primitives.IBounds2D;
	import weave.core.StageUtils;
	import weave.data.AttributeColumns.AbstractAttributeColumn;
	import weave.data.KeySets.KeySet;
	import weave.primitives.Bounds2D;
	import weave.primitives.GeneralizedGeometry;
	import weave.primitives.KDNode;
	import weave.primitives.KDTree;

	/**
	 * This class provides functions for parsing a binary geometry stream.
	 * The callbacks for this object get called when all queued decoding completes.
	 * 
	 * Throughout the code, an ID refers to an integer value, while a Key is a string value.
	 * Binary format:
	 *   tile descriptor format: <float minImportance, float maxImportance, double xMin, double yMin, double xMax, double yMax>
	 *       stream tile format: <int negativeTileID, binary stream object beginning with positive int, ...>
	 *   metadata stream object: <int geometryID, String geometryKey, '\0', double xMin, double yMin, double xMax, double yMax, int vertexID1, ..., int vertexID(n), int -1>
	 *   geometry stream object: <int geometryID1, int vertexID1, int geometryID2, int vertexID2, ..., int geometryID(n-1), int vertexID(n-1), int geometryID(n), int negativeVertexID(n), double x, double y, float importance>
	 * 
	 * @author adufilie
	 */
	public class GeometryStreamDecoder implements ILinkableObject
	{
		public function GeometryStreamDecoder()
		{
		}
		
		/**
		 * geometries
		 * This is an Array of GeneralizedGeometry objects that have been decoded from a stream.
		 */
		public const geometries:Array = [];
		
		/**
		 * collectiveBounds
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
		 * keySet
		 * This is the set of geometry keys that have been decoded so far.
		 */
		public const keySet:KeySet = newDisposableChild(this, KeySet);

		/**
		 * keyToGeometryMapping
		 * This object maps a key to an array of geometries.
		 */
		private const keyToGeometryMapping:Dictionary = new Dictionary();

		/**
		 * getGeometriesFromKey
		 * @param geometryKey A String identifier.
		 * @return An Array of GeneralizedGeometry objects with keys matching the specified key. 
		 */
		public function getGeometriesFromKey(geometryKey:IQualifiedKey):Array
		{
			if (keyToGeometryMapping[geometryKey] == undefined)
				keyToGeometryMapping[geometryKey] = [];
			return keyToGeometryMapping[geometryKey];
		}

		/**
		 * idToDelayedAddPointParamsMap
		 * This maps a geometryID (integer) to an Array of arrays of parameters for GeneralizedGeometry.addPoint().
		 * For example, idToDelayedAddPointParamsMap[3] may be [[vertexID1,importance1,x1,y1],[vertexID2,importance2,x2,y2]].
		 */
		private const idToDelayedAddPointParamsMap:Array = [];
		
		/**
		 * delayAddPointParams
		 * This function will store a list of parameters for GeneralizedGeometry.addPoint() to be used later.
		 * @param geometryID The ID of the GeneralizedGeometry the addPoint() parameters are for.
		 * @param vertexID Parameter for GeneralizedGeometry.addPoint().
		 * @param importance Parameter for GeneralizedGeometry.addPoint().
		 * @param x Parameter for GeneralizedGeometry.addPoint().
		 * @param y Parameter for GeneralizedGeometry.addPoint().
		 */
		private function delayAddPointParams(geometryID:int, vertexID:int, importance:Number, x:Number, y:Number):void
		{
			if (idToDelayedAddPointParamsMap.length <= geometryID)
				idToDelayedAddPointParamsMap.length = geometryID + 1;
			if (idToDelayedAddPointParamsMap[geometryID] == undefined)
				idToDelayedAddPointParamsMap[geometryID] = [];
			(idToDelayedAddPointParamsMap[geometryID] as Array).push([vertexID, importance, x, y]);
		}
		
		/**
		 * metadataTiles & geometryTiles
		 * These are 6-dimensional trees of tiles that are available and have not been downloaded yet.
		 * The dimensions are minImportance, maxImportance, xMin, yMin, xMax, yMax.
		 * The objects contained in the KDNodes are integers representing tile ID numbers.
		 */
		private const metadataTiles:KDTree = new KDTree(6);
		private const geometryTiles:KDTree = new KDTree(6);
		/**
		 * metadataTileIDToKDNodeMapping & geometryTileIDToKDNodeMapping
		 * These vectors map a tileID to a KDNode which is used for deleting nodes from the KDTrees.
		 */
		private const metadataTileIDToKDNodeMapping:Vector.<KDNode> = new Vector.<KDNode>();
		private const geometryTileIDToKDNodeMapping:Vector.<KDNode> = new Vector.<KDNode>();
		private const metadataTilesChecklist:Vector.<int> = new Vector.<int>();
		private const geometryTilesChecklist:Vector.<int> = new Vector.<int>();
		/**
		 * These constants define indices in a KDKey corresponding to the different KDTree dimensions.
		 */
		private const IMIN_INDEX:int = 0, IMAX_INDEX:int = 1;
		private const XMIN_INDEX:int = 2, YMIN_INDEX:int = 3;
		private const XMAX_INDEX:int = 4, YMAX_INDEX:int = 5;
		/**
		 * These KDKey arrays are created once and reused to avoid unnecessary creation of objects.
		 */
		private const minKDKey:Array = [-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity];
		private const maxKDKey:Array = [Infinity, Infinity, Infinity, Infinity, Infinity, Infinity];
		
		/**
		 * This function should be called when stream decoding begins or resumes.
		 * @param stream The stream to be decoded. 
		 * @return A value of true if this is the first time the decoding process has been reported for the specified stream.
		 */
		private function beginTask(stream:ByteArray):Boolean
		{
			if (_queuedStreamDictionary[stream])
				return false;
			_queuedStreamDictionary[stream] = NameUtil.createUniqueName(stream);
			WeaveAPI.ProgressIndicator.addTask(stream);
			return true;
		}
		/**
		 * This function should be called to indicate decoding progress.
		 * @param stream The stream being decoded.
		 */
		private function updateTask(stream:ByteArray):void
		{
			WeaveAPI.ProgressIndicator.updateTask(stream, stream.position / (stream.length - 1));
		}
		/**
		 * This function should be called when we have finished decoding a stream.
		 * @param stream The stream.
		 * @return A value of true if there are more tasks in queue.
		 */
		private function endTask(stream:ByteArray):Boolean
		{
			delete _queuedStreamDictionary[stream];
			WeaveAPI.ProgressIndicator.removeTask(stream);
			for (var _stream:Object in _queuedStreamDictionary)
				return true; // more tasks remain
			return false; // no more tasks
		}
		
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
				for (var i:int = tileIDs.length - 1; i >= 0; i--)
					metadataTiles.remove(metadataTileIDToKDNodeMapping[tileIDs[i]]);
			return tileIDs;
		}
		public function getRequiredGeometryTileIDs(bounds:IBounds2D, minImportance:Number, removeTilesFromList:Boolean):Array
		{
			var tileIDs:Array = getRequiredTileIDs(geometryTiles, bounds, minImportance);
			if (removeTilesFromList)
				for (var i:int = tileIDs.length - 1; i >= 0; i--)
					geometryTiles.remove(geometryTileIDToKDNodeMapping[tileIDs[i]]);
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
		 * decodeMetadataTileList, decodeGeometryTileList, and decodeTileList
		 * Converts a base64 string to a ByteArray and extracts tile descriptors,
		 * starting with tile #0, then tile #1, etc.
		 * When decoding completes, decodeCompleteCallbacks will run.
		 */
		public function decodeMetadataTileList(stream:ByteArray):void
		{
			decodeTileList(metadataTiles, metadataTileIDToKDNodeMapping, stream);
			// generate checklist for debugging
			metadataTilesChecklist.length = 0;
			while (metadataTilesChecklist.length < metadataTileIDToKDNodeMapping.length)
				metadataTilesChecklist.push(metadataTilesChecklist.length);
			// include bounds of all metadata tiles in collecteBounds
			var node:KDNode;
			var kdKey:Array;
			for each (node in metadataTileIDToKDNodeMapping)
			{
				kdKey = node.key;
				collectiveBounds.includeCoords(kdKey[XMIN_INDEX], kdKey[YMIN_INDEX]);
				collectiveBounds.includeCoords(kdKey[XMAX_INDEX], kdKey[YMAX_INDEX]);
			}
		}
		public function decodeGeometryTileList(stream:ByteArray):void
		{
			decodeTileList(geometryTiles, geometryTileIDToKDNodeMapping, stream);
			// generate checklist for debugging
			geometryTilesChecklist.length = 0;
			while (geometryTilesChecklist.length < geometryTileIDToKDNodeMapping.length)
				geometryTilesChecklist.push(geometryTilesChecklist.length);
		}
		private function decodeTileList(tileTree:KDTree, tileIDToKDNodeMapping:Vector.<KDNode>, stream:ByteArray):void
		{
			// if this is the first time calling this function with this stream, call later
			if (beginTask(stream))
			{
				StageUtils.callLater(this, decodeTileList, arguments);
				return;
			}
			
			var tileDescriptors:Array = []; // array of descriptor objects containing kdKey and tileID
		    try {
				// read tile descriptors from stream
				var tileID:int = 0;
				while (true)
				{
					var kdKey:Array = new Array(6);
					kdKey[IMIN_INDEX] = stream.readFloat();
					kdKey[IMAX_INDEX] = stream.readFloat();
					kdKey[XMIN_INDEX] = stream.readDouble();
					kdKey[YMIN_INDEX] = stream.readDouble();
					kdKey[XMAX_INDEX] = stream.readDouble();
					kdKey[YMAX_INDEX] = stream.readDouble();
					//trace((tileTree == metadataTiles ? "metadata tile" : "geometry tile") + " " + tileID + "[" + kdKey + "]");
					tileDescriptors.push({kdKey: kdKey, tileID: tileID});
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
			var tileDescriptor:Object;
			for (var i:int = tileDescriptors.length - 1; i >= 0; i--)
			{
				tileDescriptor = tileDescriptors[i];
				// insert a new node in the tree, mapping kdKey to tileID
				node = tileTree.insert(tileDescriptor.kdKey, tileDescriptor.tileID);
				// save mapping from tile ID to KDNode so the node can be deleted from the tree later
				tileIDToKDNodeMapping[tileDescriptor.tileID] = node;
			}
			//trace("decodeTileList(): tile counts: ",metadataTiles.nodeCount,geometryTiles.nodeCount);

			// remove this stream from the processing list
			if (endTask(stream))
				return; // do not run callbacks if there are still streams being processed.
			
			getCallbackCollection(this).triggerCallbacks();
		}

		private var _projectionWKT:String = ""; // stores the well-known-text defining the projection
		
		
		/**
		 * currentGeometryType
		 * This value specifies the type of the geometries currently being streamed
		 */
		
		private var _currentGeometryType:String = GeneralizedGeometry.GEOM_TYPE_POLYGON;
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
		 * The keys in this dictionary are ByteArray objects that are currently being processed.
		 */
		private const _queuedStreamDictionary:Dictionary = new Dictionary();

		/**
		 * extracts metadata from a ByteArray.
		 * If the geometries change, the specified callback will run when processing is finished.
		 * When decoding completes, decodeCompleteCallbacks will run.
		 */
		public function decodeMetadataStream(stream:ByteArray):void
		{
			beginTask(stream);

			//trace("decodeMetadataStream",_queuedStreamDictionary[stream],hex(stream));
			var geometriesUpdated:Boolean = false;
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
							//trace("got metadata tileID=" + tileID + "/"+metadataTileIDToKDNodeMapping.length+"; "+stream.bytesAvailable);

							/*flag = metadataTilesChecklist.indexOf(tileID);
							if (flag >= 0)
							{
								metadataTilesChecklist.splice(flag, 1);
								trace("remaining metadata tiles: "+metadataTilesChecklist);
							}*/
						}
						else
						{
							// something went wrong
							// either the tileDescriptors were not requested yet,
							// or the service is returning incorrect data.
							trace("ERROR! decodeMetadataStream(): tileID is out of range ("+tileID+" >= "+metadataTileIDToKDNodeMapping.length+")");
							break;
						}
						if (StageUtils.shouldCallLater)
						{
							//trace("callLater");
							updateTask(stream);
							StageUtils.callLater(this, decodeMetadataStream, arguments);
							return;
						}
					}
					else // flag is geometryID
					{
						geometryID = flag;
						// read geometry key (null-terminated string)
						stringBuffer.clear();
						while (true)
						{
							byte = stream.readByte();
							if (byte == 0) // if \0 char is found (end of string)
								break;
							stringBuffer.writeByte(byte); // copy the byte to the string buffer
						}
						key = WeaveAPI.QKeyManager.getQKey(_keyType, stringBuffer.toString()); // get key string from buffer
						// initialize geometry at geometryID
						geometry = new GeneralizedGeometry();
						if (geometries.length <= geometryID)
							geometries.length = geometryID + 1;
						geometries[geometryID] = geometry;
						// save key-to-geometry mapping
			            getGeometriesFromKey(key).push(geometry);
						// remember that this key was seen
			            keysLastSeen.push(key);
						// read bounds xMin, yMin, xMax, yMax
						geometry.bounds.setBounds(
								stream.readDouble(),
								stream.readDouble(),
								stream.readDouble(),
								stream.readDouble()
							);
						//trace("got metadata: geometryID=" + flag + " key=" + key + " bounds=" + geometry.bounds);
						// read vertexIDs (part markers)
						while (true)
						{
							vertexID = stream.readInt(); // read next vertexID
							//trace("vID=",vertexID);
							if (vertexID < 0)
								break; // there are no more vertexIDs
							geometry.addPartMarker(vertexID);
						}
						// if flag is < -1, it means the shapeType follows
						if (vertexID < -1)
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
							flag = stream.readInt();
							//trace("shapeType",flag);
							switch (flag) // read shapeType
							{
								//Point
								case 1:
								case 21:
								//MultiPoint
								case 8:
								case 28:
									currentGeometryType = GeneralizedGeometry.GEOM_TYPE_POINT;
								break;
								//PolyLine
								case 3:
								case 23:
									currentGeometryType = GeneralizedGeometry.GEOM_TYPE_LINE;
								break;
								//Polygon
								case 5:
								case 25:
									currentGeometryType = GeneralizedGeometry.GEOM_TYPE_POLYGON;
								break;
								default:
							}
							if (vertexID < -2)
							{
								stringBuffer.clear();
								while (true)
								{
									byte = stream.readByte();
									if (byte == 0) // if \0 char is found (end of string)
										break;
									stringBuffer.writeByte(byte); // copy the byte to the string buffer
								}
								_projectionWKT = stringBuffer.toString(); // get key from buffer
							}
						}
						// set geometry type
						geometry.geomType = currentGeometryType;
						// add delayed points
						if (geometryID < idToDelayedAddPointParamsMap.length && idToDelayedAddPointParamsMap[geometryID] is Array)
						{
							for each (var addPointParams:Array in idToDelayedAddPointParamsMap[geometryID])
								geometry.addPoint.apply(null, addPointParams);
							delete idToDelayedAddPointParamsMap[geometryID];
						}
						// geometries changed
						geometriesUpdated = true;
					}
				}
            } 
            catch(e:EOFError) { }

			keySet.addKeys(keysLastSeen); // update keys
			keysLastSeen.length = 0; // reset for next time
            
			// remove this stream from the processing list
			if (endTask(stream))
				return; // do not run callbacks if there are still streams being processed.
			
			//trace("metadata stream processing done");
			//if (geometriesUpdated)
				getCallbackCollection(this).triggerCallbacks();

		}

		/**
		 * extracts points from a ByteArray.
		 * If the geometries change, the specified callback will run when processing is finished.
		 * When decoding completes, decodeCompleteCallbacks will run.
		 */
		public function decodeGeometryStream(stream:ByteArray):void
		{
			beginTask(stream);

			//trace("decodeGeometryStream",_queuedStreamDictionary[stream],hex(stream));
			var geometriesUpdated:Boolean = false;
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
						var tileID:int = (-1 - flag); // decode negativeTileID
						if (tileID < geometryTileIDToKDNodeMapping.length)
						{
							// remove tile from tree
							geometryTiles.remove(geometryTileIDToKDNodeMapping[tileID]);
							//trace("got geometry tileID=" + tileID + "/" + geometryTileIDToKDNodeMapping.length + "; "+stream.bytesAvailable);

							/*flag = geometryTilesChecklist.indexOf(tileID);
							if (flag >= 0)
							{
								geometryTilesChecklist.splice(flag, 1);
								trace("remaining geometry tiles: "+geometryTilesChecklist);
							}*/
						}
						else
						{
							// something went wrong
							// either the tileDescriptors were not requested yet,
							// or the service is returning incorrect data.
							trace("ERROR! decodeGeometryStream(): tileID is out of range ("+tileID+" >= "+geometryTileIDToKDNodeMapping.length+")");
							break;
						}
						if (StageUtils.shouldCallLater)
						{
							//trace("callLater");
							updateTask(stream);
							StageUtils.callLater(this, decodeGeometryStream, arguments);
							return;
						}
					}
					else // flag is geometryID
					{
						geometryID = flag;
						geometryIDArray.length = vertexIDArray.length = 0; // reset list of IDs
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
							geometryIDArray.push(geometryID); // save next geometryID
						}
						//trace("geomIDs",geometryIDArray);
						//trace("vIDs",vertexIDArray);
						// read coordinates and importance value
						x = stream.readDouble();
						y = stream.readDouble();
						importance = stream.readFloat();
						//trace("X,Y,I",[x,y,importance]);
						// save vertex in all corresponding geometries
						for (i = geometryIDArray.length - 1; i >= 0; i--)
						{
							//trace("geom "+geometryIDArray[i]+" insert "+vertexIDArray[i]+" "+importance+" "+x+" "+y);
							geometryID = geometryIDArray[i]
							if (geometryID < geometries.length && geometries[geometryID] is GeneralizedGeometry)
								(geometries[geometryID] as GeneralizedGeometry).addPoint(vertexIDArray[i], importance, x, y);
							else
							{
								//trace("delay",geometryID,vertexIDArray[i]);
								delayAddPointParams(geometryID, vertexIDArray[i], importance, x, y);
							}
						}
						// geometries changed
						geometriesUpdated = true;
					}
				}
            }
            catch(e:EOFError) { }
//            catch(e:Error)
//            {
//            	trace("Unexpected error: "+e.getStackTrace());
//            }
            
			// remove this stream from the processing list
			if (endTask(stream))
				return; // do not run callbacks if there are still streams being processed.
			
			//trace("geometry stream processing done");
			//if (geometriesUpdated)
				getCallbackCollection(this).triggerCallbacks();
		}

		
		// reusable temporary objects to reduce GC activity
		private static const stringBuffer:ByteArray = new ByteArray(); // for reading null-terminated strings
		private static const geometryIDArray:Vector.<int> = new Vector.<int>(); // temporary list of geometryIDs
		private static const vertexIDArray:Vector.<int> = new Vector.<int>(); // temporary list of vertexIDs
		private static const keysLastSeen:Array = []; // temporary list of keys recently decoded
		
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
		
		private function trace(...args):void
		{
			DebugUtils.debug_trace(this, args);
		}
	}
}
