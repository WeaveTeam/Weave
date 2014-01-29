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

import weave.config.DataConfig.DataEntityMetadata;
import weave.config.DataConfig.DataEntityWithRelationships;
import weave.config.DataConfig.EntityHierarchyInfo;
	
/**
 * Interface for a service which provides RPC functions for retrieving and manipulating Weave Entity information.
 * @author adufilie
 */
public interface IWeaveEntityManagementService
{
	/**
	 * Gets EntityHierarchyInfo objects containing basic information on hierarchy roots.
	 * @param entityType Either 'table' or 'hierarchy'.
	 * @return An Array of EntityHierarchyInfo objects.
	 */
	public EntityHierarchyInfo[] getHierarchyInfo(String user, String pass, String entityType) throws RemoteException;
	/**
	 * Gets an Array of Entity objects.
	 * @param ids A list of entity IDs.
	 * @return An Array of Entity objects.
	 */
	public DataEntityWithRelationships[] getEntities(String user, String pass, int[] ids) throws RemoteException;
	/**
	 * Gets an Array of entity IDs with matching metadata. 
	 * @param metadata EntityMetadata containing values to match.
	 * @return An Array of IDs.
	 */		
	public int[] findEntityIds(String user, String pass, DataEntityMetadata metadata) throws RemoteException;
	/**
	 * Finds matching values for a public metadata field.
	 * @param feildName The name of the public metadata field to search.
	 * @param valueSearch A search string.
	 * @return An Array of matching values for the specified public metadata field.
	 */
	public String[] findPublicFieldValues(String user, String pass, String fieldName, String valueSearch) throws RemoteException;
	
	/**
	 * Creates a new entity.
	 * @param metadata Metadata for the new entity.
	 * @param parentId The parent entity ID, or -1 for no parent.
	 * @param insertAtIndex Specifies insertion index for sort order.
	 * @return RPC token for an entity ID.
	 */
	public int newEntity(String user, String pass, DataEntityMetadata metadata, int parentId, int index) throws RemoteException;
	/**
	 * Removes entities and their children recursively.
	 * @param entityIds A list of entity IDs to remove.
	 * @return RPC token for an Array of entity IDs that were removed.
	 */
	public int[] removeEntities(String user, String pass, int[] entityIds) throws RemoteException;
	/**
	 * Updates the metadata for an existing entity.
	 * @param entityId An entity ID.
	 * @param diff Specifies the changes to make to the metadata.
	 * @return RPC token.
	 */
	public void updateEntity(String user, String pass, int entityId, DataEntityMetadata diff) throws RemoteException;
	/**
	 * Adds a parent-child relationship to the server-side entity hierarchy table.
	 * @param parentId The ID of the parent entity.
	 * @param childId The ID of the child entity.
	 * @param insertAtIndex Specifies insertion index for sort order.
	 * @return RPC token.
	 */
	public void addParentChildRelationship(String user, String pass, int parentId, int childId, int index) throws RemoteException;
	/**
	 * Removes a parent-child relationship from the server-side entity hierarchy table.
	 * @param parentId The ID of the parent entity.
	 * @param childId The ID of the child entity.
	 * @return RPC token.
	 */
	public void removeParentChildRelationship(String user, String pass, int parentId, int childId) throws RemoteException;
}
