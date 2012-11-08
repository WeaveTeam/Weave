package weave.ui
{
    import mx.collections.ArrayList;
    import mx.collections.ICollectionView;
    import mx.collections.ListCollectionView;
    import mx.controls.treeClasses.ITreeDataDescriptor;
    
    import weave.services.beans.Entity;
    
    public class HierarchyDescriptor implements ITreeDataDescriptor
    {
        public function HierarchyDescriptor()
        {
        }
        public function addChildAt(parent:Object, newChild:Object, index:int, model:Object = null):Boolean
        {
			if (!parent)
			{
				weaveTrace('HierarchyDescriptor.addChildAt(): parent is null, so using root');
				parent = (model as ListCollectionView).getItemAt(0);
			}

            var parentEntity:EntityTreeNode = new EntityTreeNode(parent._id);
            var childEntity:EntityTreeNode = new EntityTreeNode(newChild._id);
            if (parentEntity != null && newChild != null)
            {
                parentEntity.add_child(childEntity.id);
            }
            return parentEntity != null && newChild != null;
        }
        public function removeChildAt(parent:Object, child:Object, index:int, model:Object = null):Boolean
        {
            var parentEntity:EntityTreeNode = parent as EntityTreeNode;
            if (parentEntity != null) 
                parentEntity.remove_child(child._id);
            return parentEntity != null;
        }
        public function getChildren(node:Object, model:Object = null):ICollectionView
        {
            var entityNode:EntityTreeNode = node as EntityTreeNode;
            var list:ArrayList = new ArrayList(entityNode.children);
            return new ListCollectionView(list);
        }
        public function hasChildren(node:Object, model:Object = null):Boolean
        {
            var entityNode:EntityTreeNode = node as EntityTreeNode;
            return entityNode.children != null && entityNode.children.length > 0;
        }
        public function getData(node:Object, model:Object = null):Object
        {
            var entityNode:EntityTreeNode = node as EntityTreeNode;
            return entityNode.object;
        }
        public function isBranch(node:Object, model:Object = null):Boolean
        {
            var entityNode:EntityTreeNode = node as EntityTreeNode;
            return entityNode.object != null && entityNode.object.type != Entity.TYPE_COLUMN;
        }
    }
}
