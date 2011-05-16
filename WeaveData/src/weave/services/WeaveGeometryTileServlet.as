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

package weave.services
{
	import mx.rpc.AsyncToken;
	
	import weave.api.services.IWeaveGeometryTileService;
	
	/**
	 * This is an implementation of IWeaveGeometryTileService that uses an WeaveDataServlet as the tile source.
	 * 
	 * @author adufilie
	 */
	public class WeaveGeometryTileServlet implements IWeaveGeometryTileService
	{
		public function WeaveGeometryTileServlet(service:WeaveDataServlet, geometryCollectionName:String)
		{
			_service = service;
			_geometryCollectionName = geometryCollectionName;
		}
	
		private var _service:WeaveDataServlet;
		private var _geometryCollectionName:String;

		public function getTileDescriptors():AsyncToken
		{
			return _service.getTileDescriptors(_geometryCollectionName);
		}

		public function getMetadataTiles(tileIDs:Array):AsyncToken
		{
			return _service.getMetadataTiles(_geometryCollectionName, tileIDs);
		}

		public function getGeometryTiles(tileIDs:Array):AsyncToken
		{
			return _service.getGeometryTiles(_geometryCollectionName, tileIDs);
		}
	}
}
