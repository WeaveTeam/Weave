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
	
	import weave.api.core.ILinkableObject;
	
	/**
	 * This is an interface for requesting tiles for a streamed geometry collection.
	 * 
	 * @author adufilie
	 */
	public interface IWeaveGeometryTileService extends ILinkableObject
	{
		// This function should return an AsyncToken whose ResultEvent will contain a ByteArray as the result.
		function getMetadataTiles(tileIDs:Array):AsyncToken;
		
		// This function should return an AsyncToken whose ResultEvent will contain a ByteArray as the result.
		function getGeometryTiles(tileIDs:Array):AsyncToken;
	}
}
