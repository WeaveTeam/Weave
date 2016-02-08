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

package weavejs.data.column
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.ICallbackCollection;
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.api.net.IWeaveGeometryTileService;
	import weavejs.geom.Bounds2D;
	import weavejs.geom.GeneralizedGeometry;
	import weavejs.geom.GeometryStreamDecoder;
	import weavejs.geom.KDTree;
	import weavejs.geom.ZoomBounds;
	import weavejs.util.ArrayUtils;
	import weavejs.util.DebugUtils;
	import weavejs.util.JS;
	import weavejs.util.JSByteArray;
	import weavejs.util.StandardLib;
	import weavejs.util.WeavePromise;
	
	/**
	 * StreamedGeometryColumn
	 * 
	 * @author adufilie
	 */
	public class StreamedGeometryColumn extends AbstractAttributeColumn
	{
		public static var debug:Boolean = false;
		
		public function StreamedGeometryColumn(metadataTileDescriptors:JSByteArray, geometryTileDescriptors:JSByteArray, tileService:IWeaveGeometryTileService, metadata:Object = null)
		{
			super(metadata);
			
			_tileService = Weave.linkableChild(this, tileService);
			
			_geometryStreamDecoder.keyType = metadata[ColumnMetadata.KEY_TYPE];
			
			// handle tile descriptors
			WeaveAPI.Scheduler.callLater(this, _geometryStreamDecoder.decodeMetadataTileList, [metadataTileDescriptors]);
			WeaveAPI.Scheduler.callLater(this, _geometryStreamDecoder.decodeGeometryTileList, [geometryTileDescriptors]);
			
			var self:Object = this;
			boundingBoxCallbacks.addImmediateCallback(this, function():void{
				if (debug)
					DebugUtils.debugTrace(self,'boundingBoxCallbacks',boundingBoxCallbacks,keys.length,'keys');
			});
			addImmediateCallback(this, function():void{
				if (debug)
					DebugUtils.debugTrace(self,keys.length,'keys');
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
			{
				var sum:Number = value is Array ? 0 : NaN;
				for each (var geom:GeneralizedGeometry in value)
					sum += geom.bounds.getArea();
				value = sum;
			}
			else if (dataType == String)
				value = value ? 'Geometry(' + key.keyType + '#' + key.localName + ')' : undefined;
			
			return value;
		}
		
		public function get collectiveBounds():Bounds2D
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
		private const _geometryStreamDecoder:GeometryStreamDecoder = Weave.linkableChild(this, GeometryStreamDecoder);
		
		private var _geometryStreamDownloadCounter:int = 0;
		private var _metadataStreamDownloadCounter:int = 0;
		
		
		public var metadataTilesPerQuery:int = 200; //10;
		public var geometryTilesPerQuery:int = 200; //30;
		
		public function requestGeometryDetail(dataBounds:Bounds2D, lowestImportance:Number):void
		{
			//JS.log("requestGeometryDetail",dataBounds,lowestImportance);
			if (dataBounds == null || isNaN(lowestImportance))
				return;
			
			// don't bother downloading if we know the result will be empty
			if (dataBounds.isEmpty())
				return;
			
			var metaRequestBounds:Bounds2D;
			var metaRequestImportance:Number;
			switch (metadataRequestMode)
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

			if (debug)
			{
				if (metadataTileIDs.length > 0)
					JS.log(this, "requesting metadata tiles: " + metadataTileIDs);
				if (geometryTileIDs.length > 0)
					JS.log(this, "requesting geometry tiles: " + geometryTileIDs);
			}
			
			var query:WeavePromise;
			// make requests for groups of tiles
			while (metadataTileIDs.length > 0)
			{
				query = _tileService.getMetadataTiles(metadataTileIDs.splice(0, metadataTilesPerQuery));
				query.then(handleMetadataStreamDownload, handleMetadataDownloadFault);
				
				_metadataStreamDownloadCounter++;
			}
			// make requests for groups of tiles
			while (geometryTileIDs.length > 0)
			{
				query = _tileService.getGeometryTiles(geometryTileIDs.splice(0, geometryTilesPerQuery));
				query.then(handleGeometryStreamDownload, handleGeometryDownloadFault);
				_geometryStreamDownloadCounter++;
			} 
		}
		
		private function handleMetadataDownloadFault(error:Object):void
		{
			if (!wasDisposed)
				JS.error(error);
			//JS.log("handleDownloadFault",token,ObjectUtil.toString(event));
			_metadataStreamDownloadCounter--;
		}
		private function handleGeometryDownloadFault(error:Object):void
		{
			if (!wasDisposed)
				JS.error(error);
			//JS.log("handleDownloadFault",token,ObjectUtil.toString(event));
			_geometryStreamDownloadCounter--;
		}

		private static var _tempDataBounds:Bounds2D;
		private static var _tempScreenBounds:Bounds2D;
		
		public function requestGeometryDetailForZoomBounds(zoomBounds:ZoomBounds):void
		{
			if (!_tempDataBounds)
				_tempDataBounds = new Bounds2D();
			if (!_tempScreenBounds)
				_tempScreenBounds = new Bounds2D();
			
			zoomBounds.getDataBounds(_tempDataBounds);
			zoomBounds.getScreenBounds(_tempScreenBounds);
			var minImportance:Number = _tempDataBounds.getArea() / _tempScreenBounds.getArea();
			
			var requestedDataBounds:Bounds2D = _tempDataBounds;
			var requestedMinImportance:Number = minImportance;
			if (requestedDataBounds.isUndefined())// if data bounds is empty
			{
				// use the collective bounds from the geometry column and re-calculate the min importance
				requestedDataBounds = this.collectiveBounds;
				requestedMinImportance = requestedDataBounds.getArea() / _tempScreenBounds.getArea();
			}
			// only request more detail if requestedDataBounds is defined
			if (!requestedDataBounds.isUndefined())
				this.requestGeometryDetail(requestedDataBounds, requestedMinImportance);
		}
		
		private function reportNullResult(token:Object):void
		{
			JS.error("Did not receive any data from service for geometry column.", token);
		}
		
		private var _totalDownloadedSize:int = 0;

		private function handleMetadataStreamDownload(result:JSByteArray):void
		{
			_metadataStreamDownloadCounter--;
			
			if (result == null)
			{
				reportNullResult(this);
				return;
			}
			
			_totalDownloadedSize += result.length;
			//JS.log("handleMetadataStreamDownload "+result.length,"total bytes "+_totalDownloadedSize);

			// when decoding finishes, run callbacks
			_geometryStreamDecoder.decodeMetadataStream(result);
		}
		
		private function handleGeometryStreamDownload(result:JSByteArray):void
		{
			_geometryStreamDownloadCounter--;

			if (result == null)
			{
				reportNullResult(this);
				return;
			}

			_totalDownloadedSize += result.length;
			//JS.log("handleGeometryStreamDownload "+result.length,"total bytes "+_totalDownloadedSize);

			// when decoding finishes, run callbacks
			_geometryStreamDecoder.decodeGeometryStream(result);
		}
		
		public static const METADATA_REQUEST_MODE_ALL:String = 'all';
		public static const METADATA_REQUEST_MODE_XY:String = 'xy';
		public static const METADATA_REQUEST_MODE_XYZ:String = 'xyz';
		public static function get metadataRequestModeEnum():Array
		{
			return [METADATA_REQUEST_MODE_ALL, METADATA_REQUEST_MODE_XY, METADATA_REQUEST_MODE_XYZ];
		}
		
		/**
		 * This mode determines which metadata tiles will be requested based on what geometry data is requested.
		 * Possible request modes are:<br>
		 *    all -> All metadata tiles, regardless of requested X-Y-Z range <br>
		 *    xy -> Metadata tiles contained in the requested X-Y range, regardless of Z range <br>
		 *    xyz -> Metadata tiles contained in the requested X-Y-Z range only <br>
		 */
		public static var metadataRequestMode:String = METADATA_REQUEST_MODE_XYZ;
		
		/**
		 * This is the minimum bounding box screen area in pixels required for a geometry to be considered relevant.
		 * Should be >= 1.
		 */		
		public static var geometryMinimumScreenArea:Number = 1;
		
		public static function test_kdtree(weave:Weave, iterations:int = 10):Object
		{
			var cols:Array = WeaveAPI.SessionManager.getLinkableDescendants(weave.root, StreamedGeometryColumn);
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
				ArrayUtils.randomSort(todo);
				var t:int = JS.now();
				var kdtree:KDTree = new KDTree(5);
				for each (var params:Array in todo)
					kdtree.insert(params[0], params[1]);
				t = JS.now() - t;
				Weave.dispose(kdtree);
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
