
package weave.ui
{
    import weave.services.beans.AttributeColumnInfo;
    import weave.services.AdminInterface;
    import weave.services.WeaveAdminService;
    import mx.controls.Tree;
    import flash.events.EventDispatcher;
    import flash.events.Event;
    import mx.utils.ObjectUtil;
    public class EntityTreeNode extends EventDispatcher
    {
        public static var inc:int = 0;
        public var objid:int = 0;
        public var _id:int;
        protected var _children:Array; /* internal list of EntityTreeNode children to ensure we don't go creating unnecessary objects */
        protected var children_ids:Array; /* the ID array from which _children was built */
        public function get id():int
        {
            return _id;
        }
        
        public function EntityTreeNode(id:int)
        {
            objid = inc++;
            this._id = id;
        }
        private function objectChanged(obj:Object):void
        {
            dispatchEvent(new Event("objectChanged"));
        }
        private function childrenChanged(obj:Object):void
        {
            dispatchEvent(new Event("childrenChanged"));
        }
        [Bindable(event="objectChanged")] public function get label():String
        {
            var obj:Object = this.object;
            var name:String;
            if (obj)
                return obj.publicMetadata["title"] || obj.publicMetadata["name"] || "[No label.]";
            else
                return "<Fetching...>";
        }
        [Bindable(event="objectChanged")] public function get object():AttributeColumnInfo
        {
            return AdminInterface.instance.meta_cache.get_metadata(id, objectChanged);
        }
        [Bindable(event="childrenChanged")] public function get children():Array
        {
            return get_children();
        }
        protected function get_children():Array
        {
            if (this.object.entity_type == AttributeColumnInfo.COLUMN) return null;
            var fresh_children_ids:Array = AdminInterface.instance.meta_cache.get_children(id, childrenChanged);
            if (children_ids == fresh_children_ids)
                return _children;
            else
                children_ids = fresh_children_ids;

            var new_children:Array = [];
            if (children_ids == null)
                return null;
            for each (var id:int in children_ids)
                new_children.push(new EntityTreeNode(id));
            return _children = new_children;
        }
        public function add_child(child_id:int):void
        {
            AdminInterface.instance.meta_cache.add_child(child_id, this.id);
        }
        public function remove_self():void
        {
            AdminInterface.instance.meta_cache.delete_entity(this.id);
        }
        public function remove_child(child_id:int):void
        {
            AdminInterface.instance.meta_cache.remove_child(child_id, this.id);
        }
        public function commit(pubDiff:Object, privDiff:Object, onComplete:Function):void
        {
            AdminInterface.instance.meta_cache.update_metadata(id, pubDiff, privDiff, onComplete);
        }
        public static function yell(str:String):void
        {
            WeaveAdminService.messageDisplay(null, str, false);
        }
        public static function printobj(o:Object):void
        {
            yell(ObjectUtil.toString(o));
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
    }
}
