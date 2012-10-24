package weave.services
{
    import weave.services.beans.AttributeColumnInfo;
    import weave.services.AdminInterface;
    import weave.services.WeaveAdminService;
    import mx.rpc.events.ResultEvent;
    public class MetadataCache
    {
        private var entity_metacache:Object = {}; /* Of AttributeColumnInfo's */
        private var entity_childcache:Object = {}; /* Of arrays of AttributeColumnInfo's */
        private var metaquery_queues:Object = {}; /* Of arrays of functions */
        private var childquery_queues:Object = {}; /* Of arrays of functions */
        public function MetadataCache()
        {
            /* Nothing really needs to be done. */
            return; 
        }
        public function get_children(id:int, onComplete:Function = null):Array
        {
            if (entity_childcache[id] != null)
            {
                return entity_childcache[id];
            }
            else
            {
                fetch_children(id, onComplete);
                return null; 
            }
        }
        public function get_metadata(id:int, onComplete:Function = null):AttributeColumnInfo
        {
            if (entity_metacache[id] != null)
            {
                return entity_metacache[id];
            }
            else
            {
                fetch_metadata(id, onComplete);
                return null;
            }
        }
        public function fetch_children(id:int, onComplete:Function = null):void
        {
            if (childquery_queues[id] == null) childquery_queues[id] = [];

            var queue:Array = childquery_queues[id];

            if (onComplete != null)
                queue.push(onComplete);

            if (queue.length == 1)
                AdminInterface.instance.getEntityChildren(id, getChildrenHandler);

            function getChildrenHandler(event:ResultEvent, token:Object = null):void
            {
                var obj_children:Array = event.result as Array || [];
                var children:Array = [];
                for each (var obj:Object in obj_children)
                {
                    var entity:AttributeColumnInfo = new AttributeColumnInfo(obj);
                    entity_metacache[entity.id] = entity; /* Update the entries while we're here. */
                    children.push(entity.id);
                }
                entity_childcache[id] = children;
                /* Call all the queued requesters, if any */
                while (queue.length > 0)
                {
                    var f:Function = queue.shift();
                    f(children);
                }
            }
        }
        public function fetch_metadata(id:int, onComplete:Function = null):void
        {
            if (metaquery_queues[id] == null) metaquery_queues[id] = [];
            var queue:Array = metaquery_queues[id];

            if (onComplete != null)
                queue.push(onComplete);

            if (queue.length == 1)
                AdminInterface.instance.getEntity(id, getEntityHandler);

            function getEntityHandler(event:ResultEvent, token:Object = null):void
            {
                var entity:AttributeColumnInfo = new AttributeColumnInfo(event.result);
                entity_metacache[id] = entity;
                while (queue.length > 0)
                {
                    var f:Function = queue.shift();
                    f(entity);
                }
            }
        }
        public function invalidate(id:int = -2):void
        {
            if (id == -2)
            {
                entity_metacache = {};
                entity_childcache = {};
            }
            else 
            {
                delete entity_metacache[id];
                delete entity_childcache[id];
            }
        }
        public function update_metadata(id:int, pubMeta:Object, privMeta:Object, onComplete:Function = null):void
        {
            function afterUpdate():void
            {
                fetch_metadata(id, onComplete);
            }
            delete entity_metacache[id];
            AdminInterface.instance.updateEntity(id, {"public":pubMeta, "private":privMeta}, afterUpdate);
            /* Do stuff, and things. */ 
        }
        public function add_tag(label:String, onComplete:Function = null):void
        {
            /* Entity creation should usually impact root, so we'll invalidate root's cache entry and refetch. */
            function afterUpdate():void
            {
                delete entity_childcache[-1];  /* Invalidate the root. */
                fetch_children(-1, onComplete);
            }
            var meta:Object = {};
            meta["public"] = {title: label};
            AdminInterface.instance.addTag(meta, afterUpdate);
        }
        public function delete_entity(id:int, onComplete:Function = null):void
        {
            /* Entity deletion should usually impact root, so we'll invalidate root's cache entry and refetch. */
            function afterUpdate():void
            {
                fetch_children(-1, onComplete);
            }
            delete entity_childcache[id];
            delete entity_metacache[id]; 
            /* Invalidate the root. */
            delete entity_childcache[-1];
            AdminInterface.instance.removeEntity(id, afterUpdate);
        }
        public function add_child(child_id:int, parent_id:int, onComplete:Function = null):void
        {
            function afterUpdate():void
            {
                fetch_children(parent_id, onComplete);
            }
            delete entity_childcache[parent_id];
            AdminInterface.instance.addChildToParent(child_id, parent_id, afterUpdate);
        }
        public function copy_and_add(child_id:int, parent_id:int, onComplete:Function = null):void
        {
            return;
        }
        public function remove_child(child_id:int, parent_id:int, onComplete:Function = null):void
        {
            function afterUpdate():void
            {
                fetch_children(parent_id, onComplete);
            }
            delete entity_childcache[parent_id];
            AdminInterface.instance.removeChildFromParent(child_id, parent_id, afterUpdate);
        }
    }
}
