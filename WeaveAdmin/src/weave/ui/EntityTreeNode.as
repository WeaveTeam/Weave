
package weave.ui
{
    import weave.services.beans.AttributeColumnInfo;
    import weave.services.AdminInterface;
    import weave.services.WeaveAdminService;
    import mx.controls.Tree;
    import mx.rpc.events.ResultEvent;

    public class EntityTreeNode
    {
        public var label:String;
        public var object:AttributeColumnInfo;
        public var children:Array = [];

        public var columns:Array = [];
        public var is_populated:Boolean = false;
        public var pending_commit:Boolean = false;
        public function EntityTreeNode(info:AttributeColumnInfo)
        {
            this.object = info;
            label = info.publicMetadata["title"];
            if (info.entity_type == 1 || info.entity_type == 0) children = null;
            if (label == null) label = info.publicMetadata["name"]; // TODO: hack, remove later after full migration code is written.
        }
        public function populate(onComplete:Function = null):void
        {
            var etn:EntityTreeNode = this;
        
            function populateHandler(event:ResultEvent, token:Object = null):void
            {
                etn.children = [];
                etn.columns = [];
                var entities:Array = event.result as Array || [];
                for each (var obj:Object in entities)
                {
                    var entity:AttributeColumnInfo = new AttributeColumnInfo(obj);
                    if (entity.entity_type == 2)
                    {
                        etn.children.push(new EntityTreeNode(entity));
                    }
                    else if (entity.entity_type == 1)
                    {
                        etn.columns.push(new EntityTreeNode(entity));
                    }
                }
                if (onComplete != null)
                {
                    onComplete(etn);
                }
                etn.is_populated = true;
            }
            
            AdminInterface.instance.getEntityChildren(object.id, populateHandler);
            return;
        }
        public function refresh(onComplete:Function = null):void
        {
            var etn:EntityTreeNode = this;
            function refreshHandler(event:ResultEvent, token:Object = null):void
            {
                var freshetn:AttributeColumnInfo = new AttributeColumnInfo(event.result);
                etn.object = freshetn;
                if (onComplete != null)
                    onComplete(etn);
                etn.is_populated = true;
            }
            AdminInterface.instance.getEntity(object.id, refreshHandler);
            return;
        }
        public function addToParent(parent_id:int):void
        {
            AdminInterface.instance.addChild(object.id, parent_id, null);
            return;
        }
        public function removeFromParent(parent_id:int):void
        {
            AdminInterface.instance.removeChild(object.id, parent_id, null);
            return;
        }
        public function commit(diff:Object, handler:Function = null):void
        {
            function commitHandler(o:Object):void
            {
                refresh(handler);
            }
            AdminInterface.instance.updateEntity(object.id, diff, commitHandler);
        }
        static public function mergeObjects(a:Object, b:Object):Object
        {
            var result:Object = {};
            for each (var obj:Object in [a, b])
                for (var property:Object in obj)
                    result[property] = obj[property];
            return result;
        }
        static public function diffObjects(old:Object, fresh:Object):Object
        {
            var diff:Object = {};
            for (var property:String in mergeObjects(old, fresh))
                if (old[property] != fresh[property])
                    diff[property] = fresh[property];
            return diff;
        }
        private static function yell(str:String):void
        {
            WeaveAdminService.messageDisplay(null, str, false);
        }
        private static function printobj(o:Object):void
        {
            for (var prop:String in o)
                yell(prop + ":" + o[prop]);
        }

    }
}
