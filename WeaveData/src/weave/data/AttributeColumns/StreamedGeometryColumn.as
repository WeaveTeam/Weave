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

package weave.data.AttributeColumns
{
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.core.ICallbackCollection;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IQualifiedKey;
	import weave.api.disposeObject;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.api.services.IWeaveGeometryTileService;
	import weave.compiler.StandardLib;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.primitives.Bounds2D;
	import weave.primitives.GeneralizedGeometry;
	import weave.primitives.KDTree;
	import weave.services.addAsyncResponder;
	import weave.utils.GeometryStreamDecoder;
	import weave.utils.VectorUtils;
	
	/**
	 * StreamedGeometryColumn
	 * 
	 * @author adufilie
	 */
	public class StreamedGeometryColumn extends AbstractAttributeColumn
	{
		private static var _debug:Boolean = false;
		
		public function StreamedGeometryColumn(metadataTileDescriptors:ByteArray, geometryTileDescriptors:ByteArray, tileService:IWeaveGeometryTileService, metadata:Object = null)
		{
			super(metadata);
			
			_tileService = registerLinkableChild(this, tileService);
			
			_geometryStreamDecoder.keyType = metadata[ColumnMetadata.KEY_TYPE];
			
			// handle tile descriptors
			WeaveAPI.StageUtils.callLater(this, _geometryStreamDecoder.decodeMetadataTileList, [metadataTileDescriptors]);
			WeaveAPI.StageUtils.callLater(this, _geometryStreamDecoder.decodeGeometryTileList, [geometryTileDescriptors]);
			
			var self:Object = this;
			boundingBoxCallbacks.addImmediateCallback(this, function():void{
				if (_debug)
					debugTrace(self,'boundingBoxCallbacks',boundingBoxCallbacks,'keys',keys.length);
			});
			addImmediateCallback(this, function():void{
				if (_debug)
					debugTrace(self,'keys',keys.length);
			});
		}
		
		public function get boundingBoxCallbacks():ICallbackCollection
		{
			return _geometryStreamDecoder.metadataCallbacks;
		}
		
		override public function getMetadata(propertyName:String):String
		{
			return super.getMetadata(propertyName);
		}
		
		/**
		 * This is a list of unique keys this column defines values for.
		 */
		override public function get keys():Array
		{
			return _geometryStreamDecoder.keys;
		}
		
		override public function containsKey(key:IQualifiedKey):Boolean
		{
			return _geometryStreamDecoder.getGeometriesFromKey(key) != null;
		}
		
		/**
		 * @return The Array of geometries associated with the given key (if dataType not specified).
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class=null):*
		{
			var value:* = _geometryStreamDecoder.getGeometriesFromKey(key);
			
			// cast to different types
			if (dataType == Boolean)
				value = (value is Array);
			else if (dataType == Number)
				value = value ? (value as Array).length : NaN;
			else if (dataType == String)
				value = value ? 'Geometry(' + key.keyType + '#' + key.localName + ')' : undefined;
			
			return value;
		}
		
		public function get collectiveBounds():IBounds2D
		{
			return _geometryStreamDecoder.collectiveBounds;
		}
		
		/**
		 * This function returns true if the column is still downloading tiles.
		 * @return True if there are tiles still downloading.
		 */
		public function isStillDownloading():Boolean
		{
			return _metadataStreamDownloadCounter > 0
				|| _geometryStreamDownloadCounter > 0;
		}
		
		private var _tileService:IWeaveGeometryTileService;
		private const _geometryStreamDecoder:GeometryStreamDecoder = newLinkableChild(this, GeometryStreamDecoder);
		
		private var _geometryStreamDownloadCounter:int = 0;
		private var _metadataStreamDownloadCounter:int = 0;
		
		
		public var metadataTilesPerQuery:int = 200; //10;
		public var geometryTilesPerQuery:int = 200; //30;
		
		public function requestGeometryDetail(dataBounds:IBounds2D, lowestImportance:Number):void
		{
			//trace("requestGeometryDetail",dataBounds,lowestImportance);
			if (dataBounds == null || isNaN(lowestImportance))
				return;
			
			// don't bother downloading if we know the result will be empty
			if (dataBounds.isEmpty())
				return;
			
			var metaRequestBounds:IBounds2D;
			var metaRequestImportance:Number;
			switch (metadataRequestMode.value)
			{
				case METADATA_REQUEST_MODE_ALL:
					metaRequestBounds = _geometryStreamDecoder.collectiveBounds;
					metaRequestImportance = 0;
					break;
				case METADATA_REQUEST_MODE_XY:
					metaRequestBounds = dataBounds;
					metaRequestImportance = 0;
					break;
				case METADATA_REQUEST_MODE_XYZ:
					metaRequestBounds = dataBounds;
					metaRequestImportance = lowestImportance;
					break;
			}
			// request metadata tiles
			var metadataTileIDs:Array = _geometryStreamDecoder.getRequiredMetadataTileIDs(metaRequestBounds, metaRequestImportance, true);
			// request geometry tiles needed for desired dataBounds and zoom level (filter by XYZ)
			var geometryTileIDs:Array = _geometryStreamDecoder.getRequiredGeometryTileIDs(dataBounds, lowestImportance, true);

			if (_debug)
			{
				if (metadataTileIDs.length > 0)
					debugTrace(this, "requesting metadata tiles: " + metadataTileIDs);
				if (geometryTileIDs.length > 0)
					debugTrace(this, "requesting geometry tiles: " + geometryTileIDs);
			}
			
			var query:AsyncToken;
			// make requests for groups of tiles
			while (metadataTileIDs.length > 0)
			{
				query = _tileService.getMetadataTiles(metadataTileIDs.splice(0, metadataTilesPerQuery));
				addAsyncResponder(query, handleMetadataStreamDownload, handleMetadataDownloadFault, query);
				
				_metadataStreamDownloadCounter++;
			}
			// make requests for groups of tiles
			while (geometryTileIDs.length > 0)
			{
				query = _tileService.getGeometryTiles(geometryTileIDs.splice(0, geometryTilesPerQuery));
				addAsyncResponder(query, handleGeometryStreamDownload, handleGeometryDownloadFault, query);
				_geometryStreamDownloadCounter++;
			} 
		}
		
		private function handleMetadataDownloadFault(event:FaultEvent, token:Object = null):void
		{
			if (!wasDisposed)
				reportError(event);
			//trace("handleDownloadFault",token,ObjectUtil.toString(event));
			_metadataStreamDownloadCounter--;
		}
		private function handleGeometryDownloadFault(event:FaultEvent, token:Object = null):void
		{
			if (!wasDisposed)
				reportError(event);
			//trace("handleDownloadFault",token,ObjectUtil.toString(event));
			_geometryStreamDownloadCounter--;
		}

		private function reportNullResult(token:Object):void
		{
			reportError("Did not receive any data from service for geometry column. " + token);
		}
		
		private var _totalDownloadedSize:int = 0;

		private function handleMetadataStreamDownload(event:ResultEvent, token:Object = null):void
		{
			_metadataStreamDownloadCounter--;
			
			if (event.result == null)
			{
				reportNullResult(token);
				return;
			}
			
			var result:ByteArray = event.result as ByteArray;
			_totalDownloadedSize += result.bytesAvailable;
			//trace("handleMetadataStreamDownload "+result.bytesAvailable,"total bytes "+_totalDownloadedSize);

			// when decoding finishes, run callbacks
			_geometryStreamDecoder.decodeMetadataStream(result);
		}
		
		private function handleGeometryStreamDownload(event:ResultEvent, token:Object = null):void
		{
			_geometryStreamDownloadCounter--;

			if (event.result == null)
			{
				reportNullResult(token);
				return;
			}

			var result:ByteArray = event.result as ByteArray;
			_totalDownloadedSize += result.bytesAvailable;
			//trace("handleGeometryStreamDownload "+result.bytesAvailable,"total bytes "+_totalDownloadedSize);

			// when decoding finishes, run callbacks
			_geometryStreamDecoder.decodeGeometryStream(result);
		}
		
		/**
		 * This mode determines which metadata tiles will be requested based on what geometry data is requested.
		 * Possible request modes are:<br>
		 *    all -> All metadata tiles, regardless of requested X-Y-Z range <br>
		 *    xy -> Metadata tiles contained in the requested X-Y range, regardless of Z range <br>
		 *    xyz -> Metadata tiles contained in the requested X-Y-Z range only <br>
		 */
		public static const metadataRequestMode:LinkableString = new LinkableString(METADATA_REQUEST_MODE_XYZ, verifyMetadataRequestMode);
		
		public static const METADATA_REQUEST_MODE_ALL:String = 'all';
		public static const METADATA_REQUEST_MODE_XY:String = 'xy';
		public static const METADATA_REQUEST_MODE_XYZ:String = 'xyz';
		public static function get metadataRequestModeEnum():Array
		{
			return [METADATA_REQUEST_MODE_ALL, METADATA_REQUEST_MODE_XY, METADATA_REQUEST_MODE_XYZ];
		}
		private static function verifyMetadataRequestMode(value:String):Boolean
		{
			return metadataRequestModeEnum.indexOf(value) >= 0;
		}
		
		/**
		 * This is the minimum bounding box screen area required for a geometry to be considered relevant.
		 */		
		public static const geometryMinimumScreenArea:LinkableNumber = new LinkableNumber(1, verifyMinimumScreenArea);
		private static function verifyMinimumScreenArea(value:Number):Boolean
		{
			return value >= 1;
		}
		
		public static function test_kdtree(iterations:int = 10):Object
		{
			var cols:Array = WeaveAPI.SessionManager.getLinkableDescendants(WeaveAPI.globalHashMap, StreamedGeometryColumn);
			for each (var sgc:StreamedGeometryColumn in cols)
				return sgc.test_kdtree(iterations);
			return "No StreamedGeometryColumn to test";
		}
		
		public function test_kdtree(iterations:int = 10):Object
		{
			var todo:Array = [];
			for each (var geom:GeneralizedGeometry in _geometryStreamDecoder.geometries)
			{
				var bounds:Bounds2D = geom.bounds as Bounds2D;
				var key:Array = [bounds.getXNumericMin(), bounds.getYNumericMin(), bounds.getXNumericMax(), bounds.getYNumericMax(), bounds.getArea()];
				todo.push([key, geom]);
			}
			
			// ------
			
			var results:Array = [];
			for (var i:int = 0; i < iterations; i++)
			{
				VectorUtils.randomSort(todo);
				var t:int = getTimer();
				var kdtree:KDTree = new KDTree(5);
				for each (var params:Array in todo)
					kdtree.insert(params[0], params[1]);
				t = getTimer() - t;
				disposeObject(kdtree);
				results.push(t);
			}
			
			return {
				node_count: todo.length,
				times_in_ms: results.join(', '),
				time_mean_ms: StandardLib.mean(results),
				time_min_ms: Math.min.apply(null, results),
				time_max_ms: Math.max.apply(null, results)
			};
		}
	}
}
