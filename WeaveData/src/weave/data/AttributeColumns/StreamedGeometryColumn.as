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

package weave.data.AttributeColumns
{
	import flash.utils.ByteArray;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.WeaveAPI;
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerDisposableChild;
	import weave.api.services.IWeaveGeometryTileService;
	import weave.core.ErrorManager;
	import weave.services.beans.GeometryStreamMetadata;
	import weave.utils.ColumnUtils;
	import weave.utils.GeometryStreamDecoder;
	
	/**
	 * StreamedGeometryColumn
	 * 
	 * @author adufilie
	 */
	public class StreamedGeometryColumn extends AbstractAttributeColumn
	{
		public function StreamedGeometryColumn(tileService:IWeaveGeometryTileService, metadata:XML = null)
		{
			super(metadata);
			
			_tileService = tileService;
			_geometryStreamDecoder.keySet.addImmediateCallback(this, triggerCallbacks);
			
			// request a list of tiles for this geometry collection
			var query:AsyncToken = _tileService.getTileDescriptors();
			query.addAsyncResponder(handleGetTileDescriptors, handleGetTileDescriptorsFault, metadata);
		}
		
		override public function getMetadata(propertyName:String):String
		{
			if (propertyName == AttributeColumnMetadata.PROJECTION_SRS)
				return _geometryStreamDecoder.projectionSrsCode;
			return super.getMetadata(propertyName);
		}
		
		/**
		 * This is a list of unique keys this column defines values for.
		 */
		override public function get keys():Array
		{
			return _geometryStreamDecoder.keySet.keys;
		}
		
		override public function containsKey(key:IQualifiedKey):Boolean
		{
			return _geometryStreamDecoder.keySet.containsKey(key);
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
				value = key.keyType + '#' + key.localName;
			
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
			return (_streamDownloadCounter > 0);			
		}
		
		private var _tileService:IWeaveGeometryTileService;
		private const _geometryStreamDecoder:GeometryStreamDecoder = newLinkableChild(this, GeometryStreamDecoder);
		private var _streamDownloadCounter:int = 0;
		
		public var metadataTilesPerQuery:int = 10; //10;
		public var geometryTilesPerQuery:int = 10; //30;
		
		public function requestGeometryDetail(dataBounds:IBounds2D, lowestImportance:Number):void
		{
			//trace("requestGeometryDetail",dataBounds,lowestImportance);
			if (dataBounds == null || isNaN(lowestImportance))
				return;
			
			// don't bother downloading if we know the result will be empty
			if (dataBounds.isUndefined() || dataBounds.isEmpty())
				return;
			
			var query:AsyncToken;
			
			//TODO: instead of a single geometryStreamDecoder tile query, make several tile queries
			// and make a single webservice query for each group of results.
			
			// request ALL metadata tiles
			var metadataTileIDs:Array = _geometryStreamDecoder.getRequiredMetadataTileIDs(
				_geometryStreamDecoder.collectiveBounds, 0, true
			).sort(Array.NUMERIC);
			// request geometry tiles needed for desired dataBounds
			var geometryTileIDs:Array = _geometryStreamDecoder.getRequiredGeometryTileIDs(
				dataBounds, lowestImportance, true
			).sort(Array.NUMERIC);

//			if (metadataTileIDs.length > 0)
//				trace("requesting metadata tiles: " + metadataTileIDs);
//			if (geometryTileIDs.length > 0)
//				trace("requesting geometry tiles: " + geometryTileIDs);
			
			// make requests for groups of tiles
			while (metadataTileIDs.length > 0)
			{
				query = _tileService.getMetadataTiles(metadataTileIDs.splice(0, metadataTilesPerQuery));
				query.addAsyncResponder(handleMetadataStreamDownload, handleDownloadFault, query);
				
				_streamDownloadCounter++;
			}
			// make requests for groups of tiles
			while (geometryTileIDs.length > 0)
			{
				query = _tileService.getGeometryTiles(geometryTileIDs.splice(0, geometryTilesPerQuery));
				query.addAsyncResponder(handleGeometryStreamDownload, handleDownloadFault, query);
				
				_streamDownloadCounter++;
			} 
		}
		
		private function handleDownloadFault(event:FaultEvent, token:Object = null):void
		{
			WeaveAPI.ErrorManager.reportError(event.fault);
			//trace("handleDownloadFault",token,ObjectUtil.toString(event));
			_streamDownloadCounter--;
		}

		private function handleGetTileDescriptorsFault(event:FaultEvent, token:Object = null):void
		{
			WeaveAPI.ErrorManager.reportError(event.fault);
		}
		
		private function handleGetTileDescriptors(event:ResultEvent, token:Object = null):void
		{
			if (event.result == null)
			{
				reportNullResult();
				return;
			}
			try
			{
				//trace("handleGetTileDescriptors",ObjectUtil.toString(token),ObjectUtil.toString(result));

				var result:GeometryStreamMetadata = new GeometryStreamMetadata(event.result);
				
				_metadata.@keyType = result.keyType;
				_geometryStreamDecoder.keyType = result.keyType;
				_geometryStreamDecoder.projectionSrsCode = result.projection;
				
				// handle metadata tiles
				_geometryStreamDecoder.decodeMetadataTileList(result.metadataTileDescriptors);
				
				// handle geometry tiles
				_geometryStreamDecoder.decodeGeometryTileList(result.geometryTileDescriptors);
				
			}
			catch (error:Error)
			{
				trace('handleGetTileDescriptors() error parsing result from server');
				WeaveAPI.ErrorManager.reportError(error);
			}
		}
		

		private function reportNullResult():void
		{
			var msg:String = "Did not receive any data from service for geometry column: " + ColumnUtils.getTitle(this);
			WeaveAPI.ErrorManager.reportError(new Error(msg));
		}
		
		private var _totalDownloadedSize:int = 0;

		private function handleMetadataStreamDownload(event:ResultEvent, token:Object = null):void
		{
			_streamDownloadCounter--;
			
			if (event.result == null)
			{
				reportNullResult();
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
			_streamDownloadCounter--;

			if (event.result == null)
			{
				reportNullResult();
				return;
			}

			var result:ByteArray = event.result as ByteArray;
			_totalDownloadedSize += result.bytesAvailable;
			//trace("handleGeometryStreamDownload "+result.bytesAvailable,"total bytes "+_totalDownloadedSize);

			// when decoding finishes, run callbacks
			_geometryStreamDecoder.decodeGeometryStream(result);
		}
	}
}
