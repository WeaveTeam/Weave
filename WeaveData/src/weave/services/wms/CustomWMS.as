package weave.services.wms
{
	import com.as3xls.xls.formula.Tokens;
	import com.modestmaps.core.Coordinate;
	import com.modestmaps.geo.Location;
	
	import flash.display.Bitmap;
	import flash.net.URLRequest;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.StringUtil;
	
	import org.openscales.proj4as.ProjConstants;
	
	import weave.api.WeaveAPI;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.data.ProjectionManager;
	import weave.primitives.Bounds2D;
	import weave.primitives.LinkableNumberFormatter;
	import weave.utils.AsyncSort;

	public class CustomWMS extends AbstractWMS
	{
		public function CustomWMS()
		{
			_currentTileIndex = new WMSTileIndex();
			getCallbackCollection(this).triggerCallbacks();
		}
		
		override public function getAllowedBounds(output:IBounds2D):void
		{
			ProjectionManager.getMercatorTileBoundsInLatLong(_tempBounds);
			setReprojectedBounds(_tempBounds, output, "EPSG:4326", tileProjectionSRS.value);
		}
		
		override public function setProvider(provider:String):void
		{
			
		}
		
		override public function getProvider():*
		{
			return WMSProviders.CUSTOM_MAP;
		}
		
		public const wmsURL:LinkableString = registerLinkableChild(this,new LinkableString(),getImageAttributes);
		public const tileProjectionSRS:LinkableString = registerLinkableChild(this,new LinkableString("EPSG:3857"));
		public const maxZoom:LinkableNumber = registerLinkableChild(this,new LinkableNumber(18));
		
		static public const IMAGE_PROJECTION_SRS:String = 'EPSG:3857';
		
		// reusable objects
		private const _tempCoord:Coordinate = new Coordinate(NaN, NaN, NaN); 
		private const _tempLocation:Location = new Location(NaN, NaN);
		
		// non-specific names due to reuse
		private const _tempBounds2:Bounds2D = new Bounds2D(); 
		private const _tempBounds3:Bounds2D = new Bounds2D();
		private const _tempBounds4:Bounds2D = new Bounds2D();
		
		private var _imageHeight:Number = NaN;
		private var _imageWidth:Number = NaN;
		
		private var imageAttributesSet:Boolean= false;
		
		
		private function getImageAttributes():void
		{
			if(!wmsURL.value)
				return;
			
			//http://tiles.domain.com/layer/{z}/{x}/{y}.png			
			
			var basicReq:String = getTileUrls(new Coordinate(0,0,0));
			var instance:CustomWMS = this;
			WeaveAPI.URLRequestUtils.getContent(
				this,
				new URLRequest(basicReq),
				function(event:ResultEvent,token:Object=null):void
				{
					_imageWidth = (event.result as Bitmap).width;
					_imageHeight = (event.result as Bitmap).height;
					imageAttributesSet = true;
					getCallbackCollection(instance).triggerCallbacks();
				},
				function(event:FaultEvent,token:Object=null):void
				{
					//setting defaults values of 256 if there is an error in the request
					_imageWidth = 256;
					_imageHeight = 256;
					imageAttributesSet = true;
					getCallbackCollection(instance).triggerCallbacks();
				}
				
			)
		
		}
		
		override public function requestImages(dataBounds:IBounds2D, screenBounds:IBounds2D, preferLowerQuality:Boolean = false, layerLowerQuality:Boolean = false):Array
		{
			if(_currentTileIndex == null || !wmsURL.value || !imageAttributesSet)
				return [];
			var i:int
			var copyDataBounds:Bounds2D = _tempBounds3;
			var latLonCopyDataBounds:Bounds2D = _tempBounds4;
			
			
			// first determine zoom level using all of the data bounds in lat/lon
			setTempCoordZoomLevel(dataBounds, screenBounds, preferLowerQuality); // this sets _tempCoord.zoom 
			
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
			getAllowedBounds(_tempBounds);
			_tempBounds.constrainBounds(copyDataBounds, false);
			setReprojectedBounds(copyDataBounds, latLonCopyDataBounds, tileProjectionSRS.value, "EPSG:4326");
			
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
			setReprojectedBounds(latLonTileXYBounds, mercatorTileXYBounds, "EPSG:4326", tileProjectionSRS.value);
			getAllowedBounds(_tempBounds);
			_tempBounds.constrainBounds(mercatorTileXYBounds);
			
			
			// get tiles we need using the map's mercator projection because the tiles' bounds must be in this projection
			var lowerQualTiles:Array = _currentTileIndex.getTiles(mercatorTileXYBounds, 0, _tempCoord.zoom - 1);
			var completedTiles:Array = _currentTileIndex.getTiles(mercatorTileXYBounds, _tempCoord.zoom, _tempCoord.zoom);
			for (var x:int = xTileMin; x < xTileMax; ++x)
			{
				for (var y:int = yTileMin; y < yTileMax; ++y)
				{
					var thisTileXY:Bounds2D = _tempBounds2;
					var thisTileLatLon:Bounds2D = _tempBounds3;
					var thisTileMercator:Bounds2D = _tempBounds2;
					thisTileXY.setBounds(x, y, x + 1, y + 1);
					tileXYToDataBounds(thisTileXY, thisTileLatLon, zoomScale);
					setReprojectedBounds(thisTileLatLon, thisTileMercator, "EPSG:4326", tileProjectionSRS.value);
					
					_tempCoord.row = y;
					_tempCoord.column = x;
					
					// if the coordinate is wrapped around, we don't want it
//					if (_mapProvider.sourceCoordinate(_tempCoord).equalTo(_tempCoord) == false)
//						continue;
					
					// get the tile URLs
					var requestString:String = getTileUrls(_tempCoord);
					if(requestString == null)
						continue;
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
		
		public const creditInfo:LinkableString = registerLinkableChild(this,new LinkableString(""));
		override public function getCreditInfo():String
		{
			return creditInfo.value;
		}
		
		
		/**
		 * This function sets the value of _tempCoord.zoom.
		 */
		private function setTempCoordZoomLevel(dataBounds:IBounds2D, screenBounds:IBounds2D, lowerQuality:Boolean):void
		{
			var requestedPrecision:Number = dataBounds.getArea() / screenBounds.getArea(); 
			if (lowerQuality == true)
				requestedPrecision *= 4; // go one level higher, which means twice the data width and height => 4 times
			
			getAllowedBounds(_tempBounds);
			var worldArea:Number = _tempBounds.getArea();
			var imageArea:int = _imageWidth* _imageHeight;
			var higherQualZoomLevel:int = Number.POSITIVE_INFINITY;
			var lowerQualZoomLevel:int = Number.POSITIVE_INFINITY;
			var numTiles:Number;
			var tileArea:Number;
			var tempPrecision:Number;
			_tempCoord.zoom = 1;
			
			// very few providers have a zoom of 0, so the loop starts at 1 to prevent enforcement later
			for (var i:int = 1; i <= maxZoom.value; ++i) // 20 is max provided in ModestMaps Library
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
		
		private function getTileUrls(coord:Coordinate):String
		{
			if(!wmsURL || !wmsURL.value)
				return null;
			
			var url:String = wmsURL.value;
			
			url= url.replace('{z}','{0}');
			url= url.replace('{x}','{1}');
			url= url.replace('{y}','{2}');
			
			url = StringUtil.substitute(url,coord.zoom.toString(),coord.column.toString(),coord.row.toString());
			
			return url;
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
	}
}