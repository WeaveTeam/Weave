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
		
		private var cache_dirty:Object = {}; // id -> Boolean
        private var cache_entity:Object = {}; // id -> Array <Entity>
		private var delete_later:Object = {}; // id -> Boolean
		private var _idsByType:Object = {}; // entityType -> Array of id
		private var _infoLookup:Object = {}; // id -> EntityHierarchyInfo
		private var pending_invalidate:Object = {}; // id -> Boolean; used to remember which ids to invalidate the next time the entity is requested
		
        public function EntityCache()
        {
			callbacks.addGroupedCallback(this, fetchDirtyEntities);
			registerLinkableChild(this, Admin.service);
			Admin.service.addHook(Admin.service.authenticate, null, fetchDirtyEntities);
        }
		
		public function hasCachedRelationship(parentId:int, childId:int):Boolean
		{
			if (cache_entity[parentId] && (!cache_dirty[parentId] || !cache_entity[childId]))
				return (cache_entity[parentId] as Entity).hasChild(childId);
			if (cache_entity[childId])
				return (cache_entity[childId] as Entity).hasParent(parentId);
			return false;
		}
		
		public function invalidate(id:int, alsoInvalidateParents:Boolean = false):void
		{
			callbacks.delayCallbacks();
			
			if (!cache_dirty[id])
				callbacks.triggerCallbacks();
			
			pending_invalidate[id] = false;
			cache_dirty[id] = true;
			
			if (!cache_entity[id])
			{
				var entity:Entity = new Entity();
				cache_entity[id] = entity;
			}
			
			if (alsoInvalidateParents)
			{
				var parents:Array = (cache_entity[id] as Entity).parentIds;
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
			if (!cache_entity[id] || pending_invalidate[id])
				invalidate(id);
			
            return cache_entity[id];
		}
		
		private function fetchDirtyEntities(..._):void
		{
			if (!Admin.instance.userHasAuthenticated)
				return;
			
			var id:*;
			
			// delete marked entities
			var deleted:Boolean = false;
			var idsToRemove:Array = [];
			for (id in delete_later)
				idsToRemove.push(id);
			
			if (idsToRemove.length)
			{
				addAsyncResponder(Admin.service.removeEntities(idsToRemove), handleRemoveEntities);
				delete_later = {};
			}
			
			// request invalidated entities
			var ids:Array = [];
			for (id in cache_dirty)
			{
				// when requesting root, also request data table list
				if (id == ROOT_ID)
				{
					delete cache_dirty[id];
					addAsyncResponder(Admin.service.getEntityHierarchyInfo(EntityType.TABLE), handleEntityHierarchyInfo, null, EntityType.TABLE);
					addAsyncResponder(Admin.service.getEntityHierarchyInfo(EntityType.HIERARCHY), handleEntityHierarchyInfo, null, EntityType.HIERARCHY);
				}
				else
					ids.push(int(id));
			}
			if (ids.length > 0)
			{
				cache_dirty = {};
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
				entity = cache_entity[id] || new Entity();
				if (entity.id != ROOT_ID)
					entity = new Entity();
				cache_entity[id] = entity;
				pending_invalidate[id] = false;
			}
				
			for each (var result:Object in event.result)
			{
				id = Entity.getEntityIdFromResult(result);
				entity = cache_entity[id] || new Entity();
				entity.copyFromResult(result);
	            cache_entity[id] = entity;
				
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
				cache_dirty = {};
				cache_entity = {};
				delete_later = {};
				_idsByType = {};
				_infoLookup = {};
				pending_invalidate = {};
			}
			else
			{
				// we don't want to delete the cache because we can still use the cached values for display in the meantime.
				for (var id:* in cache_entity)
					pending_invalidate[id] = true;
			}
			callbacks.triggerCallbacks();
			
			callbacks.resumeCallbacks();
        }
		
		public function update_metadata(id:int, diff:EntityMetadata):void
        {
			Admin.service.updateEntity(id, diff);
			invalidate(id);
        }
        public function add_category(label:String, parentId:int, index:int):void
        {
			var type:int = parentId == ROOT_ID ? EntityType.HIERARCHY : EntityType.CATEGORY;
            var em:EntityMetadata = new EntityMetadata();
			em.publicMetadata[ColumnMetadata.TITLE] = label;
			Admin.service.newEntity(type, em, parentId, index);
			invalidate(parentId);
        }
        public function delete_entity(id:int):void
        {
            /* Entity deletion should usually impact root, so we'll invalidate root's cache entry and refetch. */
			delete_later[id] = true;
			invalidate(id, true);
        }
        public function add_child(parent_id:int, child_id:int, index:int):void
        {
			if (parent_id == ROOT_ID && delete_later[child_id])
			{
				// prevent hierarchy-dragged-to-root from removing the hierarchy
				delete delete_later[child_id];
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
				delete_later[child_id] = true;
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
