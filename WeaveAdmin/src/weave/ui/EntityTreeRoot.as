package weave.ui
{
    import weave.ui.EntityTreeNode;
    import weave.services.beans.AttributeColumnInfo;
    public class EntityTreeRoot extends EntityTreeNode
    {
        private var filterFunc:Function;
        private var aci:AttributeColumnInfo;
        public function EntityTreeRoot(filterFunc:Function)
        {
            super(-1);
            aci = new AttributeColumnInfo();
            aci.id = -1;
            aci.entity_type = AttributeColumnInfo.ENTITY_TABLE;
            aci.privateMetadata = {};
            aci.publicMetadata = {};
            this.filterFunc = filterFunc;
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
            var unfiltered:Array = super.get_children();
            if (unfiltered != null)
                return unfiltered.filter(filterFunc)
            else
                return [];
        }
    }
}
