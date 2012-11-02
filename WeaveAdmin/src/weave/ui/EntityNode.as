
package weave.ui
{
    import flash.events.Event;
    import flash.events.EventDispatcher;
    
    import mx.controls.Tree;
    import mx.rpc.AsyncToken;
    import mx.rpc.events.ResultEvent;
    import mx.utils.ObjectUtil;
    
    import weave.api.data.ColumnMetadata;
    import weave.services.AdminInterface;
    import weave.services.WeaveAdminService;
    import weave.services.addAsyncResponder;
    import weave.services.beans.AttributeColumnInfo;
    import weave.services.beans.EntityMetadata;

    public class EntityNode
    {
		public static var debug:Boolean = true;
		
		public var id:int = -1;
		
		public function get label():String
		{
			if (!AdminInterface.instance.userHasAuthenticated)
				return 'please log in';
			
			var info:AttributeColumnInfo = AdminInterface.instance.meta_cache.get_metadata(id);
			if (!info)
			{
				AdminInterface.instance.meta_cache.fetch_metadata(id);
				return lang('<Fetching...>');
			}
			
			var title:String = info.publicMetadata[ColumnMetadata.TITLE];
			if (!title)
				title = '[name: ' + info.publicMetadata['name'] + ']';
			if (!title)
				title = '[untitled]';
				
			if (debug)
			{
				var _children:Array = children;
				var typeStrs:Array = ['table','column','category'];
				var typeInts:Array = [AttributeColumnInfo.ENTITY_TABLE, AttributeColumnInfo.ENTITY_COLUMN, AttributeColumnInfo.ENTITY_CATEGORY];
				var typeStr:String = typeStrs[typeInts.indexOf(info.entity_type)];
				var childrenStr:String = _children ? '; ' + _children.length + ' children' : '';
				var idStr:String = '(' + typeStr + id + childrenStr + ') ' + debugId(this);
				title = idStr + ' ' + title;
			}
			
			return title;
		}
		
		public function get children():Array
		{
			if (!AdminInterface.instance.userHasAuthenticated)
				return null;
				
			var childIds:Array = AdminInterface.instance.meta_cache.get_children(id);
			if (!childIds)
			{
				AdminInterface.instance.meta_cache.fetch_children(id);
				return null;
			}
			
			_children.length = childIds.length;
			for (var i:int = 0; i < childIds.length; i++)
			{
				var childId:int = childIds[i];
				var child:EntityNode = childCache[childId];
				
				if (!child)
					childCache[childId] = child = new EntityNode();
				
				// set id whether or not it's a new child
				child.id = childId;
				
				_children[i] = child;
			}
			
			return _children.length ? _children : null;
		}
		
		private var _children:Array = [];
		
		private const childCache:Object = {};
    }
}
