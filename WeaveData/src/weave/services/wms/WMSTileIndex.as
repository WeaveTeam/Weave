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
	import weave.api.core.IDisposableObject;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerDisposableChild;
	import weave.primitives.KDTree;

	/**
	 * This class provides an interface to a collection of WMSTiles. The tiles
	 * are inserted into the 5-dimensional KDTree with keys of the form
	 * [xMin, yMin, xMax, yMax, zoomLevel]. 
	 * 
	 * 
	 * @author kmonico
	 */
	public class WMSTileIndex implements IDisposableObject
	{
		public function WMSTileIndex()
		{
		}
		
		public function dispose():void
		{
			// _kdTree will be automatically disposed
		}

		/**
		 * Insert a fully downloaded tile into the KDTree.
		 * 
		 * @param tile The WMSTile to insert into the tree.
		 */
		public function addTile(tile:WMSTile):void
		{
			var bounds:IBounds2D = tile.bounds;
			_kdTree.insert([bounds.getXMin(), bounds.getYMin(), bounds.getXMax(), bounds.getYMax(), tile.zoomLevel], tile);
		}
		

		/**
		 * This is a mapping of URLLoaders to WMSTiles. The function cancelPendingRequests
		 * iterates over these keys to close the URLLoaders. The image download handlers
		 * removes the entries from this dictionary.
		 */
		//private const _loaderToTileMap:Dictionary = new Dictionary();
		
		/**
		 * These KDKey arrays are created once and reused to avoid unnecessary creation of objects.
		 * The only values that change are the ones that are undefined here.
		 */
		private var _minKDKey:Array = [Number.NEGATIVE_INFINITY, Number.NEGATIVE_INFINITY, NaN, NaN, 0];
		private var _maxKDKey:Array = [NaN, NaN, Number.POSITIVE_INFINITY, Number.POSITIVE_INFINITY, Number.POSITIVE_INFINITY];
		
		// KDTree key indices
		private static const XMIN_INDEX:int = 0;
		private static const YMIN_INDEX:int = 1;
		private static const XMAX_INDEX:int = 2;
		private static const YMAX_INDEX:int = 3;
		private static const ZOOM_INDEX:int = 4;
		
		/**
		 * For NASA WMS, zoomLevel is preferably defined as the area of the best matching bbox divided by the area of the image.
		 * For the ModestMaps services, zoomLevel should be the constant zoom level provided in a Coordinate object.
		 * @param dataBounds The bounds of the data.
		 * @param minZoomLevel The min zoom level of the data.
 		 * @param maxZoomLevel The max zoom level of the data. 
		 * @return An array of keys with bounds that contain the given bounds.
		 */
		public function getTiles(dataBounds:IBounds2D, minZoomLevel:Number, maxZoomLevel:Number):Array
		{
			_minKDKey[XMAX_INDEX] = dataBounds.getXNumericMin();
			_minKDKey[YMAX_INDEX] = dataBounds.getYNumericMin();
			_maxKDKey[XMIN_INDEX] = dataBounds.getXNumericMax();
			_maxKDKey[YMIN_INDEX] = dataBounds.getYNumericMax();

			_minKDKey[ZOOM_INDEX] = minZoomLevel;
			_maxKDKey[ZOOM_INDEX] = maxZoomLevel;
			
			var tiles:Array = _kdTree.queryRange(_minKDKey, _maxKDKey, true);
			
			return tiles;
		}

		/**
		 * kdTree
		 * This is the 5-dimensional tree which holds all the tiles.
		 */
		private const _kdTree:KDTree = registerDisposableChild(this, new KDTree(5)); // each node is of the form [xmin, ymin, xmax, ymax, zoomlevel]
	}
}