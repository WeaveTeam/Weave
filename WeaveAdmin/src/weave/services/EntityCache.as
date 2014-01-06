package weave.services
{
    import flash.utils.Dictionary;
    
    import mx.rpc.events.ResultEvent;
    
    import weave.api.core.ICallbackCollection;
    import weave.api.core.ILinkableObject;
    import weave.api.data.ColumnMetadata;
    import weave.api.getCallbackCollection;
    import weave.api.registerLinkableChild;
    import weave.services.beans.Entity;
    import weave.services.beans.EntityHierarchyInfo;
    import weave.services.beans.EntityMetadata;
    import weave.services.beans.EntityType;
    import weave.utils.Dictionary2D;

    public class EntityCache implements ILinkableObject
    {
		public static const ROOT_ID:int = -1;
		
		private var idsToFetch:Object = {}; // id -> Boolean
        private var entityCache:Object = {}; // id -> Array <Entity>
		private var idsToDelete:Object = {}; // id -> Boolean
		private var _idsByType:Object = {}; // entityType -> Array of id
		private var _infoLookup:Object = {}; // id -> EntityHierarchyInfo
		private var idsDirty:Object = {}; // id -> Boolean; used to remember which ids to invalidate the next time the entity is requested
		
        public function EntityCache()
        {
			callbacks.addGroupedCallback(this, groupedCallback);
			registerLinkableChild(this, Admin.service);
			Admin.service.addHook(Admin.service.authenticate, null, groupedCallback);
        }
		
		public function hasCachedRelationship(parentId:int, childId:int):Boolean
		{
			if (entityCache[parentId] && (!idsToFetch[parentId] || !entityCache[childId]))
				return (entityCache[parentId] as Entity).hasChild(childId);
			if (entityCache[childId])
				return (entityCache[childId] as Entity).hasParent(parentId);
			return false;
		}
		
		public function invalidate(id:int, alsoInvalidateParents:Boolean = false):void
		{
			callbacks.delayCallbacks();
			
			// trigger callbacks if we haven't previously decided to fetch this id
			if (!idsToFetch[id])
				callbacks.triggerCallbacks();
			
			idsDirty[id] = false;
			idsToFetch[id] = true;
			
			if (!entityCache[id])
			{
				var entity:Entity = new Entity();
				entityCache[id] = entity;
			}
			
			if (alsoInvalidateParents)
			{
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
		
		private function get callbacks():ICallbackCollection { return getCallbackCollection(this); }
		
		public function getEntity(id:int):Entity
		{
			// if there is no cached value, call invalidate() to create a placeholder.
			if (!entityCache[id] || idsDirty[id])
				invalidate(id);
			
            return entityCache[id] as Entity;
		}
		
		public function entityIsCached(id:int):Boolean
		{
			return entityCache[id] is Entity;
		}
		
		private function groupedCallback(..._):void
		{
			if (!Admin.instance.userHasAuthenticated)
				return;
			
			var id:*;
			
			// delete marked entities
			var deleted:Boolean = false;
			var idsToRemove:Array = [];
			for (id in idsToDelete)
				idsToRemove.push(id);
			
			if (idsToRemove.length)
			{
				addAsyncResponder(Admin.service.removeEntities(idsToRemove), handleRemoveEntities);
				idsToDelete = {};
			}
			
			// request invalidated entities
			var ids:Array = [];
			for (id in idsToFetch)
			{
				// when requesting root, also request data table list
				if (id == ROOT_ID)
				{
					delete idsToFetch[id];
					addAsyncResponder(Admin.service.getEntityHierarchyInfo(EntityType.TABLE), handleEntityHierarchyInfo, null, EntityType.TABLE);
					addAsyncResponder(Admin.service.getEntityHierarchyInfo(EntityType.HIERARCHY), handleEntityHierarchyInfo, null, EntityType.HIERARCHY);
				}
				else
					ids.push(int(id));
			}
			if (ids.length > 0)
			{
				idsToFetch = {};
				addAsyncResponder(Admin.service.getEntitiesById(ids), getEntityHandler, null, ids);
			}
        }
		
		private function handleRemoveEntities(event:ResultEvent, token:Object):void
		{
			callbacks.delayCallbacks();
			
			for each (var id:int in event.result as Array)
				invalidate(id, true);
			
			callbacks.resumeCallbacks();
		}
		
        private function getEntityHandler(event:ResultEvent, requestedIds:Array):void
        {
			var id:int;
			var entity:Entity;
			
			// unmark all requested ids in case they do not appear in the results
			for each (id in requestedIds)
			{
				// this entity doesn't exist, so make sure its cached object is empty
				entity = entityCache[id] || new Entity();
				if (entity.id != ROOT_ID)
					entity = new Entity();
				entityCache[id] = entity;
				idsDirty[id] = false;
			}
				
			for each (var result:Object in event.result)
			{
				id = Entity.getEntityIdFromResult(result);
				entity = entityCache[id] || new Entity();
				entity.copyFromResult(result);
	            entityCache[id] = entity;
				
				var info:EntityHierarchyInfo = _infoLookup[id];
				if (info)
				{
					info.type = entity.type;
					info.title = entity.publicMetadata[ColumnMetadata.TITLE];
					info.numChildren = entity.childIds.length;
				}
			}
			
			callbacks.triggerCallbacks();
        }
		
		private function handleEntityHierarchyInfo(event:ResultEvent, entityType:int):void
		{
			var items:Array = event.result as Array;
			for (var i:int = 0; i < items.length; i++)
			{
				var item:EntityHierarchyInfo = new EntityHierarchyInfo(items[i], entityType);
				_infoLookup[item.id] = item;
				items[i] = item.id; // overwrite item with its id
			}
			_idsByType[entityType] = items; // now an array of ids
			
			callbacks.triggerCallbacks();
		}
		
		public function getIdsByType(entityType:int):Array
		{
			getEntity(ROOT_ID);
			return _idsByType[entityType] = (_idsByType[entityType] || []);
		}
		
		public function getBranchInfo(id:int):EntityHierarchyInfo
		{
			getEntity(ROOT_ID);
			return _infoLookup[id];
		}
        
		public function invalidateAll(purge:Boolean = false):void
        {
			callbacks.delayCallbacks();
			
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
			
			callbacks.resumeCallbacks();
        }
		
		public function update_metadata(id:int, diff:EntityMetadata):void
        {
			Admin.service.updateEntity(id, diff);
			invalidate(id);
        }
        public function add_category(title:String, parentId:int, index:int):void
        {
			var type:int = parentId == ROOT_ID ? EntityType.HIERARCHY : EntityType.CATEGORY;
            var em:EntityMetadata = new EntityMetadata();
			em.publicMetadata[ColumnMetadata.TITLE] = title;
			Admin.service.newEntity(type, em, parentId, index);
			invalidate(parentId);
        }
        public function delete_entity(id:int):void
        {
            /* Entity deletion should usually impact root, so we'll invalidate root's cache entry and refetch. */
			idsToDelete[id] = true;
			invalidate(id, true);
        }
        public function add_child(parent_id:int, child_id:int, index:int):void
        {
			if (parent_id == ROOT_ID && idsToDelete[child_id])
			{
				// prevent hierarchy-dragged-to-root from removing the hierarchy
				delete idsToDelete[child_id];
				return;
			}
			Admin.service.addParentChildRelationship(parent_id, child_id, index);
			invalidate(parent_id);
        }
        public function remove_child(parent_id:int, child_id:int):void
        {
			// remove from root not supported, but invalidate root anyway in case the child is added via add_child later
			if (parent_id == ROOT_ID)
			{
				idsToDelete[child_id] = true;
				invalidate(ROOT_ID);
			}
			else
			{
				Admin.service.removeParentChildRelationship(parent_id, child_id);
			}
			invalidate(child_id, true);
        }
    }
}
