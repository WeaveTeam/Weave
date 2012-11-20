
package weave.ui
{
    import mx.collections.ArrayCollection;
    import mx.collections.ICollectionView;
    import mx.utils.StringUtil;
    
    import weave.api.data.ColumnMetadata;
    import weave.services.Admin;
    import weave.services.EntityCache;
    import weave.services.beans.Entity;
    import weave.services.beans.EntityTableInfo;

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
		
		public function getEntity():Entity
		{
			return Admin.entityCache.getEntity(id);
		}
		
		// the node can re-use the same children array
		private const _childNodes:Array = [];
		private const _childCollectionView:ICollectionView = new ArrayCollection(_childNodes);
		
		// We cache child nodes to avoid creating unnecessary objects.
		// Each node must have its own child cache (not static) because we can't have the same node in two places in a Tree.
		private const _childNodeCache:Object = {}; // id -> EntityNode
		
		public function get label():String
		{
			if (!Admin.instance.userHasAuthenticated)
				return 'Not logged in';
			
			var tableInfo:EntityTableInfo = Admin.entityCache.getDataTableInfo(id);
			if (tableInfo != null)
			{
				// this is a table node, so avoid calling getEntity()
				return StringUtil.substitute("{0} ({1})", tableInfo.title, tableInfo.numChildren);
			}
			
			var info:Entity = getEntity();
			
			var title:String = info.publicMetadata[ColumnMetadata.TITLE];
			if (!title)
				title = '[name: ' + info.publicMetadata['name'] + ']';
			if (!title)
				title = '[untitled]';
				
			if (debug)
			{
				var typeStrs:Array = ['Hierarchy','Table','Column','Category'];
				var typeInts:Array = [Entity.TYPE_HIERARCHY, Entity.TYPE_TABLE, Entity.TYPE_COLUMN, Entity.TYPE_CATEGORY];
				var typeInt:int = info.type;
				var typeStr:String = typeStrs[typeInts.indexOf(typeInt)];
				var childrenStr:String = '';
				if (typeInt != Entity.TYPE_COLUMN)
					childrenStr = '; ' + _childNodes.length + ' children';
				var idStr:String = '(' + typeStr + "#" + id + childrenStr + ') ' + debugId(this);
				title = idStr + ' ' + title;
			}
			
			return title;
		}
		
		public function get children():ICollectionView
		{
			if (!Admin.instance.userHasAuthenticated)
				return null;
			
			var childIds:Array;
			var type:int = _rootFilterType;
			if (type == Entity.TYPE_TABLE)
			{
				childIds = Admin.entityCache.getDataTableIds();
			}
			else
			{
				var entity:Entity = Admin.entityCache.getEntity(id);
				type = entity.type;
				childIds = entity.childIds;
			}
			
			if (!childIds)
				return null;
			
			var outputIndex:int = 0;
			for (var i:int = 0; i < childIds.length; i++)
			{
				var childId:int = childIds[i];
				
				// if there is a filter type, filter out non-column entities that do not have that type
				if (_rootFilterType >= 0)
				{
					var childEntity:Entity = Admin.entityCache.getEntity(childId);
					if (childEntity.type != _rootFilterType && childEntity.type != Entity.TYPE_COLUMN)
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
			
			if (type == Entity.TYPE_COLUMN && _childNodes.length == 0)
				return null; // leaf node
			
			return _childCollectionView;
		}
		
		public static function addChildAt(parent:EntityNode, child:EntityNode, index:int):void
		{
			Admin.entityCache.add_child(parent ? parent.id : EntityCache.ROOT_ID, child.id, index);
		}
		public static function removeChild(parent:EntityNode, child:EntityNode):void
		{
			Admin.entityCache.remove_child(parent ? parent.id : EntityCache.ROOT_ID, child.id);
		}
    }
}
