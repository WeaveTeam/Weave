
package weave.ui
{
    import flash.events.Event;
    import flash.events.EventDispatcher;
    
    import mx.collections.ArrayCollection;
    import mx.collections.ICollectionView;
    import mx.collections.ListCollectionView;
    import mx.controls.Tree;
    import mx.rpc.AsyncToken;
    import mx.rpc.events.ResultEvent;
    import mx.utils.ObjectUtil;
    
    import weave.api.data.ColumnMetadata;
    import weave.services.AdminInterface;
    import weave.services.MetadataCache;
    import weave.services.WeaveAdminService;
    import weave.services.addAsyncResponder;
    import weave.services.beans.AttributeColumnInfo;
    import weave.services.beans.EntityMetadata;

	[RemoteClass]
    public class EntityNode
    {
		public static var debug:Boolean = true;
		
		/**
		 * @param filterType To be used by root node only.
		 */
		public function EntityNode(rootFilterType:int = -1)
		{
			_rootFilterType = rootFilterType;
		}
		
		private var _rootFilterType:int = -1;
		
		public var id:int = -1;
		
		public function getEntity():AttributeColumnInfo
		{
			return AdminInterface.instance.meta_cache.getEntity(id);
		}
		
		// the node can re-use the same children array
		private const _childNodes:Array = [];
		private const _childCollectionView:ICollectionView = new ArrayCollection(_childNodes);
		
		// We cache child nodes to avoid creating unnecessary objects.
		// Each node must have its own child cache (not static) because we can't have the same node in two places in a Tree.
		private const _childNodeCache:Object = {}; // id -> EntityNode
		
		public function get label():String
		{
			if (!AdminInterface.instance.userHasAuthenticated)
				return 'Not logged in';
			
			var info:AttributeColumnInfo = getEntity();
			
			var title:String = info.publicMetadata[ColumnMetadata.TITLE];
			if (!title)
				title = '[name: ' + info.publicMetadata['name'] + ']';
			if (!title)
				title = '[untitled]';
				
			if (debug)
			{
				var typeStrs:Array = ['table','column','category'];
				var typeInts:Array = [AttributeColumnInfo.ENTITY_TABLE, AttributeColumnInfo.ENTITY_COLUMN, AttributeColumnInfo.ENTITY_CATEGORY];
				var typeStr:String = typeStrs[typeInts.indexOf(info.entity_type)];
				var childrenStr:String = _childNodes ? '; ' + _childNodes.length + ' children' : '';
				var idStr:String = '(' + typeStr + id + childrenStr + ') ' + debugId(this);
				title = idStr + ' ' + title;
			}
			
			return title;
		}
		
		public function get children():ICollectionView
		{
			if (!AdminInterface.instance.userHasAuthenticated)
				return null;
			
			var entity:AttributeColumnInfo = AdminInterface.instance.meta_cache.getEntity(id);
			var childIds:Array = entity.childIds;
			if (!childIds)
				return null;
			
			var outputIndex:int = 0;
			for (var i:int = 0; i < childIds.length; i++)
			{
				var childId:int = childIds[i];
				
				// if there is a filter type, filter out non-column entities that do not have that type
				if (_rootFilterType >= 0)
				{
					var childEntity:AttributeColumnInfo = AdminInterface.instance.meta_cache.getEntity(childId);
					if (childEntity.entity_type != _rootFilterType && childEntity.entity_type != AttributeColumnInfo.ENTITY_COLUMN)
					{
						//trace('filter',_rootFilterType,'removed',childEntity.id,'(type',childEntity.entity_type,')');
						continue;
					}
				}
				
				var child:EntityNode = _childNodeCache[childId];
				
				if (!child)
					_childNodeCache[childId] = child = new EntityNode();
				
				// set id whether or not it's a new child
				child.id = childId;
				
				_childNodes[outputIndex] = child;
				outputIndex++;
			}
			_childNodes.length = outputIndex;
			
			if (entity.entity_type == AttributeColumnInfo.ENTITY_COLUMN && _childNodes.length == 0)
				return null; // leaf node
			
			return _childCollectionView;
		}
		
		public static function addChildAt(parent:EntityNode, child:EntityNode, index:int):void
		{
			//TODO: handle index
			AdminInterface.instance.meta_cache.add_child(child.id, parent ? parent.id : MetadataCache.ROOT_ID);
		}
		public static function removeChild(parent:EntityNode, child:EntityNode):void
		{
			AdminInterface.instance.meta_cache.remove_child(child.id, parent ? parent.id : MetadataCache.ROOT_ID);
		}
    }
}
