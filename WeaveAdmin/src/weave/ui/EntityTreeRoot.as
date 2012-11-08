package weave.ui
{
    import weave.ui.EntityTreeNode;
    import weave.services.beans.Entity;
    public class EntityTreeRoot extends EntityTreeNode
    {
        private var filterFunc:Function;
        private var aci:Entity;
        public function EntityTreeRoot(filterFunc:Function)
        {
            super(-1);
            aci = new Entity();
            aci.id = -1;
            aci.type = Entity.TYPE_CATEGORY;
            aci.privateMetadata = {};
            aci.publicMetadata = {};
            this.filterFunc = filterFunc;
        }
        override public function get label():String
        {
            return "Root";
        }
        override public function get object():Entity
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
