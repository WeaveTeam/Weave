package weave.services
{
    import flash.utils.Dictionary;
    
    import mx.rpc.events.ResultEvent;
    
    import weave.api.getCallbackCollection;
    import weave.api.core.ICallbackCollection;
    import weave.api.core.ILinkableObject;
    import weave.api.data.ColumnMetadata;
    import weave.services.beans.Entity;
    import weave.services.beans.EntityMetadata;
    import weave.services.beans.EntityTableInfo;
    import weave.utils.Dictionary2D;

    public class EntityCache implements ILinkableObject
    {
		public static const ROOT_ID:int = -1;
		
		private var cache_dirty:Object = {}; // id -> Boolean
        private var cache_entity:Object = {}; // id -> Array <Entity>
		private var d2d_child_parent:Dictionary2D = new Dictionary2D(); // <child_id,parent_id> -> Boolean
		private var delete_later:Object = {}; // id -> Boolean
		private var _dataTableIds:Array = []; // array of EntityTableInfo
		private var _dataTableLookup:Object = {}; // id -> EntityTableInfo
		private var pending_invalidate:Object = {}; // id -> Boolean; used to remember which ids to invalidate the next time the entity is requested
		
        public function EntityCache()
        {
			callbacks.addGroupedCallback(this, fetchDirtyEntities);
			Admin.service.addHook(Admin.service.authenticate, null, fetchDirtyEntities);
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
				var entity:Entity = new Entity(id);
				cache_entity[id] = entity;
			}
			
			if (alsoInvalidateParents)
			{
				var parents:Dictionary = d2d_child_parent.dictionary[id];
				if (parents)
				{
					// when a child is deleted, invalidate parents
					for (var parentId:* in parents)
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
					addAsyncResponder(Admin.service.getDataTableList(), handleDataTableList);
				ids.push(int(id));
			}
			if (ids.length > 0)
			{
				cache_dirty = {};
				addAsyncResponder(Admin.service.getEntitiesById(ids), getEntityHandler);
			}
        }
		
		private function handleRemoveEntities(event:ResultEvent, token:Object):void
		{
			for each (var id:int in event.result as Array)
				invalidate(id, true);
		}
		
        private function getEntityHandler(event:ResultEvent, token:Object):void
        {
			for each (var result:Object in event.result)
			{
				var id:int = Entity.getEntityIdFromResult(result);
				var entity:Entity = cache_entity[id] || new Entity(id);
				entity.copyFromResult(result);
	            cache_entity[id] = entity;
				
				// cache child-to-parent mappings
				for each (var childId:int in entity.childIds)
					d2d_child_parent.set(childId, id, true);
			}
			
			callbacks.triggerCallbacks();
        }
		
		private function handleDataTableList(event:ResultEvent, token:Object = null):void
		{
			var items:Array = event.result as Array;
			for (var i:int = 0; i < items.length; i++)
			{
				var item:EntityTableInfo = new EntityTableInfo(items[i]);
				_dataTableLookup[item.id] = item;
				items[i] = item.id;
			}
			_dataTableIds = items;
			
			callbacks.triggerCallbacks();
		}
		
		public function getDataTableIds():Array
		{
			getEntity(ROOT_ID);
			return _dataTableIds;
		}
		
		public function getDataTableInfo(id:int):EntityTableInfo
		{
			getEntity(ROOT_ID);
			return _dataTableLookup[id];
		}
        
		public function clearCache():void
        {
			callbacks.delayCallbacks();
			
			// we don't want to delete the cache because we can still use the cached values for display in the meantime.
			for (var id:* in cache_entity)
				pending_invalidate[id] = true;
			
			callbacks.triggerCallbacks();
			
			callbacks.resumeCallbacks();
        }
		
		public function update_metadata(id:int, diff:EntityMetadata):void
        {
			Admin.service.updateEntity(id, diff);
			invalidate(id);
        }
        public function add_tag(label:String, parentId:int):void
        {
            /* Entity creation should usually impact root, so we'll invalidate root's cache entry and refetch. */
            var em:EntityMetadata = new EntityMetadata();
			em.publicMetadata[ColumnMetadata.TITLE] = label;
			Admin.service.newEntity(Entity.TYPE_CATEGORY, em, parentId);
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
