package weave.ui
{
    import mx.controls.treeClasses.ITreeDataDescriptor;
    import mx.collections.ICollectionView;
    import mx.collections.ListCollectionView;
    import mx.collections.ArrayList;
    import weave.services.MetadataCache;
    import weave.services.beans.AttributeColumnInfo;
    
    public class HierarchyDescriptor implements ITreeDataDescriptor
    {
        public function HierarchyDescriptor()
        {
        }
        public function addChildAt(parent:Object, newChild:Object, index:int, model:Object = null):Boolean
        {

            var parentEntity:EntityTreeNode = parent as EntityTreeNode;
            if (parentEntity != null && newChild != null)
                parentEntity.add_child(newChild._id);
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
            return entityNode.object != null && entityNode.object.entity_type != AttributeColumnInfo.COLUMN;
        }
    }
}
