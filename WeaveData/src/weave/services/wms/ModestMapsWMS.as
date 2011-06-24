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


package weave.services.wms
{
	import com.modestmaps.core.Coordinate;
	import com.modestmaps.geo.Location;
	import com.modestmaps.mapproviders.ACTransitMapProvider;
	import com.modestmaps.mapproviders.BlueMarbleMapProvider;
	import com.modestmaps.mapproviders.IMapProvider;
	import com.modestmaps.mapproviders.OpenStreetMapProvider;
	import com.modestmaps.mapproviders.microsoft.MicrosoftAerialMapProvider;
	import com.modestmaps.mapproviders.microsoft.MicrosoftHybridMapProvider;
	import com.modestmaps.mapproviders.microsoft.MicrosoftProvider;
	import com.modestmaps.mapproviders.microsoft.MicrosoftRoadMapProvider;
	import com.modestmaps.mapproviders.yahoo.YahooAerialMapProvider;
	import com.modestmaps.mapproviders.yahoo.YahooHybridMapProvider;
	import com.modestmaps.mapproviders.yahoo.YahooOverlayMapProvider;
	import com.modestmaps.mapproviders.yahoo.YahooRoadMapProvider;
	
	import flash.display.Bitmap;
	import flash.net.URLRequest;
	import flash.system.Security;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.WeaveAPI;
	import weave.api.primitives.IBounds2D;
	import weave.api.services.IWMSService;
	import weave.core.ErrorManager;
	import weave.primitives.Bounds2D;
	import org.openscales.proj4as.ProjConstants;
	import org.openscales.proj4as.proj.ProjMerc;

	/**
	 * This class is a wrapper around the ModestMaps library for both Microsoft and Yahoo
	 * WMS providers.
	 * 
	 * @author kmonico
	 */
	public class ModestMapsWMS extends AbstractWMS implements IWMSService
	{
		public function ModestMapsWMS()
		{
			_srs = IMAGE_PROJECTION_SRS; 

			_tempBounds.copyFrom(_worldBoundsMercator);
			setReprojectedBounds(_tempBounds, _worldBoundsMercator, _tileProjectionSRS, _srs); // get world bounds in our Mercator
		}
		
		override public function setProvider(provider:String):void
		{
			switch (provider)
			{
				// we cannot use Microsoft services, but we can keep the code 
				
				/*case 'Microsoft Aerial':
					_mapProvider = new MicrosoftAerialMapProvider();
					break;
				case 'Microsoft Hybrid':
					_mapProvider = new MicrosoftHybridMapProvider();
					break;
				case 'Microsoft RoadMap':
					_mapProvider = new MicrosoftRoadMapProvider();
					break;*/
				case WMSProviders.BLUE_MARBLE_MAP:
					_mapProvider = new BlueMarbleMapProvider();
					break;
				case WMSProviders.OPEN_STREET_MAP:
					_mapProvider = new OpenStreetMapProvider();
					break;
				case WMSProviders.MAPQUEST:
					_mapProvider = new OpenMapQuestProvider();
					break;
				case WMSProviders.MAPQUEST_AERIAL:
					_mapProvider = new OpenMapQuestAerialProvider();
					break;
				default:
					ErrorManager.reportError(new Error("Attempt to set invalid map provider."));
					return;
					break;
			}
			
			_imageWidth = _mapProvider.tileWidth;
			_imageHeight = _mapProvider.tileHeight;
			_currentTileIndex = new WMSTileIndex();
			triggerCallbacks();
		}
		
		public function get provider():IMapProvider
		{
			return _mapProvider;
		}
		
		static public const IMAGE_PROJECTION_SRS:String = 'EPSG:3857';
		
		// the provider from the ModestMaps library used for  
		private var _mapProvider:IMapProvider = null;
		
		// image dimensions
		private var _imageWidth:int;
		private var _imageHeight:int;
		
		// some parameters about the tiles
		private const _minWorldLon:Number = -180.0 + ProjConstants.EPSLN; // because Proj4 wraps coordinates
		private const _maxWorldLon:Number = 180.0 - ProjConstants.EPSLN; // because Proj4 wraps coordinates
		private const _minWorldLat:Number = -Math.atan(ProjConstants.sinh(Math.PI)) * ProjConstants.R2D; 
		private const _maxWorldLat:Number = Math.atan(ProjConstants.sinh(Math.PI)) * ProjConstants.R2D;
		private const _worldBoundsMercator:IBounds2D = new Bounds2D(_minWorldLon, _minWorldLat, _maxWorldLon, _maxWorldLat);
		private const _tileProjectionSRS:String = "EPSG:4326"; // constant for modestMaps
		
		// reusable objects
		private const _tempCoord:Coordinate = new Coordinate(NaN, NaN, NaN); 
		private const _tempLocation:Location = new Location(NaN, NaN);
		
		// non-specific names due to reuse
		private const _tempBounds2:Bounds2D = new Bounds2D(); 
		private const _tempBounds3:Bounds2D = new Bounds2D();
		private const _tempBounds4:Bounds2D = new Bounds2D();

		override public function requestImages(dataBounds:IBounds2D, screenBounds:IBounds2D, lowerQuality:Boolean = false):Array
		{
			if(_currentTileIndex == null || _mapProvider == null)
				return [];
			var i:int
			var copyDataBounds:Bounds2D = _tempBounds3;
			var latLonCopyDataBounds:Bounds2D = _tempBounds4;
			
			// first determine zoom level using all of the data bounds in lat/lon
			setTempCoordZoomLevel(dataBounds, screenBounds, lowerQuality); // this sets _tempCoord.zoom 
			
			// cancel all pending requests which aren't of this zoom level
			for (i = 0; i < _pendingTiles.length; ++i)
			{
				var pendingTile:WMSTile = _pendingTiles[i] as WMSTile;
				if (pendingTile.zoomLevel != _tempCoord.zoom)
				{
					pendingTile.cancelDownload(); // cancel download
					delete _urlToTile[pendingTile.request.url];
					_pendingTiles.splice(i--, 1); // remove from the array and decrement i
				}
			}
			
			// now determine the data bounds we need to covert in lat/lon
			copyDataBounds.copyFrom(dataBounds);
			_worldBoundsMercator.constrainBounds(copyDataBounds, false);
			setReprojectedBounds(copyDataBounds, latLonCopyDataBounds, _srs, _tileProjectionSRS);
						
			var latLonViewingDataBounds:Bounds2D = latLonCopyDataBounds;
			var tileXYBounds:Bounds2D = _tempBounds2;
			// calculate min and max tile x and y for the zoom level
			var zoomScale:Number = Math.pow(2, _tempCoord.zoom);
			dataBoundsToTileXY(latLonViewingDataBounds, tileXYBounds, zoomScale);
			var xTileMin:Number = tileXYBounds.xMin;
			var yTileMin:Number = tileXYBounds.yMin;
			var xTileMax:Number = tileXYBounds.xMax;
			var yTileMax:Number = tileXYBounds.yMax;

			var mercatorTileXYBounds:Bounds2D = _tempBounds2;
			var latLonTileXYBounds:Bounds2D = _tempBounds3;
			tileXYToDataBounds(tileXYBounds, latLonTileXYBounds, zoomScale);
			setReprojectedBounds(latLonTileXYBounds, mercatorTileXYBounds, _tileProjectionSRS, _srs); 
			_worldBoundsMercator.constrainBounds(mercatorTileXYBounds);
			
			
			// get tiles we need using the map's mercator projection because the tiles' bounds must be in this projection
			var lowerQualTiles:Array = _currentTileIndex.getTilesWithinBoundsAndZoomLevels(mercatorTileXYBounds, 0, _tempCoord.zoom - 1);
			var completedTiles:Array = _currentTileIndex.getTilesWithinBounds(mercatorTileXYBounds, _tempCoord.zoom);
			for (var x:int = xTileMin; x < xTileMax; ++x)
			{
				for (var y:int = yTileMin; y < yTileMax; ++y)
				{
					var thisTileXY:Bounds2D = _tempBounds2;
					var thisTileLatLon:Bounds2D = _tempBounds3;
					var thisTileMercator:Bounds2D = _tempBounds2;
					thisTileXY.setBounds(x, y, x + 1, y + 1);
					tileXYToDataBounds(thisTileXY, thisTileLatLon, zoomScale);
					setReprojectedBounds(thisTileLatLon, thisTileMercator, _tileProjectionSRS, _srs);
					
					_tempCoord.row = y;
					_tempCoord.column = x;
					
					// if the coordinate is wrapped around, we don't want it
					if (_mapProvider.sourceCoordinate(_tempCoord).equalTo(_tempCoord) == false)
						continue;
					
					// get the tile URLs... there should only be at most 1
					var requestArray:Array = _mapProvider.getTileUrls(_tempCoord);
					if (requestArray == null)
						continue;
					var requestString:String = requestArray[0]; // always 1 string in this array
					if (_urlToTile[requestString] != undefined)
						continue;
					
					var urlRequest:URLRequest = new URLRequest(requestString);
					// note that thisTileMercator is still in Mercator coords
					var newTile:WMSTile = new WMSTile(thisTileMercator, _imageWidth, _imageHeight, urlRequest);
					newTile.zoomLevel = _tempCoord.zoom; // need to manually set it so tileIndex queries work
					_urlToTile[requestString] = newTile;
					_pendingTiles.push(newTile);
					downloadImage(newTile);
				}
			}

			lowerQualTiles = lowerQualTiles.concat(completedTiles);
			lowerQualTiles = lowerQualTiles.sort(tileSortingComparison);
			return lowerQualTiles;
		}
		
		/**
		 * This is a private method used for sorting an array of WMSTiles.
		 */ 
		private function tileSortingComparison(a:WMSTile, b:WMSTile):int
		{
			// if a is lower quality (lower zoomLevel), it goes before
			if (a.zoomLevel < b.zoomLevel)
				return -1;
			else if (a.zoomLevel == b.zoomLevel)
				return 0;
			else
				return 1;			
		}
		
		/**
		 * This function will reproject a bounds from a source projection to a destination projection.
		 * @param sourceBounds The bounds to reproject.
		 * @param destBounds The bounds for which to save the output.
		 * @param sourceSRS The SRS code of the source projection.
		 * @param destSRS The SRS code of the destination projection.
		 */
		private function setReprojectedBounds(sourceBounds:IBounds2D, destBounds:IBounds2D, sourceSRS:String, destSRS:String):void
		{
			sourceBounds.getMinPoint(_tempPoint);
			WeaveAPI.ProjectionManager.transformPoint(sourceSRS, destSRS, _tempPoint);
			destBounds.setMinPoint(_tempPoint);
			sourceBounds.getMaxPoint(_tempPoint);
			WeaveAPI.ProjectionManager.transformPoint(sourceSRS, destSRS, _tempPoint);
			destBounds.setMaxPoint(_tempPoint);
			
			destBounds.makeSizePositive();
		}
		
		/**
		 * This function sets the value of _tempCoord.zoom.
		 */
		private function setTempCoordZoomLevel(dataBounds:IBounds2D, screenBounds:IBounds2D, lowerQuality:Boolean):void
		{
			var requestedPrecision:Number = dataBounds.getArea() / screenBounds.getArea(); 
			if (lowerQuality == true)
				requestedPrecision *= 4; // go one level higher, which means twice the data width and height => 4 times
			
			var imageArea:int = _imageWidth * _imageHeight;
			var worldArea:Number = _worldBoundsMercator.getArea();
			var higherQualZoomLevel:int = Number.POSITIVE_INFINITY;
			var lowerQualZoomLevel:int = Number.POSITIVE_INFINITY;
			var numTiles:Number;
			var tileArea:Number;
			var tempPrecision:Number;
			var maxZoom:int = 1;
			_tempCoord.zoom = 1;
			
			// not all providers allow the same zoom range
			if (_mapProvider is BlueMarbleMapProvider)
				maxZoom = 9;
			else if (_mapProvider is OpenStreetMapProvider)
				maxZoom = 18;
			else if (_mapProvider is MicrosoftProvider)
				maxZoom = 20;
			else if (_mapProvider is YahooAerialMapProvider)
				maxZoom = 20;
			else if (_mapProvider is YahooRoadMapProvider)
				maxZoom = 20;
			else if (_mapProvider is YahooHybridMapProvider)
				maxZoom = 20;
			else if (_mapProvider is YahooOverlayMapProvider)
				maxZoom = 20;
			else if (_mapProvider is OpenMapQuestProvider)
				maxZoom = 15;
			else if (_mapProvider is OpenMapQuestAerialProvider)
				maxZoom = 7;
			
			
			// very few providers have a zoom of 0, so the loop starts at 1 to prevent enforcement later
			for (var i:int = 1; i <= maxZoom; ++i) // 20 is max provided in ModestMaps Library
			{
				numTiles = Math.pow(2, 2 * i); // 2^(2n) tiles at zoom level n
				tileArea = worldArea / numTiles;
				tempPrecision = tileArea / imageArea;
				if (tempPrecision < requestedPrecision)
				{
					higherQualZoomLevel = i;
					lowerQualZoomLevel = Math.max(i - 1, 1); // one level down or the minimum
					break;
				}
			}
			
			// compare the two qualities--the closer one is the one we want.
			var higherPrecision:Number = (worldArea / Math.pow(2, 2 * higherQualZoomLevel)) / imageArea;
			var lowerPrecision:Number = (worldArea / Math.pow(2, 2 * lowerQualZoomLevel)) / imageArea;
			if ((lowerPrecision - requestedPrecision) < (requestedPrecision - higherPrecision))
				_tempCoord.zoom = lowerQualZoomLevel;
			else
				_tempCoord.zoom = higherQualZoomLevel;
		}
		
		/**
		 * This function will convert a bounds in lat/long coordinates to tile (x, y) coordinates.
		 * 
		 * @param sourceBounds The source bounds.
		 * @param destbounds The destination.
		 * @param zoomScale The value 2^zoom where zoom is the zoom level.
		 * @return The destination bounds.
		 */
		private function dataBoundsToTileXY(sourceBounds:Bounds2D, destBounds:Bounds2D, zoomScale:Number):IBounds2D
		{
			sourceBounds.makeSizePositive();
			
			destBounds.xMin = zoomScale * (sourceBounds.xMin + 180) / 360.0; 
			destBounds.xMax = zoomScale * (sourceBounds.xMax + 180) / 360.0; 
			
			var latRadians:Number = sourceBounds.yMin * Math.PI / 180;
			destBounds.yMin = zoomScale * (1 - (Math.log(Math.tan(latRadians) + (1 / Math.cos(latRadians))) / Math.PI)) / 2.0;
			latRadians = sourceBounds.yMax * Math.PI / 180;
			destBounds.yMax = zoomScale * (1 - (Math.log(Math.tan(latRadians) + (1 / Math.cos(latRadians))) / Math.PI)) / 2.0;
			
			destBounds.makeSizePositive();
			
			destBounds.xMin = Math.floor(destBounds.xMin);
			destBounds.yMin = Math.floor(destBounds.yMin);
			destBounds.xMax = Math.ceil(destBounds.xMax);
			destBounds.yMax = Math.ceil(destBounds.yMax);
			
			// although this may allow the max values to be zoomScale, which is 1 larger than number of tiles,
			// it's not a problem because the tile starting at zoomScale,zoomScale is never requested.
			_tempBounds.setBounds(0, 0, zoomScale, zoomScale); 
			_tempBounds.constrainBounds(destBounds, false);
			
			return destBounds;
		}
		
		/**
		 * This function will convert bounds from tile x,y coordinates to Latitude and Longitude coordinates.
		 * @param sourceBounds The source.
		 * @param destBounds The destination.
		 * @param zoomScale The value 2^zoom.
		 * @return The destBounds.
		 */
		private function tileXYToDataBounds(sourceBounds:Bounds2D, destBounds:Bounds2D, zoomScale:Number):IBounds2D
		{
			destBounds.xMin = 360 * (sourceBounds.xMin / zoomScale) - 180.0;
			destBounds.xMax = 360 * (sourceBounds.xMax / zoomScale) - 180.0;

			var latRadians:Number = Math.atan(ProjConstants.sinh(Math.PI * (1 - 2 * sourceBounds.yMin / zoomScale)));
			destBounds.yMin = latRadians * 180.0 / Math.PI;
			latRadians = Math.atan(ProjConstants.sinh(Math.PI * (1 - 2 * sourceBounds.yMax / zoomScale)));
			destBounds.yMax = latRadians * 180.0 / Math.PI;
			
			destBounds.makeSizePositive();

			return destBounds;
		}
		

		/**
		 * This function will download the image data for a tile.
		 * 	
		 * @param tile The tile whose bitmap will be downloaded.
		 */
		public function downloadImage(tile:WMSTile):void
		{
			tile.downloadImage(handleImageDownload, handleImageDownloadFault, tile);
		}

		/**
		 * This function is called when an image is done downloading. The image is then cached and saved.
		 * 
		 * @param event The result event.
		 * @param token The tile.
		 */
		private function handleImageDownload(event:ResultEvent, token:Object = null):void
		{
			var tile:WMSTile = token as WMSTile;

			tile.bitmapData = (event.result as Bitmap).bitmapData;
			handleTileDownload(tile);
		}
		
		/**
		 * This function reports an error downloading an image. A download may fail with a valid URL.
		 * 
		 * @param event The fault event.
		 * @param token The tile.
		 */
		private function handleImageDownloadFault(event:FaultEvent, token:Object = null):void
		{
			var tile:WMSTile = token as WMSTile;
			
			tile.bitmapData = null; // a plotter should handle this
			ErrorManager.reportError(event.fault);
			
			/** 
			 * @TODO This may not be appropriate because a download with a valid URL may fail.
			 * It may be a better idea to try again once, and if it fails, never try again.
			 **/
			
			handleTileDownload(tile);
		}
		
		override public function getAllowedBounds():IBounds2D
		{
			return _worldBoundsMercator.cloneBounds(); 
		}
		
		/**
		 * The width of an image.
		 */
		public function get imageWidth():int
		{
			return _imageWidth;
		}
		
		/**
		 * The height of an image.
		 */
		public function get imageHeight():int
		{
			return _imageHeight;
		}
		
		override public function getProvider():*
		{
			return _mapProvider;
		}
		
		override public function getCreditInfo():String
		{
			if (_mapProvider is BlueMarbleMapProvider)
				return '2011 (c) NASA Jet Propulsion Laboratory at California Institute of Technology';
			else if (_mapProvider is OpenStreetMapProvider)
				return '2011 (c) OpenStreetMap contributors, CC-BY-SA';
			else if (_mapProvider is OpenMapQuestProvider)
				return 'Tiles Courtesy of MapQuest and (c) OpenStreetMap contributors, CC-BY-SA';
			else if (_mapProvider is OpenMapQuestAerialProvider)
				return 'Portions Courtesy NASA/JPL-Caltech and U.S. Depart. of Agriculture, Farm Service Agency';
			
			return '';
		}
	}
}