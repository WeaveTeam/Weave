package weave.ui
{
    import mx.collections.ICollectionView;
    import mx.controls.treeClasses.ITreeDataDescriptor;
    
    import weave.services.EntityCache;
    
	/**
	 * @author adufilie
	 */
    public class EntityTreeDataDescriptor implements ITreeDataDescriptor
    {
        public function addChildAt(parent:Object, newChild:Object, index:int, model:Object = null):Boolean
        {
			var parentNode:EntityNode = parent as EntityNode;
			var childNode:EntityNode = newChild as EntityNode;
			if (childNode)
			{
				if (parentNode && parentNode.getEntityCache() != childNode.getEntityCache())
					return false;
				childNode.getEntityCache().add_child(parentNode ? parentNode.id : EntityCache.ROOT_ID, childNode.id, index);
				return true;
			}
			return false;
        }
        public function removeChildAt(parent:Object, child:Object, index:int, model:Object = null):Boolean
        {
			var parentNode:EntityNode = parent as EntityNode;
			var childNode:EntityNode = child as EntityNode;
			if (childNode)
			{
				if (parentNode && parentNode.getEntityCache() != childNode.getEntityCache())
					return false;
				childNode.getEntityCache().remove_child(parentNode ? parentNode.id : EntityCache.ROOT_ID, childNode.id);
			}
			return true;
        }
        public function getChildren(node:Object, model:Object = null):ICollectionView
        {
			return (node as EntityNode).children;
        }
        public function hasChildren(node:Object, model:Object = null):Boolean
        {
			var children:ICollectionView = getChildren(node, model);
			return children != null;
        }
        public function getData(node:Object, model:Object = null):Object
        {
			return node as EntityNode;
        }
        public function isBranch(node:Object, model:Object = null):Boolean
        {
			return (node as EntityNode).isBranch();
        }
    }
}
