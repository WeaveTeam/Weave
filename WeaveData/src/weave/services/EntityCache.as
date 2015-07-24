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

package weave.services
{
    import mx.rpc.AsyncToken;
    import mx.rpc.events.FaultEvent;
    import mx.rpc.events.ResultEvent;
    
    import weave.api.core.ICallbackCollection;
    import weave.api.core.IDisposableObject;
    import weave.api.core.ILinkableObject;
    import weave.api.data.ColumnMetadata;
    import weave.api.data.EntityType;
    import weave.api.getCallbackCollection;
    import weave.api.objectWasDisposed;
    import weave.api.registerLinkableChild;
    import weave.api.reportError;
    import weave.api.services.IWeaveEntityManagementService;
    import weave.api.services.IWeaveEntityService;
    import weave.api.services.beans.Entity;
    import weave.api.services.beans.EntityHierarchyInfo;
    import weave.api.services.beans.EntityMetadata;
    import weave.utils.EventUtils;
    import weave.utils.VectorUtils;

	/**
	 * Provides an interface to a set of cached Entity objects.
	 */
    public class EntityCache implements ILinkableObject, IDisposableObject
    {
		/**
		 * A special flag value to represent a root node, which doesn't actually exist.
		 */
		public static const ROOT_ID:int = -1;
		/**
		 * This is the maximum number of entities the server allows a user to request at a time.
		 */
		private static const MAX_ENTITY_REQUEST_COUNT:int = 1000;

		private var service:IWeaveEntityService = null;
		private var adminService:IWeaveEntityManagementService = null; // service as IWeaveEntityManagementService
		private var idsToFetch:Object = {}; // id -> Boolean
        private var entityCache:Object = {}; // id -> Array <Entity>
		private var idsToDelete:Object = {}; // id -> Boolean
		private var _idsByType:Object = {}; // entityType -> Array of id
		private var _infoLookup:Object = {}; // id -> EntityHierarchyInfo
		private var idsDirty:Object = {}; // id -> Boolean; used to remember which ids to invalidate the next time the entity is requested
		private var purgeMissingEntities:Boolean = false;
		
		private function get callbacks():ICallbackCollection { return getCallbackCollection(this); }
		
		/**
		 * Creates an EntityCache.
		 * @param service The entity service, which may or may not implement IWeaveEntityManagementService.
		 * @param purgeMissingEntities Set this to true when entities may be deleted or created and ids previously deleted may be reused.
		 */
        public function EntityCache(service:IWeaveEntityService, purgeMissingEntities:Boolean = false)
        {
			this.purgeMissingEntities = purgeMissingEntities;
			this.service = service;
			this.adminService = service as IWeaveEntityManagementService;
			registerLinkableChild(this, service);
			// Generate a delayed callback so other grouped callbacks would not cause it to trigger immediately.
			// This is important for grouping entity requests.
			callbacks.addImmediateCallback(this, EventUtils.generateDelayedCallback(this, delayedCallback, 0));
        }
		
		/**
		 * Gets the IWeaveEntityService that was passed to the constructor.
		 */
		public function getService():IWeaveEntityService
		{
			return service;
		}
		
		/**
		 * Checks if a specific parent-child relationship has been cached.
		 * @param parentId The ID of the parent entity.
		 * @param childId The ID of the child entity.
		 * @return true if the relationship has been cached.
		 */
		public function hasCachedRelationship(parentId:int, childId:int):Boolean
		{
			if (entityCache[parentId] && (!idsToFetch[parentId] || !entityCache[childId]))
				return (entityCache[parentId] as Entity).hasChild(childId);
			if (entityCache[childId])
				return (entityCache[childId] as Entity).hasParent(parentId);
			return false;
		}
		
		/**
		 * Invalidates a cached Entity object and optionally invalidates any related Entity objects.
		 * @param id The entity ID.
		 * @param alsoInvalidateRelatives Set this to true if any hierarchy relationships may have been altered.
		 */
		public function invalidate(id:int, alsoInvalidateRelatives:Boolean = false):void
		{
			if (objectWasDisposed(this))
				return;
			
			//trace('invalidate',id, alsoInvalidateRelatives, entityCache[id]);
			callbacks.delayCallbacks();
			
			WeaveAPI.SessionManager.assignBusyTask(delayedCallback, this);
			
			// trigger callbacks if we haven't previously decided to fetch this id
			if (!idsToFetch[id])
				callbacks.triggerCallbacks();
			
			idsDirty[id] = false;
			idsToFetch[id] = true;
			
			if (!entityCache[id])
				entityCache[id] = new Entity(_infoLookup[id]);

			if (alsoInvalidateRelatives)
			{
				var children:Array = (entityCache[id] as Entity).childIds;
				if (children && children.length)
				{
					for each (var childId:* in children)
						invalidate(childId);
				}
				var parents:Array = (entityCache[id] as Entity).parentIds;
				if (parents && parents.length)
				{
					for each (var parentId:* in parents)
						invalidate(parentId);
				}
				else
				{
					// invalidate root when child has no parents
					invalidate(ROOT_ID);
				}
			}
			
			callbacks.resumeCallbacks();
		}
		
		/**
		 * Retrieves an Entity object given its ID.
		 * @param id The entity ID.
		 * @return The Entity object.
		 */
		public function getEntity(id:int):Entity
		{
			// if there is no cached value, call invalidate() to create a placeholder.
			if (!entityCache[id] || idsDirty[id])
				invalidate(id);
			
            return entityCache[id] as Entity;
		}
		
		/**
		 * Checks if a particular Entity object is cached.
		 * @param The entity ID.
		 * @return true if the corresponding Entity object exists in the cache.
		 */
		public function entityIsCached(id:int):Boolean
		{
			var entity:Entity = entityCache[id] as Entity;
			return entity && entity.initialized;
		}
		
		private function delayedCallback():void
		{
			if (!service.entityServiceInitialized)
				return;
			
			var id:*;
			
			// delete marked entities
			var deleted:Boolean = false;
			var idsToRemove:Array = [];
			for (id in idsToDelete)
				idsToRemove.push(id);
			
			if (adminService && idsToRemove.length)
			{
				addAsyncResponder(adminService.removeEntities(idsToRemove), handleIdsToInvalidate, handleServiceFault, true);
				idsToDelete = {};
			}
			
			// request invalidated entities
			var ids:Array = [];
			for (id in idsToFetch)
			{
				// when requesting root, also request data table list
				if (id == ROOT_ID)
				{
					var tableMetadata:Object = {};
					tableMetadata[ColumnMetadata.ENTITY_TYPE] = EntityType.TABLE;
					addAsyncResponder(service.getHierarchyInfo(tableMetadata), handleEntityHierarchyInfo, handleServiceFault, tableMetadata);
					
					var hierarchyMetadata:Object = {};
					hierarchyMetadata[ColumnMetadata.ENTITY_TYPE] = EntityType.HIERARCHY;
					addAsyncResponder(service.getHierarchyInfo(hierarchyMetadata), handleEntityHierarchyInfo, handleServiceFault, hierarchyMetadata);
				}
				else
					ids.push(int(id));
			}
			
			delete idsToFetch[ROOT_ID];
			if (ids.length > 0)
				idsToFetch = {};
			
			while (ids.length > 0)
			{
				var splicedIds:Array = ids.splice(0, MAX_ENTITY_REQUEST_COUNT);
				addAsyncResponder(
					service.getEntities(splicedIds),
					getEntityHandler,
					handleServiceFault,
					splicedIds
				);
			}
			
			WeaveAPI.SessionManager.unassignBusyTask(delayedCallback);
        }
		
		private function handleIdsToInvalidate(event:ResultEvent, alsoInvalidateRelatives:Boolean):void
		{
			callbacks.delayCallbacks();
			
			for each (var id:int in event.result as Array)
				invalidate(id, alsoInvalidateRelatives);
			
			callbacks.resumeCallbacks();
		}
		
        private function getEntityHandler(event:ResultEvent, requestedIds:Array):void
        {
			var id:int;
			var entity:Entity;
			var info:EntityHierarchyInfo;
			
			// reset all requested entities in case they do not appear in the results
			for each (id in requestedIds)
			{
				// make sure cached object is empty
				entity = entityCache[id] || new Entity();
				entity.reset();
				entityCache[id] = entity;
				idsDirty[id] = true;
			}
			
			for each (entity in event.result)
			{
				if (!entity.parentIds)
					entity.parentIds = [];
				if (!entity.childIds)
					entity.childIds = [];
				id = entity.id;
				entityCache[id] = entity;
				idsDirty[id] = false;
				info = _infoLookup[id];
				if (info)
				{
					info.entityType = entity.publicMetadata[ColumnMetadata.ENTITY_TYPE];
					info.title = entity.publicMetadata[ColumnMetadata.TITLE];
					info.numChildren = entity.childIds.length;
				}
			}
			
			// for each id not appearing in result, delete _infoLookup[id]
			for each (id in requestedIds)
			{
				if (idsDirty[id])
				{
					if (purgeMissingEntities)
					{
						delete _infoLookup[id];
					}
					else
					{
						// display an error and stop requesting the missing entity
						info = _infoLookup[id] || new EntityHierarchyInfo();
						info.id = id;
						info.numChildren = 0;
						info.title = lang("[Error: Entity #{0} does not exist]", id);
						_infoLookup[id] = info;
						idsDirty[id] = false;
					}
				}
			}
			
			callbacks.triggerCallbacks();
        }
		
		/**
		 * Calls getHierarchyInfo() in the IWeaveEntityService that was passed to the constructor and caches
		 * the results when they come back.
		 * @param publicMetadata Public metadata search criteria.
		 * @return RPC token for an Array of EntityHierarchyInfo objects.
		 * @see weave.api.services.IWeaveEntityService#getHierarchyInfo()
		 */		
		public function getHierarchyInfo(publicMetadata:Object):AsyncToken
		{
			var token:AsyncToken = service.getHierarchyInfo(publicMetadata);
			addAsyncResponder(token, handleEntityHierarchyInfo, handleServiceFault, publicMetadata);
			return token;
		}
		
		private function handleEntityHierarchyInfo(event:ResultEvent, publicMetadata:Object):void
		{
			var entityType:String = publicMetadata[ColumnMetadata.ENTITY_TYPE];
			var infoArray:Array = event.result as Array || [];
			var ids:Array = new Array(infoArray.length);
			for (var i:int = 0; i < infoArray.length; i++)
			{
				var info:EntityHierarchyInfo = EntityHierarchyInfo(infoArray[i]);
				info.entityType = entityType; // entityType is not provided by the server
				_infoLookup[info.id] = info;
				ids[i] = info.id;
			}
			// if there is only one metadata property and it's entityType, save the list of ids
			var keys:Array = VectorUtils.getKeys(publicMetadata);
			if (keys.length == 1 && keys[0] == ColumnMetadata.ENTITY_TYPE)
				_idsByType[entityType] = ids;
			
			callbacks.triggerCallbacks();
		}
		
		/**
		 * Gets an Array of Entity objects which have previously been cached via getHierarchyInfo().
		 * Entities of type 'table' and 'hierarchy' get cached automatically.
		 * @param entityType Either 'table' or 'hierarchy'
		 * @return An Array of Entity objects with the given type
		 */		
		public function getIdsByType(entityType:String):Array
		{
			getEntity(ROOT_ID);
			return _idsByType[entityType] = (_idsByType[entityType] || []);
		}
		
		/**
		 * Gets an EntityHierarchyInfo object corresponding to an entity ID, to be used for displaying a hierarchy.
		 * @param The entity ID.
		 * @return The hierarchy info, or null if there is none.
		 */
		public function getBranchInfo(id:int):EntityHierarchyInfo
		{
			getEntity(ROOT_ID);
			var info:EntityHierarchyInfo = _infoLookup[id];
			
//			if (!info && entityIsCached(id))
//			{
//				var entity:Entity = entityCache[id];
//				info = new EntityHierarchyInfo(null);
//				info.id = id;
//				info.entityType = entity.publicMetadata[ColumnMetadata.ENTITY_TYPE];
//				info.title = entity.publicMetadata[ColumnMetadata.TITLE];
//				info.numChildren = entity.childIds.length;
//				_infoLookup[id] = info;
//			}
			
			return info;
		}
        
		/**
		 * Invalidates all cached information.
		 * @param purge If set to true, clears cache instead of just invalidating it.
		 */
		public function invalidateAll(purge:Boolean = false):void
        {
			if (objectWasDisposed(this))
				return;
			if (purge)
			{
				idsToFetch = {};
				entityCache = {};
				idsToDelete = {};
				_idsByType = {};
				_infoLookup = {};
				idsDirty = {};
			}
			else
			{
				// we don't want to delete the cache because we can still use the cached values for display in the meantime.
				for (var id:* in entityCache)
					idsDirty[id] = true;
			}
			callbacks.triggerCallbacks();
        }
		
		public function update_metadata(id:int, diff:EntityMetadata):void
        {
			if (!adminService)
			{
				reportError("Unable to update metadata (Not an admin service)");
				return;
			}
			adminService.updateEntity(id, diff);
			invalidate(id);
        }
        public function add_category(title:String, parentId:int, index:int):void
        {
			if (!adminService)
			{
				reportError("Unable to create entities (Not an admin service)");
				return;
			}
			var entityType:String = parentId == ROOT_ID ? EntityType.HIERARCHY : EntityType.CATEGORY;
            var em:EntityMetadata = new EntityMetadata();
			em.publicMetadata[ColumnMetadata.TITLE] = title;
			em.publicMetadata[ColumnMetadata.ENTITY_TYPE] = entityType;
			adminService.newEntity(em, parentId, index);
			invalidate(parentId);
        }
        public function delete_entity(id:int):void
        {
			idsToDelete[id] = true;
			invalidate(id, true);
        }
        public function add_child(parent_id:int, child_id:int, index:int):void
        {
			if (!adminService)
			{
				reportError("Unable to modify hierarchy (Not an admin service)");
				return;
			}
			
			if (idsToDelete[child_id]) // move from root
			{
				// prevent move-from-root from deleting the child
				delete idsToDelete[child_id];
				if (parent_id == ROOT_ID)
					return; // nothing to do
				
				// change hierarchy to category
				var diff:EntityMetadata = new EntityMetadata();
				diff.publicMetadata[ColumnMetadata.ENTITY_TYPE] = EntityType.CATEGORY;
				adminService.updateEntity(child_id, diff);
			}
				
			addAsyncResponder(adminService.addChild(parent_id, child_id, index), handleIdsToInvalidate, handleServiceFault, false);
			invalidate(parent_id);
        }
        public function remove_child(parent_id:int, child_id:int):void
        {
			if (!adminService)
			{
				reportError("Unable to remove entities (Not an admin service)");
				return;
			}
			
			// remove from root means delete
			if (parent_id == ROOT_ID)
			{
				// delete_entity() does not take effect immediately.
				// this allows add_child() to move it to a new parent instead of deleting.
				delete_entity(child_id);
			}
			else
			{
				adminService.removeChild(parent_id, child_id);
			}
			invalidate(child_id, true);
        }
		
		/**
		 * Finds a series of Entity objects which can be traversed as a path from a root Entity to a descendant Entity.
		 * @param root The root Entity.
		 * @param descendant The descendant Entity.
		 * @return An Array of Entity objects which can be followed as a path from the root to the descendant, including the root and the descendant.
		 *         Returns null if the descendant is unreachable from the root.
		 */
		public function getEntityPath(root:Entity, descendant:Entity):Array
		{
			if (!root.id == ROOT_ID)
			{
				//TODO - when searching for a column under root(-1), a table should always be returned instead of a hierarchy
				var type:String = descendant.getEntityType();
				if (type == EntityType.TABLE || type == EntityType.HIERARCHY)
					return [root, descendant];
			}
			
			if (root.id == descendant.id)
				return [root];
			
			for each (var parentId:int in descendant.parentIds)
			{
				var parent:Entity = getEntity(parentId);
				if (!parent.initialized)
					continue;
				var path:Array = getEntityPath(root, parent)
				if (path)
				{
					path.push(descendant);
					return path;
				}
			}
			return null;
		}
		
		private function handleServiceFault(event:FaultEvent, token:Object = null):void
		{
			reportError(event);
		}
		
		public function dispose():void
		{
			WeaveAPI.SessionManager.unassignBusyTask(delayedCallback);
		}
    }
}
