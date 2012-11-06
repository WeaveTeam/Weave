package weave.services
{
    import flash.utils.Dictionary;
    
    import mx.rpc.AsyncToken;
    import mx.rpc.events.ResultEvent;
    
    import weave.api.core.ICallbackCollection;
    import weave.api.core.ILinkableObject;
    import weave.api.getCallbackCollection;
    import weave.api.reportError;
    import weave.services.beans.AttributeColumnInfo;
    import weave.services.beans.EntityMetadata;
    import weave.utils.Dictionary2D;
    import weave.utils.EventUtils;

    public class MetadataCache implements ILinkableObject
    {
		public static const ROOT_ID:int = -1;
		
		private var cache_dirty:Object = {}; // id -> Boolean
        private var cache_entity:Object = {}; // id -> Array <AttributeColumnInfo>
		private var d2d_child_parent:Dictionary2D = new Dictionary2D(); // <child_id,parent_id> -> Boolean
		
        public function MetadataCache()
        {
			callbacks.addGroupedCallback(this, fetchDirtyEntities);
        }
		
		private function invalidate(id:int, alsoInvalidateParents:Boolean = false):AsyncToken
		{
			var token:AsyncToken;
			
			callbacks.delayCallbacks();
			
			if (!cache_dirty[id])
				callbacks.triggerCallbacks();
			
			cache_dirty[id] = true;
			
			if (!cache_entity[id])
			{
				var info:AttributeColumnInfo = new AttributeColumnInfo();
				info.id = id;
				cache_entity[id] = info;
			}
			
			if (alsoInvalidateParents)
			{
				var parents:Dictionary = d2d_child_parent.dictionary[id];
				if (parents)
				{
					// when a child is deleted, invalidate parents
					for (var parentId:* in parents)
						token = invalidate(parentId);
				}
				else
				{
					// invalidate root when child has no parents
					token = invalidate(ROOT_ID);
				}
			}
			
			callbacks.resumeCallbacks();
			
			return token;
		}
		
		private function get callbacks():ICallbackCollection { return getCallbackCollection(this); }
		
		public function getEntity(id:int):AttributeColumnInfo
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
				addAsyncResponder(AdminInterface.instance.getEntitiesById(ids), getEntityHandler);
			}
        }
		
        private function getEntityHandler(event:ResultEvent, token:Object):void
        {
			for each (var result:Object in event.result)
			{
				var id:int = AttributeColumnInfo.getEntityIdFromResult(result);
				var info:AttributeColumnInfo = cache_entity[id] || new AttributeColumnInfo();
				info.copyFromResult(result);
	            cache_entity[id] = info;
				
				// cache child-to-parent mappings
				for each (var childId:int in info.childIds)
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
		
		public function update_metadata(id:int, diff:EntityMetadata):AsyncToken
        {
			var token:AsyncToken = AdminInterface.instance.updateEntity(id, diff);
			invalidate(id);
            return token;
        }
        public function add_tag(label:String):AsyncToken
        {
            /* Entity creation should usually impact root, so we'll invalidate root's cache entry and refetch. */
            var em:EntityMetadata = new EntityMetadata();
			em.publicMetadata = {title: label};
			var token:AsyncToken = AdminInterface.instance.addTag(em);
			invalidate(ROOT_ID); // because the tag will appear under root
			return token;
        }
        public function delete_entity(id:int):AsyncToken
        {
            /* Entity deletion should usually impact root, so we'll invalidate root's cache entry and refetch. */
			var token:AsyncToken = AdminInterface.instance.removeEntity(id);
			invalidate(id, true);
			return token;
        }
        public function add_child(child_id:int, parent_id:int):AsyncToken
        {
			var token:AsyncToken;
			// add to root not supported
			if (parent_id != ROOT_ID)
				token = AdminInterface.instance.addChildToParent(child_id, parent_id);
			var invalidateToken:AsyncToken = invalidate(parent_id);
			
			return token || invalidateToken;
        }
        public function remove_child(child_id:int, parent_id:int):AsyncToken
        {
			var token:AsyncToken;
			
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
				token = AdminInterface.instance.removeChildFromParent(child_id, parent_id);
			}
			var invalidateToken:AsyncToken = invalidate(child_id, true);
            return token || invalidateToken;
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
