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

package weave.services.wms
{
	import flash.utils.Dictionary;
	
	import weave.api.core.IDisposableObject;
	import weave.api.getCallbackCollection;
	import weave.api.objectWasDisposed;
	import weave.api.primitives.IBounds2D;
	import weave.api.reportError;
	import weave.api.services.IWMSService;
	import weave.compiler.StandardLib;
	import weave.primitives.Bounds2D;

	/**
	 * This is an abstract class containing all the implementation details relevant
	 * to each Service object for WMS.
	 * 
	 * @author kmonico
	 */
	public class AbstractWMS implements IWMSService, IDisposableObject
	{
		public function AbstractWMS() 
		{
		}

		/**
		 * This is the tiling index which contains the KDTree of the tiles
		 * and associated images.
		 */
		protected var _currentTileIndex:WMSTileIndex;
		
		// parameters common to all tiling services
		protected var _tiledName:String; // displayed on maptool settings
		protected var _srs:String = null; // mercator for ModestMaps, lat/lon for nasa
		
		// dictionary mapping request strings to WMSTile objects
		protected var _urlToTile:Dictionary = new Dictionary(true);
				
		/**
		 * The bounds allowed for requests.
		 */
		protected const _allowedRequestedBounds:IBounds2D = new Bounds2D(-180, -90, 180, 90);

		/**
		 * This is an array of tiles whose images are downloading.
		 */
		protected var _pendingTiles:Array = [];
		
		/**
		 * This function will cancel all pending requests.
		 * @see weave.api.core.IWMSService#cancelPendingRequests
		 */
		public function cancelPendingRequests():void
		{
			for each (var tile:WMSTile in _pendingTiles)
			{
				tile.cancelDownload();
				delete _urlToTile[tile.request.url];
			}			
			_pendingTiles.length = 0;
		}
		
		/**
		 * This function will determine if a tile with identical bounds as key was already
		 * downloaded.
 		 * @param key The bounds object to check.
		 * @param array An array of WMSTile objects.
		 * @return True if there is a tile with bounds identical to key.
		 */
		protected function tileContainingBoundsDownloaded(key:IBounds2D, array:Array):Boolean
		{
			for each (var obj:Object in array)
			{
				var tempTile:WMSTile = obj as WMSTile;
				
				// if bounds are the same, they're the same tile
				if (tempTile.bounds.equals(key))
					return true;
			}
			return false;
		}
		
		/**
		 * This function will remove an image from _pendingImages and trigger callbacks.
		 */
		protected function handleTileDownload(tile:WMSTile):void
		{
			if (objectWasDisposed(this))
				return;
			
			_currentTileIndex.addTile(tile);
			
			// remove from pending list if necessary
			var index:int = _pendingTiles.indexOf(tile);
			if (index >= 0)
				_pendingTiles.splice(index, 1);
			
			getCallbackCollection(this).triggerCallbacks();
		}
		
		/**
		 * Return the number of pending requests.
		 * @see weave.api.core.IWMSService#getNumPendingRequests
		 */
		public function getNumPendingRequests():int
		{
			return _pendingTiles.length;
		}
		
		/**
		 * Return the srs code.
		 * @see weave.api.core.IWMSService#getProjectionSRS
		 */
		public function getProjectionSRS():String
		{
			return _srs;
		}
		
		/**
		 * Request the images.
		 * @see weave.api.core.IWMSService#requestImages
		 */		 
		/* abstract */ public function requestImages(dataBounds:IBounds2D, screenBounds:IBounds2D, preferLowerQuality:Boolean = false, layerLowerQuality:Boolean = false):Array
		{
			return null;
		}
		
		/**
		 * Return the allowed bounds.
		 * @see weave.api.core.IWMSService#getAllowedBounds
		 */ 
		public function getAllowedBounds(output:IBounds2D):void
		{
			output.reset();
		}
		
		/**
		 * This will cancel pending requests when this object is disposed.
		 */		
		public function dispose():void
		{
			cancelPendingRequests();
		}
		
		/* abstract */ public function getCreditInfo():String
		{
			reportError("Attempt to get copyright information of AbstractWMS.");
			return null;
		}
		
		// image dimensions
		protected var _imageWidth:int;
		protected var _imageHeight:int;
		
		/**
		 * @inheritDoc
		 */
		public function getImageWidth():int
		{
			return _imageWidth;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getImageHeight():int
		{
			return _imageHeight;
		}
		
		protected function sortTiles(tiles:Array):void
		{
			StandardLib.sortOn(tiles, WMSTile.ZOOM_LEVEL);
		}
	}
}