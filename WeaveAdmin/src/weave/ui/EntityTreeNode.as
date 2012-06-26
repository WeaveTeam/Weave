
package weave.ui
{
    import weave.services.beans.AttributeColumnInfo;
    import weave.services.AdminInterface;
    import mx.controls.Tree;
    import mx.rpc.events.ResultEvent;

    public class EntityTreeNode
    {
        public var label:String;
        public var object:AttributeColumnInfo;
        public var children:Array = [];

        public var columns:Array = [];
        public var is_populated:Boolean = false;

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
        public function updateFromDataProvider(rows:Array):Boolean
        {
            var pub:Object = {};
            var priv:Object = {};
                
            for each (var row:Object in rows)
            {
                if (row.isPrivate)
                    priv[row.property] = row.value;
                else
                    pub[row.property] = row.value;
            }
            // TODO: Actually commit to DB and return success/fail
            this.object.publicMetadata = pub;
            this.object.privateMetadata = pub;
            return true;
        }
        public function asDataProvider():Array
        {
            function objToArr(o:Object, isPrivate:Boolean = false):Array
            {
                var arr:Array = [];
                for (var prop:String in o) 
                {
                    arr.push({property: prop, value: o[prop], isPrivate: isPrivate});
                }
                return arr;
            }
            var dgarr:Array = objToArr(object.publicMetadata);
            dgarr = dgarr.concat(objToArr(object.privateMetadata, true));
            return dgarr;
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
    }
}
