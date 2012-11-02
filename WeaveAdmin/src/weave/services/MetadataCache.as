package weave.services
{
    import mx.rpc.AsyncToken;
    import mx.rpc.events.ResultEvent;
    
    import weave.api.core.ILinkableObject;
    import weave.api.getCallbackCollection;
    import weave.api.reportError;
    import weave.services.beans.AttributeColumnInfo;
    import weave.services.beans.EntityMetadata;

    public class MetadataCache implements ILinkableObject
    {
        private var cache_entities:Object = {};
        private var cache_childIds:Object = {};
        public function MetadataCache()
        {
        }
        public function get_children(id:int):Array
        {
            return cache_childIds[id];
        }
        public function get_metadata(id:int):AttributeColumnInfo
        {
            return cache_entities[id];
        }
		
        public function fetch_children(id:int):AsyncToken
        {
			// make sure cached value is not null to avoid excess fetch commands
			if (!cache_childIds[id])
				cache_childIds[id] = [];
			
			var token:AsyncToken = AdminInterface.instance.getEntityChildEntities(id);
			addAsyncResponder(token, getChildrenHandler, null, id);
			return token;
        }
        private function getChildrenHandler(event:ResultEvent, token:Object):void
        {
			var id:int = int(token);
            var results:Array = event.result as Array || [];
            var childIds:Array = [];
            for each (var result:Object in results)
            {
				// save list of child ids
				var childId:int = AttributeColumnInfo.getEntityIdFromResult(result);
                childIds.push(childId);
				
				// cache child entity info
				var child:AttributeColumnInfo = cache_entities[childId] || new AttributeColumnInfo();
                child.copyFromResult(result);
                cache_entities[childId] = child;
            }
			
			// temporary solution until the server provides correct ordering
			childIds.sort(Array.NUMERIC);
			
            cache_childIds[id] = childIds;
			getCallbackCollection(this).triggerCallbacks();
        }
        
		public function fetch_metadata(id:int):AsyncToken
        {
			// make sure cached value is not null to avoid excess fetch commands
			if (!cache_entities[id])
			{
				var info:AttributeColumnInfo = new AttributeColumnInfo();
				info.id = id;
				cache_entities[id] = info;
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
				var info:AttributeColumnInfo = cache_entities[id] || new AttributeColumnInfo();
				info.copyFromResult(event.result);
				if (id != info.id)
					reportError("Requested ID does not match result ID");
	            cache_entities[id] = info;
				getCallbackCollection(this).triggerCallbacks();
			}
			else
				weaveTrace('getEntity(',id,') returned null');
        }
        
		public function clearCache():void
        {
            cache_entities = {};
            cache_childIds = {};
        }
        
		public function update_metadata_and_fetch(id:int, metadata:EntityMetadata):AsyncToken
        {
			AdminInterface.instance.updateEntity(id, metadata);
            return fetch_metadata(id);
        }
        public function add_tag_and_fetch(label:String):AsyncToken
        {
            /* Entity creation should usually impact root, so we'll invalidate root's cache entry and refetch. */
            var em:EntityMetadata = new EntityMetadata();
			em.publicMetadata = {title: label};
			AdminInterface.instance.addTag(em);
			// refresh root
			return fetch_children(-1);
        }
        public function delete_entity_and_fetch(id:int):AsyncToken
        {
            /* Entity deletion should usually impact root, so we'll invalidate root's cache entry and refetch. */
            delete cache_childIds[id];
            delete cache_entities[id]; 
			AdminInterface.instance.removeEntity(id);
			// refresh root
			return fetch_children(-1);
        }
        public function add_child_and_fetch(child_id:int, parent_id:int):AsyncToken
        {
			AdminInterface.instance.addChildToParent(child_id, parent_id);
			return fetch_children(parent_id);
        }
        public function remove_child_and_fetch(child_id:int, parent_id:int):AsyncToken
        {
			AdminInterface.instance.removeChildFromParent(child_id, parent_id);
            return fetch_children(parent_id);
        }
    }
}
