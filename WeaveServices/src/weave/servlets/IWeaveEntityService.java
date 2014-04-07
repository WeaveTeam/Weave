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

package weave.servlets;

import java.rmi.RemoteException;
import java.util.Map;

import weave.config.DataConfig.DataEntityWithRelationships;
import weave.config.DataConfig.EntityHierarchyInfo;

/**
 * Interface for a service which provides RPC functions for retrieving Weave Entity information.
 * @author adufilie
 */
public interface IWeaveEntityService
{
	/**
	 * Gets EntityHierarchyInfo objects containing basic information on entities matching public metadata.
	 * @param publicMetadata EntityMetadata containing values to match.
	 * @return An Array of EntityHierarchyInfo objects, sorted by title.
	 */
	public EntityHierarchyInfo[] getHierarchyInfo(Map<String,String> publicMetadata) throws RemoteException;
	
	/**
	 * Gets an Array of Entity objects, minus the private metadata.
	 * @param ids A list of entity IDs.
	 * @return An Array of Entity objects.
	 */
	public DataEntityWithRelationships[] getEntities(int[] ids) throws RemoteException;
	
	/**
	 * Gets an Array of entity IDs with matching public metadata. 
	 * @param publicMetadata Public metadata to search for.
	 * @param wildcardFields A list of field names in publicMetadata that should be treated
	 *                       as search strings with wildcards '?' and '*' for single-character
	 *                       and multi-character matching, respectively.
	 * @return An Array of IDs matching the search criteria.
	 */
	public int[] findEntityIds(Map<String,String> publicMetadata, String[] wildcardFields) throws RemoteException;
	
	/**
	 * Finds matching values for a public metadata field.
	 * @param fieldName The name of the public metadata field to search.
	 * @param valueSearch A search string.
	 * @return An Array of matching values for the specified public metadata field.
	 */
	public String[] findPublicFieldValues(String fieldName, String valueSearch) throws RemoteException;
}
