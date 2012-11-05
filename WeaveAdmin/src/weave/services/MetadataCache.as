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

    public class MetadataCache implements ILinkableObject
    {
		public static const ROOT_ID:int = -1;
		
		private var cache_dirty:Object = {}; // id -> Boolean
        private var cache_entity:Object = {}; // id -> Array <AttributeColumnInfo>
		private var d2d_child_parent:Dictionary2D = new Dictionary2D(); // <child_id,parent_id> -> Boolean
		
        public function MetadataCache()
        {
        }
		
		private function invalidate(id:int, alsoInvalidateParents:Boolean = false):void
		{
			callbacks.delayCallbacks();
			
			if (!cache_dirty[id])
				callbacks.triggerCallbacks();
			cache_dirty[id] = true;
			
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
			
			if (id == ROOT_ID)
				fetchEntity(id);
			
			callbacks.resumeCallbacks();
		}
		
		private function get callbacks():ICallbackCollection { return getCallbackCollection(this); }
		
		public function getEntity(id:int):AttributeColumnInfo
		{
			// automatically fetch
			if (cache_dirty[id] || !cache_entity[id])
				fetchEntity(id);
			
            return cache_entity[id];
		}
		
		public function fetchEntity(id:int):AsyncToken
        {
			// avoid excess auto-fetching by clearing the dirty flag and setting a cached value if missing
			delete cache_dirty[id];
			if (!cache_entity[id])
			{
				var info:AttributeColumnInfo = new AttributeColumnInfo();
				info.id = id;
				cache_entity[id] = info;
			}
			var token:AsyncToken = AdminInterface.instance.getEntity(id);
			addAsyncResponder(token, getEntityHandler, null, id);
			return token;
        }
		
        private function getEntityHandler(event:ResultEvent, token:Object):void
        {
			var id:int = int(token);
			if (event.result)
			{
				var info:AttributeColumnInfo = cache_entity[id] || new AttributeColumnInfo();
				info.copyFromResult(event.result);
				if (id != info.id)
					reportError("Requested ID does not match result ID");
	            cache_entity[id] = info;
				
				// cache child-to-parent mappings
				for each (var childId:int in info.childIds)
					d2d_child_parent.set(childId, id, true);
			}
			else
				weaveTrace('getEntity(',id,') returned null');
			
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
			var token:AsyncToken = AdminInterface.instance.addChildToParent(child_id, parent_id);
			invalidate(parent_id);
			return token;
        }
        public function remove_child(child_id:int, parent_id:int):AsyncToken
        {
			var token:AsyncToken = AdminInterface.instance.removeChildFromParent(child_id, parent_id);
			invalidate(child_id, true);
            return token;
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
