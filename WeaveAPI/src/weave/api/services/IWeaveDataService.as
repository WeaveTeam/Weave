/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of the Weave API.
 *
 * The Initial Developer of the Weave API is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2012
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.api.services
{
	import mx.rpc.AsyncToken;
	
	/**
	 * This is an interface for making asynchronous calls to a WeaveDataService.
	 * 
	 * @author adufilie
	 */
	public interface IWeaveDataService
	{
		// This function should return an AsyncToken whose ResultEvent will contain a DataServiceMetadata object as the result.
		function getDataServiceMetadata():AsyncToken;
		// This function should return an AsyncToken whose ResultEvent will contain a DataTableMetadata object as the result.
		function getDataTableMetadata(dataTableName:String):AsyncToken;
		// This function should return an AsyncToken whose ResultEvent will contain a AttributeColumnDataWithKeys object as the result.
		function getAttributeColumn(pathInHierarchy:XML):AsyncToken;
		// This function should return an AsyncToken whose ResultEvent will contain a GeometryStreamMetadata object as the result.
		function getTileDescriptors(geometryCollectionName:String):AsyncToken;
		// This function should return an AsyncToken whose ResultEvent will contain a ByteArray as the result.
		function getMetadataTiles(geometryCollectionName:String, tileIDs:Array):AsyncToken;
		// This function should return an AsyncToken whose ResultEvent will contain a ByteArray as the result.
		function getGeometryTiles(geometryCollectionName:String, tileIDs:Array):AsyncToken;
		// This function returns an IGeometryTileService for a specified geometry collection.
		function createTileService(geometryCollectionName:String):IWeaveGeometryTileService;

		function createReport(name:String, keys:Array):AsyncToken;
		function getRows(keys:Array):AsyncToken;
	}
}
