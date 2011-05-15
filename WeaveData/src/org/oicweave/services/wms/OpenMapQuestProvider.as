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

package org.oicweave.services.wms
{
	import com.modestmaps.core.Coordinate;
	import com.modestmaps.mapproviders.AbstractMapProvider;
	import com.modestmaps.mapproviders.IMapProvider;
	import com.modestmaps.mapproviders.OpenStreetMapProvider;
	
	import org.oicweave.api.services.IWMSService;

	/**
	 * This class is simply another provider to be used with ModestMaps library.
	 * MapQuest tile URLs are identical to those used by OpenStreetMap, except for the beginning
	 * of the URL.
	 * 
	 * @author kmonico
	 */
	public class OpenMapQuestProvider extends AbstractMapProvider implements IMapProvider
	{
		public function OpenMapQuestProvider(minZoom:int = MIN_ZOOM, maxZoom:int = MAX_ZOOM)
		{
			super(minZoom, maxZoom);
		}
		
		public function toString():String
		{
			return "OPEN_MAP_QUEST";
		}

		private var serverNumber:int = Math.min(Math.floor(1 + Math.random() * 4), 4);
		public function getTileUrls(coord:Coordinate):Array
		{
			var sourceCoord:Coordinate = sourceCoordinate(coord);
			
			return [ 'http://otile' + serverNumber + '.mqcdn.com/tiles/1.0.0/osm/' + sourceCoord.zoom + '/' + sourceCoord.column + '/' + sourceCoord.row + '.png' ];
		}
	}
}