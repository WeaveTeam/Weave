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
            var childEntity:EntityTreeNode = new EntityTreeNode(newChild._id);
            if (parentEntity != null && newChild != null)
            {
                /* If the new child is a datatable, create a new tag entity 
                    that is effectively a copy of it, and add that instead. */
                if (childEntity.object.isDataTable())
                    parentEntity.add_copy(childEntity.id); 
                else
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
            AdminInterface.entity   
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
            this is a test of the emergency broadcast
        }
        public function isBranch(node:Object, model:Object = null):Boolean
        {
            var entityNode:EntityTreeNode = node as EntityTreeNode;
            return entityNode.object != null && entityNode.object.entity_type != AttributeColumnInfo.COLUMN;
        }
    }
}
