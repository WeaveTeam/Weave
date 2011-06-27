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
	import flash.display.Bitmap;
	import flash.events.MouseEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import org.openscales.proj4as.ProjConstants;
	
	import weave.api.primitives.IBounds2D;
	import weave.api.services.IWMSService;
	import weave.core.ErrorManager;
	import weave.core.LinkableString;
	import weave.core.StageUtils;
	import weave.primitives.Bounds2D;
	import weave.services.URLRequestUtils;

	/**
	 * This class handles the requests for tiles from NASA's OnEarth WMS.
	 * The tiling service is not fully standardized and subject to change. At
	 * this time, we only support requests for BMNG images with varying months.
	 * 
	 * The OnEarth service provided by the ModestMaps library is limited and often
	 * doesn't work. 
	 * 
	 * @author kmonico
	 */
	public class OnEarthProvider extends AbstractWMS implements IWMSService
	{
		public function OnEarthProvider()
		{
			_srs = "EPSG:4326"; 
			
			// these cannot change until NASA standardizes their OnEarth service
			_tiledName = "BMNG January";
			_shapeLayers = "BMNG"; 
			_requestURL.value = "http://onearth.jpl.nasa.gov/wms.cgi?";
			_imageFormat = "jpeg";
			_styles.value = "Dec"; // this can be cycled
			_transparent = false;
			_currentTileIndex = new WMSTileIndex();
			_stylesToTileIndex[_styles.value] = _currentTileIndex;
			
			_tileServiceXML = XML(_tileRequestClass.data);
			parseXML();
		}
		
		override public function cancelPendingRequests():void
		{
			for each (var tile:WMSTile in _pendingTiles)
			{
				tile.cancelDownload();
				delete _urlToTile[tile.request.url];
			}
			
			_pendingTiles.length = 0;
		}
		
		static public const IMAGE_PROJECTION_SRS:String = 'EPSG:4326';
		
		/**
		 * This is a mapping of styles to TileIndex. There should be a separate TileIndex
		 * for each style.
		 */
		private const _stylesToTileIndex:Dictionary = new Dictionary();
		
		/**
		 * This is an array containing an array of bounding box 
		 * values (xMin, xMax, yMin, yMax) from the regexp results.
		 * These results are saved to avoid the need to reparse the XML
		 * when the zoomlevel of the plotter has changed.
		 */
		private var _bboxList:Array = [];
		
		// parameters defining the tile patterns
		private var _requestURL:LinkableString = new LinkableString();
		private var _shapeLayers:String;
		private var _styles:LinkableString = new LinkableString();
		private var _imageFormat:String;
		private var _imageWidth:int;
		private var _imageHeight:int;
		private var _transparent:Boolean;
		
		// the XML of the tile service is embedded to prevent redownloading
		[Embed(source="/weave/resources/onearth-wms.xml")]
		private var _tileRequestClass:Class;
		private var _tileServiceXML:XML;
		
		/**
		 * The list of tiled patterns for the current tile parameters.
		 */
		private var _tiledPatternXML:XMLList = null;
		
		/**
		 * This array contains the parameters needed to fill the request URL.
		 * The even indices are constants, and the odd indices must be filled.
		 */
		private const _requestURLParams:Array = [
			'request=',			'',
			'&layers=',			'',
			'&srs=', 			'',
			'&format=image/',	'',
			'&styles=', 		'',
			'&width=', 			'',
			'&height=', 		'',
			'&bbox=', 			''
			];
		
		/**
		 * This array contains the months allowed for the styles of the BMNG tiles.
		 */
		private static const _stylesToMonths:Array = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
		
		/**
		 * This object contains the absolute xMin, yMin, xMax, and yMax allowed for
		 * the tile pattern.
		 */
		private const _tilePatternBounds:Bounds2D = new Bounds2D();

		
		/**
		 * This function will change the month.
		 * @param newMonth The month to use.
		 */
		public function changeStyleToMonth(newMonth:String):void
		{
			cancelPendingRequests();
			
			// set the style and get a tiling index, if necessary
			_styles.value = newMonth;
			
			var newIndex:WMSTileIndex = _stylesToTileIndex[_styles.value] as WMSTileIndex;
			if (newIndex == null)
			{
				newIndex = new WMSTileIndex();
				_stylesToTileIndex[_styles.value] = newIndex;
			}
			
			_currentTileIndex = newIndex;
			triggerCallbacks();
		}
		
		private function parseXML():void
		{
			var i:int;
			
			var tiledPatterns:XMLList = _tileServiceXML.descendants("TiledPatterns");
			var tiledPatternsBounds:XML = tiledPatterns.child("LatLonBoundingBox")[0];
			
			_tilePatternBounds.setBounds(
				tiledPatternsBounds.@minx, tiledPatternsBounds.@miny,
				tiledPatternsBounds.@maxx, tiledPatternsBounds.@maxy
			);
			
			// set the correct group
			var tiledGroups:XMLList = _tileServiceXML.descendants("TiledGroup");
			var thisGroup:XML = null;
			for (i = 0; i < tiledGroups.length(); ++i)
			{
				var currentTiledGroup:XML = tiledGroups[i];
				var nameXML:XML = (currentTiledGroup.descendants("Name"))[0];
				var nameString:String = (nameXML.text())[0];
				if (nameString == _tiledName)
				{
					thisGroup = currentTiledGroup;
					break;
				}
			}
			
			// if we didn't find the correct group, return
			if (thisGroup== null)
				return;
		
			// reset the _bboxList
			_bboxList.length = 0;
			
			// if the tiles are not all of the same shapeLayers, return 
			var tilePatternsList:XMLList = thisGroup.descendants("TilePattern");
			var thisTiledPattern:XML = null;
			
			// match layers=*   where * is anything up to eol or &
			var layersPattern:RegExp = new RegExp("layers=(?P<val>[^&]+)");
			// match bbox=d,d,d,d where d is a signed int 
			var bboxPattern:RegExp = new RegExp("bbox=(?P<xMin>[-0-9]+),(?P<yMin>[-0-9]+),(?P<xMax>[-0-9]+),(?P<yMax>[-0-9]+)");
			// match width=d&height=d where d is a signed int
			var imageDimPattern:RegExp = new RegExp("width=(?P<width>[0-9]+)&height=(?P<height>[0-9]+)");
			var bboxPatternsResult:Array = null; 
			var imageDimPatternsResult:Array = null;
			for (i = 0; i < tilePatternsList.length(); ++i)
			{
				var currentTilePattern:XML = tilePatternsList[i];
				var s:String = currentTilePattern.toString(); // create a string we can parse
				if (s.length == 0)
					continue;
				var tilePatternsResult:Array = layersPattern.exec(s);
				if (tilePatternsResult == null) // no matches
					continue;
				if (tilePatternsResult.val != _shapeLayers) // invalid tile service
					return;
				
				bboxPatternsResult = bboxPattern.exec(s);
				if (bboxPatternsResult == null) // no matches--can't do anything else
					continue;
				_bboxList.push(bboxPatternsResult); // save matches

				imageDimPatternsResult = imageDimPattern.exec(s);
				if (imageDimPatternsResult == null)
					continue; // these must be defined for valid xml, and we require they be the same for all tiles in this pattern
				_imageWidth = imageDimPatternsResult.width;
				_imageHeight = imageDimPatternsResult.height;
			}

			// set min and max zoom levels
			for (i = 0; i < _bboxList.length; ++i)
			{
				var bboxWidth:Number = _bboxList[i].xMax - _bboxList[i].xMin;
				var bboxHeight:Number = _bboxList[i].yMax - _bboxList[i].yMin;
				var bboxArea:Number = bboxHeight * bboxWidth;
				var bboxZoomLevel:Number = bboxArea / (_imageHeight * _imageWidth);
				
				if (bboxZoomLevel > _maxZoomLevel)
					_maxZoomLevel = bboxZoomLevel;
				
				if (bboxZoomLevel < _minZoomLevel)
					_minZoomLevel = bboxZoomLevel;
			}
			// everything went well
			_tiledPatternXML = tilePatternsList;
		}
		
		private var _minZoomLevel:Number = Number.POSITIVE_INFINITY;
		private var _maxZoomLevel:Number = 0;
		private const thisBounds:IBounds2D = new Bounds2D();
		
		override public function requestImages(dataBounds:IBounds2D, screenBounds:IBounds2D, lowerQuality:Boolean = false):Array
		{
			if (_tiledPatternXML == null)
				return null;

			var actualZoomLevel:Number = dataBounds.getArea() / screenBounds.getArea(); 
			if (lowerQuality == true)
				actualZoomLevel *= 4; // double the bounds' dimensions to get 4 * area, while not requesting extra tiles
			
			var i:int;
			var j:int;
			var thisZoomLevel:Number;
			var lowerQualLevel:Number;
			var higherQualLevel:Number;
			
			// iterate through bbox in order. the first one with more precision will be saved in thisBounds
			// the tiles are listed in XML from least quality to most quality
			// thisZoomLevel is always obtained from thisBounds, which uses the starting tile bbox
			for (i = 0; i < _bboxList.length; ++i)
			{
				lowerQualLevel = thisZoomLevel;
				thisBounds.setBounds(_bboxList[i].xMin, _bboxList[i].yMin, _bboxList[i].xMax, _bboxList[i].yMax);
				thisZoomLevel = thisBounds.getArea() / (_imageHeight * _imageWidth);
				if (thisZoomLevel < actualZoomLevel)
					break;
			}
			var tileWidth:int = thisBounds.getWidth();
			var tileHeight:int = thisBounds.getHeight();
			
			if (++i < _bboxList.length)
			{
				_tempBounds.setBounds(_bboxList[i].xMin, _bboxList[i].yMin, _bboxList[i].xMax, _bboxList[i].yMax);
				higherQualLevel = _tempBounds.getArea() / (_imageHeight * _imageWidth);
			} 
			else 
				higherQualLevel = thisZoomLevel;
			
			// cancel all pending requests which aren't of this zoom level
			for (i = 0; i < _pendingTiles.length; ++i)
			{
				var pendingTile:WMSTile = _pendingTiles[i] as WMSTile;
				if (pendingTile.zoomLevel != thisZoomLevel)
				{
					pendingTile.cancelDownload(); // cancel download
					delete _urlToTile[pendingTile.request.url];
					_pendingTiles.splice(i--, 1); // remove from the array and decrement i
				}
			}
			
			// get completed tiles of all 3 zoom levels
			var completedTiles:Array = _currentTileIndex.getTilesWithinBounds(dataBounds, thisZoomLevel);
			var lowerQualTiles:Array;
			if (lowerQualLevel != thisZoomLevel)
				lowerQualTiles = _currentTileIndex.getTilesWithinBoundsAndZoomLevels(dataBounds, lowerQualLevel, Number.POSITIVE_INFINITY);
			else
				lowerQualTiles = [];
			
			_tempBounds.copyFrom(dataBounds);
			_tilePatternBounds.constrainBounds(_tempBounds, false);
			
			// set the tile Min and Max bounds for iteration.
			// note the tiles start from (xMin, yMax)
			var xTileMin:int = _tilePatternBounds.xMin + tileWidth 
				* Math.floor((_tempBounds.xMin - _tilePatternBounds.xMin) / tileWidth);
			var xTileMax:int = _tilePatternBounds.xMin + tileWidth 
				* Math.ceil((_tempBounds.xMax - _tilePatternBounds.xMin)/ tileWidth);
			var yTileMin:int = _tilePatternBounds.yMax - tileHeight 
				* Math.ceil((_tilePatternBounds.yMax - _tempBounds.yMin) / tileHeight);
			var yTileMax:int = _tilePatternBounds.yMax - tileHeight 
				* Math.floor((_tilePatternBounds.yMax - _tempBounds.yMax) / tileHeight);
			for (var x:int = xTileMin; x < xTileMax; x += tileWidth)
			{
				// this loop starts at yTileMax because the tiles start from xMin,yMax
				for (var y:int = yTileMax; y > yTileMin; y -= tileHeight)
				{
					_tempBounds.setBounds(x, y - tileHeight, x + tileWidth, y);
					
					if (_tempBounds.isEmpty())
						continue; // don't make an empty tile request
					
					if (!_tilePatternBounds.overlaps(_tempBounds, false) || !_tempBounds.overlaps(dataBounds, false))
						continue;

					// fill requestURL parameters
					_requestURLParams[1] = "GetMap"; // should always be this for NASA
					_requestURLParams[3] = _shapeLayers;
					_requestURLParams[5] = _srs;
					_requestURLParams[7] = _imageFormat;
					if (_stylesToMonths.indexOf(_styles.value) < 0)
						_styles.value = _stylesToMonths[0];
					_requestURLParams[9] = _styles.value;
					_requestURLParams[11] = _imageWidth;
					_requestURLParams[13] = _imageHeight;
					_requestURLParams[15] = _tempBounds.getXNumericMin() +","+ _tempBounds.getYNumericMin() +","+ _tempBounds.getXNumericMax() +","+ _tempBounds.getYNumericMax();
					var fullRequestString:String = _requestURL.value;
					for (j = 0; j < _requestURLParams.length; ++j)
						fullRequestString += _requestURLParams[j];
					if (_urlToTile[fullRequestString] != undefined)
						continue;
					
					//trace(fullRequestString);
					var urlRequest:URLRequest = new URLRequest(fullRequestString);
					var newTile:WMSTile = new WMSTile(_tempBounds, _imageWidth, _imageHeight, urlRequest);
					_urlToTile[fullRequestString] = newTile; // save in dictionary
					
					_pendingTiles.push(newTile); // remember that we requested this image
					downloadImage(newTile); // download the image
				}
			}
			
			lowerQualTiles = lowerQualTiles.sort(tileSortingComparison);
			return lowerQualTiles.concat(completedTiles);
		}
		
		/**
		 * This is a private method used for sorting an array of WMSTiles.
		 */ 
		private function tileSortingComparison(a:WMSTile, b:WMSTile):int
		{
			// if a is higher quality (less data/screen => smaller value), it succeeds b
			if (a.zoomLevel < b.zoomLevel)
				return 1;
			else if (a.zoomLevel == b.zoomLevel)
				return 0;
			else
				return -1;			
		}

		override public function getAllowedBounds():IBounds2D
		{
			/* this WMS is still subject to change so we need to parse the XML. 
			 * but we need the allowed bounds early for the map tool. These bounds
			 * should never change for this service. The use of epsilon is necessary because
			 * proj4as wraps points at extremities.
			 */
			return new Bounds2D(-180 + ProjConstants.EPSLN, -90 + ProjConstants.EPSLN, 180 - ProjConstants.EPSLN, 90 - ProjConstants.EPSLN); 
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
		 * This function reports an error downloading an image. 
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
		
		override public function getProvider():*
		{
			return this;
		}
		
		override public function getCreditInfo():String
		{
			return '2011 (c) NASA Jet Propulsion Laboratory at California Institute of Technology';
		}
	}
}