package weave.services
{
    import flash.utils.Dictionary;
    
    import mx.rpc.events.ResultEvent;
    
    import weave.api.core.ICallbackCollection;
    import weave.api.core.ILinkableObject;
    import weave.api.getCallbackCollection;
    import weave.services.beans.Entity;
    import weave.services.beans.EntityMetadata;
    import weave.utils.Dictionary2D;

    public class EntityCache implements ILinkableObject
    {
		public static const ROOT_ID:int = -1;
		
		private var cache_dirty:Object = {}; // id -> Boolean
        private var cache_entity:Object = {}; // id -> Array <Entity>
		private var d2d_child_parent:Dictionary2D = new Dictionary2D(); // <child_id,parent_id> -> Boolean
		
        public function EntityCache()
        {
			callbacks.addGroupedCallback(this, fetchDirtyEntities);
        }
		
		public function invalidate(id:int, alsoInvalidateParents:Boolean = false):void
		{
			callbacks.delayCallbacks();
			
			if (!cache_dirty[id])
				callbacks.triggerCallbacks();
			
			cache_dirty[id] = true;
			
			if (!cache_entity[id])
			{
				var entity:Entity = new Entity();
				entity.id = id;
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
			if (!cache_entity[id])
				invalidate(id);
			
            return cache_entity[id];
		}
		
		private function fetchDirtyEntities():void
		{
			var ids:Array = [];
			for (var id:* in cache_dirty)
				ids.push(int(id));
			if (ids.length > 0)
			{
				cache_dirty = {};
				addAsyncResponder(AdminInterface.service.getEntitiesById(ids), getEntityHandler);
			}
        }
		
        private function getEntityHandler(event:ResultEvent, token:Object):void
        {
			for each (var result:Object in event.result)
			{
				var id:int = Entity.getEntityIdFromResult(result);
				var entity:Entity = cache_entity[id] || new Entity();
				entity.copyFromResult(result);
	            cache_entity[id] = entity;
				
				// cache child-to-parent mappings
				for each (var childId:int in entity.childIds)
					d2d_child_parent.set(childId, id, true);
			}
			
			callbacks.triggerCallbacks();
        }
        
		public function clearCache():void
        {
			callbacks.delayCallbacks();
			
			// we don't want to delete the cache because we can still use the cached values for display in the meantime.
			for (var id:* in cache_entity)
				invalidate(id);
			
			callbacks.resumeCallbacks();
        }
		
		public function update_metadata(id:int, diff:EntityMetadata):void
        {
			AdminInterface.service.updateEntity(id, diff);
			invalidate(id);
        }
        public function add_tag(label:String):void
        {
            /* Entity creation should usually impact root, so we'll invalidate root's cache entry and refetch. */
            var em:EntityMetadata = new EntityMetadata();
			em.publicMetadata = {title: label};
			AdminInterface.service.addEntity(Entity.TYPE_CATEGORY, em, -1);
			invalidate(ROOT_ID); // because the tag will appear under root
        }
        public function delete_entity(id:int):void
        {
            /* Entity deletion should usually impact root, so we'll invalidate root's cache entry and refetch. */
			AdminInterface.service.removeEntity(id);
			invalidate(id, true);
        }
        public function add_child(child_id:int, parent_id:int):void
        {
			// add to root not supported
			AdminInterface.service.addChildToParent(child_id, parent_id);
			invalidate(parent_id);
        }
        public function remove_child(child_id:int, parent_id:int):void
        {
			// remove from root not supported, but invalidate root anyway in case the child is added via add_child later
			if (parent_id == ROOT_ID)
			{
				invalidate(ROOT_ID);
			}
			else
			{
				var d:Dictionary = d2d_child_parent.dictionary[child_id];
				var count:int = 0;
				for (var _id:* in d)
					count++;
				if (count == 1)
					invalidate(ROOT_ID);
				AdminInterface.service.removeChildFromParent(child_id, parent_id);
			}
			invalidate(child_id, true);
        }
		
		static public function mergeObjects(oldObj:Object, newObj:Object):Object
		{
			var result:Object = {};
			var prop:Object;
			
			for (prop in oldObj)
				result[prop] = oldObj[prop];
			
			for (prop in newObj)
				result[prop] = newObj[prop];
			
			return result;
		}
		static public function diffObjects(oldObj:Object, newObj:Object):Object
		{
			var diff:Object = {};
			for (var property:String in mergeObjects(oldObj, newObj))
				if (oldObj[property] != newObj[property])
					diff[property] = newObj[property];
			return diff;
		}
    }
}
