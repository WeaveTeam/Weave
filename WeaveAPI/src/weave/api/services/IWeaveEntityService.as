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
	import weave.api.services.beans.EntitySearchCriteria;
	
	/**
	 * Interface for a service which provides RPC functions for retrieving Weave Entity information.
	 * @author adufilie
	 */
	public interface IWeaveEntityService extends ILinkableObject
	{
		/**
		 * This will be true when the service is initialized and ready to accept RPC requests.
		 */
		function get entityServiceInitialized():Boolean;

		/**
		 * Gets EntityHierarchyInfo objects containing basic information on entities matching public metadata.
		 * @param publicMetadata EntityMetadata containing values to match.
		 * @return RPC token for an Array of EntityHierarchyInfo objects.
		 */
		function getHierarchyInfo(publicMetadata:Object):AsyncToken;
		
		/**
		 * Gets an Array of Entity objects.
		 * @param ids A list of entity IDs.
		 * @return RPC token for an Array of Entity objects.
		 */
		function getEntities(ids:Array):AsyncToken;
		
		/**
		 * Gets an Array of entity IDs with matching metadata. 
		 * @param query Search criteria.
		 * @return RPC token for an Array of IDs.
		 */		
		function findEntityIds(query:EntitySearchCriteria):AsyncToken;
		
		/**
		 * Finds matching values for a public metadata field.
		 * @param feildName The name of the public metadata field to search.
		 * @param valueSearch A search string.
		 * @return RPC token for an Array of matching values for the specified public metadata field.
		 */
		function findPublicFieldValues(fieldName:String, valueSearch:String):AsyncToken;
	}
}
