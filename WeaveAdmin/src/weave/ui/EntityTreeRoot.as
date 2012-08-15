package weave.ui
{
    import weave.ui.EntityTreeNode;
    import weave.services.beans.AttributeColumnInfo;
    public class EntityTreeRoot extends EntityTreeNode
    {
        private var filterTag:int;
        private var aci:AttributeColumnInfo;
        public function EntityTreeRoot(filterTag:int)
        {
            super(-1);
            aci = new AttributeColumnInfo();
            aci.id = -1;
            aci.entity_type = AttributeColumnInfo.TABLE;
            aci.privateMetadata = {};
            aci.publicMetadata = {};
            this.filterTag = filterTag;
        }
        override public function get label():String
        {
            return "Root";
        }
        override public function get object():AttributeColumnInfo
        {
            return aci;
        }
        override public function get children():Array
        {
            var filterFunc:Function = function(etn:EntityTreeNode, index:int, arr:Array):Boolean
            {
                var t:int = etn.object.entity_type;
                return (t == filterTag || t == AttributeColumnInfo.COLUMN);
            };
            var filtered:Array = super.get_children().filter(filterFunc)
            printobj(filtered);
            return filtered;
        }
    }
}
