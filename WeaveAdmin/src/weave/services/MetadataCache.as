package weave.services
{
    import mx.rpc.AsyncToken;
    import mx.rpc.events.ResultEvent;
    
    import weave.api.core.ILinkableObject;
    import weave.api.getCallbackCollection;
    import weave.services.beans.AttributeColumnInfo;
    import weave.services.beans.EntityMetadata;

    public class MetadataCache implements ILinkableObject
    {
        private var entity_metacache:Object = {}; /* Of AttributeColumnInfo's */
        private var entity_childcache:Object = {}; /* Of arrays of AttributeColumnInfo's */
        public function MetadataCache()
        {
        }
        public function get_children(id:int):Array
        {
            return entity_childcache[id];
        }
        public function get_metadata(id:int):AttributeColumnInfo
        {
            return entity_metacache[id];
        }
        public function fetch_children(id:int):AsyncToken
        {
			entity_childcache[id] = [];
			
			var token:AsyncToken = AdminInterface.instance.getEntityChildEntities(id);
			addAsyncResponder(token, getChildrenHandler, null, id);
			return token;
        }
        private function getChildrenHandler(event:ResultEvent, token:Object):void
        {
			var id:int = int(token);
            var obj_children:Array = event.result as Array || [];
            var childIds:Array = [];
            for each (var obj:Object in obj_children)
            {
                var entity:AttributeColumnInfo = AttributeColumnInfo.fromResult(obj);
                entity_metacache[entity.id] = entity; /* Update the entries while we're here. */
                childIds.push(entity.id);
            }
            entity_childcache[id] = childIds;
			getCallbackCollection(this).triggerCallbacks();
        }
        public function fetch_metadata(id:int):AsyncToken
        {
			var info:AttributeColumnInfo = new AttributeColumnInfo();
			info.id = id;
			entity_metacache[id] = info;
			var token:AsyncToken = AdminInterface.instance.getEntity(id);
			addAsyncResponder(token, getEntityHandler, null, id);
			return token;
        }
        private function getEntityHandler(event:ResultEvent, token:Object):void
        {
			var id:int = int(token);
            entity_metacache[id] = event.result ? AttributeColumnInfo.fromResult(event.result) : null;
			getCallbackCollection(this).triggerCallbacks();
        }
        public function clearCache():void
        {
            entity_metacache = {};
            entity_childcache = {};
        }
        public function update_metadata_and_fetch(id:int, metadata:EntityMetadata):AsyncToken
        {
            delete entity_metacache[id];
			
			AdminInterface.instance.updateEntity(id, metadata);
            return fetch_metadata(id);
        }
        public function add_tag_and_fetch(label:String):AsyncToken
        {
            /* Entity creation should usually impact root, so we'll invalidate root's cache entry and refetch. */
            var em:EntityMetadata = new EntityMetadata();
			em.publicMetadata = {title: label};
            delete entity_childcache[-1];  /* Invalidate the root. */
			AdminInterface.instance.addTag(em);
			return fetch_children(-1);
        }
        public function delete_entity_and_fetch(id:int):AsyncToken
        {
            /* Entity deletion should usually impact root, so we'll invalidate root's cache entry and refetch. */
            delete entity_childcache[id];
            delete entity_metacache[id]; 
            /* Invalidate the root. */
            delete entity_childcache[-1];
			AdminInterface.instance.removeEntity(id);
			return fetch_children(-1);
        }
        public function add_child_and_fetch(child_id:int, parent_id:int):AsyncToken
        {
            delete entity_childcache[parent_id];
			AdminInterface.instance.addChildToParent(child_id, parent_id);
			return fetch_children(parent_id);
        }
        public function remove_child_and_fetch(child_id:int, parent_id:int):AsyncToken
        {
            delete entity_childcache[parent_id];
			AdminInterface.instance.removeChildFromParent(child_id, parent_id);
            return fetch_children(parent_id);
        }
    }
}
