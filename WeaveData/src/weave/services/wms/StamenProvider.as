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
	import com.modestmaps.core.Coordinate;
	import com.modestmaps.mapproviders.AbstractMapProvider;
	import com.modestmaps.mapproviders.IMapProvider;

	/**
	 * This class is simply another provider to be used with ModestMaps library.
	 * Tile URLs are identical to those used by OpenStreetMap, except for the beginning
	 * of the URL.
	 * 
	 * @author adufilie
	 */
	public class StamenProvider extends AbstractMapProvider implements IMapProvider
	{
		public function StamenProvider(style:String, minZoom:int = MIN_ZOOM, maxZoom:int = MAX_ZOOM)
		{
			super(minZoom, maxZoom);
			this.style = style;
		}
		
		public function toString():String
		{
			return "stamen " + style;
		}
		
		public static const STYLE_TONER:String = 'toner';
		public static const STYLE_TERRAIN:String = 'terrain';
		public static const STYLE_WATERCOLOR:String = 'watercolor';
		
		public var style:String;
		public function getTileUrls(coord:Coordinate):Array
		{
			var sourceCoord:Coordinate = sourceCoordinate(coord);
			
			return [ 'http://tile.stamen.com/' + style + '/' + sourceCoord.zoom + '/' + sourceCoord.column + '/' + sourceCoord.row + '.png' ];
		}
	}
}