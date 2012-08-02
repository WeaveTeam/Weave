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