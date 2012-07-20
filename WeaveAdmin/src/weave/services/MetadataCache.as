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
        public function update_metadata(id:int, pubMeta:Object, privMeta:Object, onComplete:Function = null):void
        {
 
            /* Do stuff, and things. */ 
        }
    }
}
