
package weave.ui
{
    import weave.services.beans.AttributeColumnInfo;
    import weave.services.AdminInterface;
    import mx.controls.Tree;
    import mx.rpc.events.ResultEvent;

    public class EntityTreeNode
    {
        public var label:String;
        public var object:AttributeColumnInfo
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
            
            AdminInterface.instance.findEntitiesByParent(object.id, populateHandler);
            return;
        }
        public function refresh():void
        {
            
            return;
        }
        public function updateMetadata(metadata:Object):void
        { 
            /* Check difference between new data and data on record; only commit these differences. TODO: Bump version number. */
            /* Fetch attributecolumninfo for this id and update it. */
            return;
        }
        public function addToParent(id:int):void
        {
            AdminInterface.instance.
            return;
        }
        public function deleteFromParent(id:int):void
        {
            return;
        }
    }
}
