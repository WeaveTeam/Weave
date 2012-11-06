package weave.ui
{
    import mx.collections.ICollectionView;
    import mx.controls.treeClasses.ITreeDataDescriptor;
    
    public class EntityTreeDataDescriptor implements ITreeDataDescriptor
    {
        public function EntityTreeDataDescriptor()
        {
        }
		
		/*********************************
		 * ITreeDataDescriptor interface *
		 *********************************/
		
        public function addChildAt(parent:Object, newChild:Object, index:int, model:Object = null):Boolean
        {
			EntityNode.addChildAt(parent as EntityNode, newChild as EntityNode, index);
			return true;
        }
        public function removeChildAt(parent:Object, child:Object, index:int, model:Object = null):Boolean
        {
			EntityNode.removeChild(parent as EntityNode, child as EntityNode);
			return true;
        }
        public function getChildren(node:Object, model:Object = null):ICollectionView
        {
			return (node as EntityNode).childCollectionView;
        }
        public function hasChildren(node:Object, model:Object = null):Boolean
        {
			return (node as EntityNode).children != null;
        }
        public function getData(node:Object, model:Object = null):Object
        {
			return node as EntityNode;
        }
        public function isBranch(node:Object, model:Object = null):Boolean
        {
			var children:Array = (node as EntityNode).children;
			return children && children.length > 0;
        }
    }
}
