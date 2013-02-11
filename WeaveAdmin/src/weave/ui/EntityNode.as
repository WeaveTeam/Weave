
package weave.ui
{
    import mx.collections.ArrayCollection;
    import mx.collections.ICollectionView;
    import mx.utils.StringUtil;
    
    import weave.api.data.ColumnMetadata;
    import weave.api.reportError;
    import weave.services.Admin;
    import weave.services.EntityCache;
    import weave.services.beans.Entity;
    import weave.services.beans.EntityMetadata;
    import weave.services.beans.EntityTableInfo;
    import weave.services.beans.EntityType;

	[RemoteClass]
    public class EntityNode
    {
		public static var debug:Boolean = false;
		
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
				return lang('Not logged in');
			
			var tableInfo:EntityTableInfo = Admin.entityCache.getDataTableInfo(id);
			if (tableInfo != null)
			{
				var tableTitle:String = tableInfo.title || lang("Untitled Table#{0}", tableInfo.id);
				
				// this is a table node, so avoid calling getEntity()
				var str:String = lang("{0} ({1})", tableTitle, tableInfo.numChildren);
				
				if (debug)
					str = lang("(Table#{0}) {1}", tableInfo.id, str);
				
				return str;
			}
			
			var entity:Entity = getEntity();
			
			var title:String = entity.publicMetadata[ColumnMetadata.TITLE];
			if (!title)
			{
				var name:String = entity.publicMetadata['name'];
				if (name)
					title = '[name: ' + name + ']';
			}
			
			if (!title)
			{
				if (entity.id == -1)
					title = '...';
				else
					title = lang("{0}#{1}", entity.getTypeString(), entity.id);
			}
			
			if (debug)
			{
				if (!title)
					title = '[untitled]';
				
				var typeStr:String = entity.getTypeString();
				var childrenStr:String = '';
				if (entity.type != Entity.TYPE_COLUMN)
					childrenStr = '; ' + children.length + ' children';
				var idStr:String = '(' + typeStr + "#" + id + childrenStr + ') ' + debugId(this);
				title = idStr + ' ' + title;
			}
			
			return title;
		}
		
		public function isBranch():Boolean
		{
			// root is a branch
			if (_rootFilterType >= 0)
				return true;
			
			// tables are branches
			if (Admin.entityCache.getDataTableInfo(id))
				return true;
			
			var entity:Entity = Admin.entityCache.getEntity(id);
			
			// columns are leaf nodes
			if (entity.type == Entity.TYPE_COLUMN)
				return false;
			
			// treat entities that haven't downloaded yet as leaf nodes
			return entity.childIds != null;
		}
		
		public function get children():ICollectionView
		{
			var childIds:Array;
			if (_rootFilterType == Entity.TYPE_TABLE)
			{
				childIds = Admin.entityCache.getDataTableIds();
			}
			else
			{
				var entity:Entity = Admin.entityCache.getEntity(id);
				childIds = entity.childIds;
				if (entity.type == Entity.TYPE_COLUMN)
					return null; // leaf node
			}
			
			if (!childIds || !Admin.instance.userHasAuthenticated)
			{
				_childNodes.length = 0;
				return isBranch() ? _childCollectionView : null;
			}
			
			var outputIndex:int = 0;
			for (var i:int = 0; i < childIds.length; i++)
			{
				var childId:int = childIds[i];
				
				// if there is a filter type, filter out non-column entities that do not have that type
				if (_rootFilterType >= 0 && _rootFilterType != Entity.TYPE_TABLE)
				{
					var childEntity:Entity = Admin.entityCache.getEntity(childId);
					if (childEntity.type != _rootFilterType && childEntity.type != Entity.TYPE_COLUMN)
					{
						//trace('filter',_rootFilterType,'removed',childEntity.id,'(type',childEntity.entity_type,')');
						continue;
					}
				}
				
				var child:EntityNode = _childNodeCache[childId] as EntityNode;
				if (!child)
				{
					child = new EntityNode();
					child.id = childId;
					_childNodeCache[childId] = child;
				}
				
				if (child.id != childId)
				{
					reportError("BUG: EntityNode id has changed since it was first cached");
					child.id = childId;
				}
				
				_childNodes[outputIndex] = child;
				outputIndex++;
			}
			_childNodes.length = outputIndex;
			
			return _childCollectionView;
		}
		
		public function toString():String
		{
			return label;
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
