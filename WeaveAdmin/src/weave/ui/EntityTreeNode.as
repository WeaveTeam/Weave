
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
        [Bindable] public var committed:Boolean = true;
        public var oldobject:AttributeColumnInfo;

        public var columns:Array = [];
        public var is_populated:Boolean = false;

        public function EntityTreeNode(info:AttributeColumnInfo)
        {
            this.object = info;
            this.oldobject = info;
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
                etn.oldobject = freshetn;
                etn.object = freshetn.deepcopy();
                if (onComplete != null)
                    onComplete(etn);
                etn.is_populated = true;
            }
            AdminInterface.instance.getEntity(object.id, refreshHandler);
            return;
        }
        public function update(meta:Object):void
        {
            var splitMeta:Array = AttributeColumnInfo.splitObject(meta);
            object.publicMetadata = splitMeta[0];
            object.privateMetadata = splitMeta[1];
            committed = false;
        }
        public function revert():void
        {
            object = oldobject;
            committed = true;
        }
        public function updateFromDataProvider(dp:Array):void
        {
            if (this.committed == true)
            {

            }
            for each (var row:Object in dp)
            {
            }
            return;
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
        public function commit():void 
        { 
            
            /* Check difference between new data and data on record; only commit these differences. TODO: Bump version number. */
            var old:Object = AttributeColumnInfo.mergeObjects(oldobject.publicMetadata, oldobject.privateMetadata);
            var fresh:Object = AttributeColumnInfo.mergeObjects(object.publicMetadata, object.privateMetadata);
            var diff:Object = AttributeColumnInfo.diffObjects(old, fresh);
            var etn:EntityTreeNode = this;
            AdminInterface.instance.updateEntity(object.id, diff, commitHandler);
            function commitHandler(event:ResultEvent, token:Object = null):void
            {
                if (event.result as Boolean) etn.committed = true;
            }
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
