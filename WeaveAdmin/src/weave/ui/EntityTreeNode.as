
package weave.ui
{
    import flash.events.Event;
    import flash.events.EventDispatcher;
    
    import mx.controls.Tree;
    import mx.rpc.AsyncToken;
    import mx.rpc.events.ResultEvent;
    import mx.utils.ObjectUtil;
    
    import weave.services.AdminInterface;
    import weave.services.WeaveAdminService;
    import weave.services.addAsyncResponder;
    import weave.services.beans.AttributeColumnInfo;
    import weave.services.beans.EntityMetadata;

    public class EntityTreeNode extends EventDispatcher
    {
		public static var debug:Boolean = true;
		
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
        private function objectChanged(..._):void
        {
            dispatchEvent(new Event("objectChanged"));
        }
        private function childrenChanged(..._):void
        {
			weaveTrace("Children changed @ " + this.label);
            dispatchEvent(new Event("childrenChanged"));
        }
        [Bindable(event="objectChanged")] public function get label():String
        {
            var name:String;
            if (object)
			{
				var label:String = object.publicMetadata["title"];
				if (!label)
					label = "[name: " + object.publicMetadata["name"] + "]";
				if (!label)
					label = "[untitled]";
				
				if (debug)
				{
					var typeStrs:Array = ['table','column','category'];
					var typeInts:Array = [AttributeColumnInfo.ENTITY_TABLE, AttributeColumnInfo.ENTITY_COLUMN, AttributeColumnInfo.ENTITY_CATEGORY];
					var typeStr:String = typeStrs[typeInts.indexOf(object.entity_type)];
					var childrenStr:String = _children ? '; ' + _children.length + ' children' : '';
					var idStr:String = ' (' + typeStr + object.id + childrenStr + ') ' + debugId(this);
					label += idStr;
				}
				
				return label;
			}
            else
                return "<Fetching...>";
        }
        [Bindable(event="objectChanged")] public function get object():AttributeColumnInfo
        {
            var info:AttributeColumnInfo = AdminInterface.instance.meta_cache.getEntity(id);
			return info;
        }
        [Bindable(event="childrenChanged")] public function get children():Array
        {
            return get_children();
        }
        protected function get_children():Array
        {
            if (this.object.entity_type == AttributeColumnInfo.ENTITY_COLUMN) return null;
            var fresh_children_ids:Array = AdminInterface.instance.meta_cache.getEntity(id).childIds;
			
			if (children_ids == fresh_children_ids)
                return _children;
            else
                children_ids = fresh_children_ids;

            var new_children:Array = [];
            if (children_ids == null)
                return null;
            for each (var child_id:int in children_ids)
            {
                var new_etn:EntityTreeNode = new EntityTreeNode(child_id)
                new_etn.addEventListener("objectChanged", childrenChanged);
                new_etn.addEventListener("childrenChanged", childrenChanged);
                new_children.push(new_etn);
            }
            _children = new_children;
            childrenChanged();
            return _children;
        }
        public function add_child(child_id:int):void
        {
            var child_obj:AttributeColumnInfo = AdminInterface.instance.meta_cache.getEntity(child_id);
            if (child_obj && (child_obj.entity_type == AttributeColumnInfo.ENTITY_TABLE))
            {
				function afterCopy(event:ResultEvent, token:Object):void
				{
					var new_child_id:int = int(event.result);
					addAsyncResponder(AdminInterface.instance.meta_cache.add_child(new_child_id, id), childrenChanged);
				}
                addAsyncResponder(AdminInterface.instance.copyEntity(child_id), afterCopy);
            }
            else
            {
				var token:AsyncToken = AdminInterface.instance.meta_cache.add_child(child_id, this.id);
				addAsyncResponder(token, childrenChanged);
            }
        }
        public function remove_self():void
        {
            AdminInterface.instance.meta_cache.delete_entity(this.id);
        }
        public function remove_child(child_id:int):void
        {
            var token:AsyncToken = AdminInterface.instance.meta_cache.remove_child(child_id, this.id);
			addAsyncResponder(token, childrenChanged);
        }
        public function commit(diff:EntityMetadata):AsyncToken
        {
            return AdminInterface.instance.meta_cache.update_metadata(id, diff);
        }
        public static function printobj(o:Object):void
        {
            weaveTrace(ObjectUtil.toString(o));
        }
    }
}
