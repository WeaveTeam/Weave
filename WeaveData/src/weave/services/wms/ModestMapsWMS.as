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
	import com.modestmaps.mapproviders.BlueMarbleMapProvider;
	import com.modestmaps.mapproviders.IMapProvider;
	import com.modestmaps.mapproviders.OpenStreetMapProvider;
	import com.modestmaps.mapproviders.yahoo.YahooAerialMapProvider;
	import com.modestmaps.mapproviders.yahoo.YahooHybridMapProvider;
	import com.modestmaps.mapproviders.yahoo.YahooOverlayMapProvider;
	import com.modestmaps.mapproviders.yahoo.YahooRoadMapProvider;
	
	import flash.display.Bitmap;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import org.openscales.proj4as.ProjConstants;
	
	import weave.api.WeaveAPI;
	import weave.api.getCallbackCollection;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.core.LinkableString;
	import weave.data.ProjectionManager;
	import weave.primitives.Bounds2D;
	import weave.utils.AsyncSort;

	/**
	 * This class is a wrapper around the ModestMaps library for both Microsoft and Yahoo
	 * WMS providers.
	 * 
	 * @author kmonico
	 */
	public class ModestMapsWMS extends AbstractWMS
	{
		public function ModestMapsWMS()
		{
			_srs = IMAGE_PROJECTION_SRS; 

			ProjectionManager.getMercatorTileBoundsInLatLong(_worldBoundsMercator);
			WeaveAPI.ProjectionManager.transformBounds(_tileProjectionSRS, _srs, _worldBoundsMercator); // get world bounds in our Mercator
		}
		
		public const providerName:LinkableString = registerLinkableChild(this,new LinkableString(),handleProviderName);
		
		private function handleProviderName():void
		{
			switch (providerName.value)
			{
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
				case WMSProviders.STAMEN_TONER:
					_mapProvider = new StamenProvider(StamenProvider.STYLE_TONER);
					break;
				case WMSProviders.STAMEN_TERRAIN:
					_mapProvider = new StamenProvider(StamenProvider.STYLE_TERRAIN);
					break;
				case WMSProviders.STAMEN_WATERCOLOR:
					_mapProvider = new StamenProvider(StamenProvider.STYLE_WATERCOLOR);
					break;
				default:
					reportError("Invalid map provider: " + providerName.value);
					return;
			}
			
			_imageWidth = _mapProvider.tileWidth;
			_imageHeight = _mapProvider.tileHeight;
			_currentTileIndex = new WMSTileIndex();
			_urlToTile = new Dictionary();	
			getCallbackCollection(this).triggerCallbacks();
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
		private const _worldBoundsMercator:IBounds2D = new Bounds2D();
		private const _tileProjectionSRS:String = "EPSG:4326"; // constant for modestMaps
		
		// reusable objects
		private const _tempCoord:Coordinate = new Coordinate(NaN, NaN, NaN); 
		private const _tempLocation:Location = new Location(NaN, NaN);
		
		// non-specific names due to reuse
		private const _tempBounds:Bounds2D = new Bounds2D();
		private const _tempBounds2:Bounds2D = new Bounds2D(); 
		private const _tempBounds3:Bounds2D = new Bounds2D();
		private const _tempBounds4:Bounds2D = new Bounds2D();

		override public function requestImages(dataBounds:IBounds2D, screenBounds:IBounds2D, preferLowerQuality:Boolean = false, layerLowerQuality:Boolean = false):Array
		{
			if(_currentTileIndex == null || _mapProvider == null)
				return [];
			var i:int
			var copyDataBounds:Bounds2D = _tempBounds3;
			
			// first determine zoom level using all of the data bounds in lat/lon
			setTempCoordZoomLevel(dataBounds, screenBounds, preferLowerQuality); // this sets _tempCoord.zoom 
			var zoomScale:Number = Math.pow(2, _tempCoord.zoom);
			
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
			var tileXYBounds:Bounds2D = _tempBounds2;
			tileXYBounds.copyFrom(dataBounds);
			_worldBoundsMercator.constrainBounds(tileXYBounds, false);
			WeaveAPI.ProjectionManager.transformBounds(_srs, _tileProjectionSRS, tileXYBounds);
						
			// calculate min and max tile x and y for the zoom level
			dataBoundsToTileXY(tileXYBounds, zoomScale);
			var xTileMin:Number = tileXYBounds.xMin;
			var yTileMin:Number = tileXYBounds.yMin;
			var xTileMax:Number = tileXYBounds.xMax;
			var yTileMax:Number = tileXYBounds.yMax;

			var mercatorTileXYBounds:Bounds2D = _tempBounds2;
			mercatorTileXYBounds.copyFrom(tileXYBounds);
			tileXYToData(mercatorTileXYBounds, zoomScale);
			_worldBoundsMercator.constrainBounds(mercatorTileXYBounds);
			
			
			// get tiles we need using the map's mercator projection because the tiles' bounds must be in this projection
			var lowerQualTiles:Array = _currentTileIndex.getTiles(mercatorTileXYBounds, 0, _tempCoord.zoom - 1);
			var completedTiles:Array = _currentTileIndex.getTiles(mercatorTileXYBounds, _tempCoord.zoom, _tempCoord.zoom);
			for (var x:int = xTileMin; x < xTileMax; ++x)
			{
				for (var y:int = yTileMin; y < yTileMax; ++y)
				{
					var thisTileMercator:Bounds2D = _tempBounds3;
					thisTileMercator.setBounds(x, y, x + 1, y + 1);
					tileXYToData(thisTileMercator, zoomScale);
					
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
					var newTile:WMSTile = registerLinkableChild(this, new WMSTile(thisTileMercator, _imageWidth, _imageHeight, urlRequest));
					newTile.zoomLevel = _tempCoord.zoom; // need to manually set it so tileIndex queries work
					_urlToTile[requestString] = newTile;
					_pendingTiles.push(newTile);
					downloadImage(newTile);
				}
			}

			var tiles:Array;
			if (layerLowerQuality)
				tiles = lowerQualTiles.concat(completedTiles);
			else
				tiles = completedTiles;
			AsyncSort.sortImmediately(tiles, tileSortingComparison);
			return tiles;
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
			else if (_mapProvider is OpenStreetMapProvider || _mapProvider is StamenProvider)
				maxZoom = 18;
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
				numTiles = Math.pow(4, i); // 4^n tiles at zoom level n
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
			var higherPrecision:Number = (worldArea / Math.pow(4, higherQualZoomLevel)) / imageArea;
			var lowerPrecision:Number = (worldArea / Math.pow(4, lowerQualZoomLevel)) / imageArea;
			if ((lowerPrecision - requestedPrecision) < (requestedPrecision - higherPrecision))
				_tempCoord.zoom = lowerQualZoomLevel;
			else
				_tempCoord.zoom = higherQualZoomLevel;
		}
		
		/**
		 * This function will convert a bounds in lat/long coordinates to tile (x, y) coordinates.
		 * 
		 * @param inputAndOutput the input/output buffer.
		 * @param zoomScale The value 2^zoom where zoom is the zoom level.
		 */
		private function dataBoundsToTileXY(inputAndOutput:Bounds2D, zoomScale:Number):void
		{
			inputAndOutput.makeSizePositive();
			
			inputAndOutput.xMin = zoomScale * (inputAndOutput.xMin + 180) / 360.0; 
			inputAndOutput.xMax = zoomScale * (inputAndOutput.xMax + 180) / 360.0; 
			
			var latRadians:Number = inputAndOutput.yMin * Math.PI / 180;
			inputAndOutput.yMin = zoomScale * (1 - (Math.log(Math.tan(latRadians) + (1 / Math.cos(latRadians))) / Math.PI)) / 2.0;
			latRadians = inputAndOutput.yMax * Math.PI / 180;
			inputAndOutput.yMax = zoomScale * (1 - (Math.log(Math.tan(latRadians) + (1 / Math.cos(latRadians))) / Math.PI)) / 2.0;
			
			inputAndOutput.makeSizePositive();
			
			inputAndOutput.xMin = Math.floor(inputAndOutput.xMin);
			inputAndOutput.yMin = Math.floor(inputAndOutput.yMin);
			inputAndOutput.xMax = Math.ceil(inputAndOutput.xMax);
			inputAndOutput.yMax = Math.ceil(inputAndOutput.yMax);
			
			// although this may allow the max values to be zoomScale, which is 1 larger than number of tiles,
			// it's not a problem because the tile starting at zoomScale,zoomScale is never requested.
			_tempBounds.setBounds(0, 0, zoomScale, zoomScale); 
			_tempBounds.constrainBounds(inputAndOutput, false);
		}
		
		/**
		 * This function will convert bounds from tile x,y coordinates to data coordinates.
		 * @param inputAndOutput The input/output buffer.
		 * @param zoomScale The value 2^zoom.
		 */
		private function tileXYToData(inputAndOutput:Bounds2D, zoomScale:Number):void
		{
			inputAndOutput.xMin = 360 * (inputAndOutput.xMin / zoomScale) - 180.0;
			inputAndOutput.xMax = 360 * (inputAndOutput.xMax / zoomScale) - 180.0;
			
			var latRadians:Number = Math.atan(ProjConstants.sinh(Math.PI * (1 - 2 * inputAndOutput.yMin / zoomScale)));
			inputAndOutput.yMin = latRadians * 180.0 / Math.PI;
			latRadians = Math.atan(ProjConstants.sinh(Math.PI * (1 - 2 * inputAndOutput.yMax / zoomScale)));
			inputAndOutput.yMax = latRadians * 180.0 / Math.PI;
			
			inputAndOutput.makeSizePositive();
			WeaveAPI.ProjectionManager.transformBounds(_tileProjectionSRS, _srs, inputAndOutput);
		}
		

		/**
		 * This function will download the image data for a tile.
		 * 	
		 * @param tile The tile whose bitmap will be downloaded.
		 */
		private function downloadImage(tile:WMSTile):void
		{
			tile.downloadImage(handleImageDownload, handleImageDownloadFault, tile);
		}

		/**
		 * This function is called when an image is done downloading. The image is then cached and saved.
		 * 
		 * @param event The result event.
		 * @param token The tile.
		 */
		private function handleImageDownload(event:ResultEvent, tile:WMSTile):void
		{
			tile.bitmapData = (event.result as Bitmap).bitmapData;
			handleTileDownload(tile);
		}
		
		/**
		 * This function reports an error downloading an image. A download may fail with a valid URL.
		 * 
		 * @param event The fault event.
		 * @param token The tile.
		 */
		private function handleImageDownloadFault(event:FaultEvent, tile:WMSTile):void
		{
			tile.bitmapData = null; // a plotter should handle this
			reportError(event);
			
			/** 
			 * @TODO This may not be appropriate because a download with a valid URL may fail.
			 * It may be a better idea to try again once, and if it fails, never try again.
			 **/
			
			handleTileDownload(tile);
		}
		
		override public function getAllowedBounds(output:IBounds2D):void
		{
			return output.copyFrom(_worldBoundsMercator);
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
			else if (_mapProvider is StamenProvider)
				return 'Map tiles by Stamen Design, under CC BY 3.0. Data by OpenStreetMap, under CC BY SA.';
			
			return '';
		}
	}
}