package weave.data.Transforms
{
    import weave.api.core.ILinkableHashMap;
    import weave.api.data.ColumnMetadata;
    import weave.api.data.IAttributeColumn;
    import weave.api.data.IColumnReference;
    import weave.api.data.IDataSource;
    import weave.api.data.IWeaveTreeNode;
    import weave.api.newLinkableChild;
    import weave.api.registerLinkableChild;
    import weave.core.LinkableHashMap;
    import weave.data.AttributeColumns.DynamicColumn;
    import weave.data.AttributeColumns.FilteredColumn;
    import weave.data.AttributeColumns.ProxyColumn;
    import weave.data.DataSources.AbstractDataSource;
    import weave.data.KeySets.StringDataFilter;
    import weave.utils.VectorUtils;

    public class PartitionDataTransform extends AbstractDataSource
    {
        public static const PARTITION_VALUE_META:String = "__PartitionValue__";
        public static const PARTITION_COLUMNNAME_META:String = "__PartitionColumnName__";
        WeaveAPI.registerImplementation(IDataSource, PartitionDataTransform, "Partitioned Table");

        public const inputColumns:ILinkableHashMap = registerLinkableChild(this, new LinkableHashMap(IAttributeColumn), inputColumnsChanged);
        public const partitionColumn:DynamicColumn = newLinkableChild(this, DynamicColumn, partitionColumnChanged);
        
        public var layer_names:Array = [];        

        public function PartitionDataTransform()
        {

        }

        public function inputColumnsChanged():void
        {
            refreshHierarchy();
            refreshAllProxyColumns();
        }

        private function partitionColumnChanged():void
        {
            var keys:Array = partitionColumn.keys;
            var layers:Object = {};
            for (var idx:int = keys.length - 1; idx >= 0; idx--)
            {
                var value:String = partitionColumn.getValueFromKey(keys[idx], String);
                
                layers[value] = true;
            }
            layer_names = VectorUtils.getKeys(layers);

            refreshHierarchy();
            refreshAllProxyColumns();
        }

        public function getInputColumnTitle(name:String):String
        {
            var column:IAttributeColumn = inputColumns.getObject(name) as IAttributeColumn;
            return column.getMetadata(ColumnMetadata.TITLE);
        }

        override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
        {
            var transformNode:PartitionTransformNode;
            var valueNode:PartitionValueNode;
            var columnNode:PartitionColumnNode;

            transformNode = new PartitionTransformNode(this);

            if (metadata[PARTITION_VALUE_META] === undefined)
                return transformNode;

            valueNode = new PartitionValueNode(transformNode, metadata[PARTITION_VALUE_META])

            if (metadata[PARTITION_COLUMNNAME_META] === undefined)
                return valueNode;

            return new PartitionColumnNode(valueNode, metadata[PARTITION_COLUMNNAME_META]);
        }

        override public function getHierarchyRoot():IWeaveTreeNode
        {
            if (!_rootNode)
                _rootNode = new PartitionTransformNode(this);
            return _rootNode;
        }

        override protected function requestHierarchyFromSource(subtreeNode:XML = null):void
        {
            // do nothing, as the hierarchy is known ahead of time.
            return;
        }

        override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
        {

            var metadata:Object = proxyColumn.getProxyMetadata();
            var columnName:String = metadata[PARTITION_COLUMNNAME_META];
            var value:String = metadata[PARTITION_VALUE_META];
            
            var column:IAttributeColumn = inputColumns.getObject(columnName) as IAttributeColumn;

            var newFilteredColumn:FilteredColumn = new FilteredColumn();
            var filter:StringDataFilter = newFilteredColumn.filter.requestLocalObject(StringDataFilter, false);

            filter.column.requestLocalObjectCopy(partitionColumn);
            filter.stringValue.value = value;

            newFilteredColumn.internalDynamicColumn.requestLocalObjectCopy(column);

            proxyColumn.setInternalColumn(newFilteredColumn);
        }
    }
}

import weave.api.data.ColumnMetadata;
import weave.api.data.IColumnReference;
import weave.api.data.IDataSource;
import weave.api.data.IWeaveTreeNode;
import weave.data.Transforms.PartitionDataTransform;

internal class PartitionTransformNode implements IWeaveTreeNode
{
    private var _source:PartitionDataTransform;
    private var children:Array;

    public function get source():PartitionDataTransform { return _source; }

    public function PartitionTransformNode(source:PartitionDataTransform)
    {
        _source = source;
    }

    public function equals(other:IWeaveTreeNode):Boolean
    {
        var that:PartitionTransformNode = other as PartitionTransformNode;
        return !!that && 
                that.source === this.source;
    }

    public function isBranch():Boolean { return true; }
    public function hasChildBranches():Boolean {return true; }

    public function getChildren():Array
    {
        if (children == null)
        {
            children = [];
            var layer_names:Array = source.layer_names;
            for (var idx:int = layer_names.length - 1; idx >= 0; idx--)
            {
                var layer:String = layer_names[idx];

                children.push(new PartitionValueNode(this, layer));
            }
        }
        return children;
    }

    public function getLabel():String
    {
        return WeaveAPI.globalHashMap.getName(source);
    }

}
internal class PartitionValueNode implements IWeaveTreeNode
{
    private var _parent:PartitionTransformNode;
    private var _partitionValue:String;
    private var children:Array;

    public function get parent():PartitionTransformNode { return _parent; }
    public function get partitionValue():String { return _partitionValue; }

    public function PartitionValueNode(parent:PartitionTransformNode, value:String)
    {
        _parent = parent;
        _partitionValue = value;
    }

    public function equals(other:IWeaveTreeNode):Boolean
    {
        var that:PartitionValueNode = other as PartitionValueNode;
        return !!that && 
                this.partitionValue == that.partitionValue &&
                that.parent.equals(this.parent);
    }

    public function isBranch():Boolean { return true; }
    public function hasChildBranches():Boolean { return false; }

    public function getChildren():Array
    {
        if (children == null)
        {
            children = [];
            var column_names:Array = parent.source.inputColumns.getNames();
            for (var idx:int = column_names.length - 1; idx >= 0; idx--)
            {
                children.push(new PartitionColumnNode(this, column_names[idx]));
            }
        }
        return children;
    }
    public function getLabel():String
    {
        return _partitionValue;
    }
}
internal class PartitionColumnNode implements IWeaveTreeNode, IColumnReference
{
    private var _parent:PartitionValueNode;
    private var _columnName:String;

    public function get parent():PartitionValueNode { return _parent; }
    public function get columnName():String { return _columnName; }

    public function PartitionColumnNode(parent:PartitionValueNode, columnName:String)
    {
        _parent = parent;
        _columnName = columnName;
    }

    public function equals(other:IWeaveTreeNode):Boolean
    {
        var that:PartitionColumnNode = other as PartitionColumnNode;
        return !!that &&
                this.columnName == that.columnName &&
                that.parent.equals(this.parent);
    }

    public function isBranch():Boolean {return false;}
    public function hasChildBranches():Boolean {return false;}
    public function getChildren():Array {return null; }

    public function getLabel():String
    {
        return parent.parent.source.getInputColumnTitle(_columnName) + 
                " (" + parent.partitionValue + ")";
    } 

    public function getDataSource():IDataSource
    {
        return parent.parent.source;
    }

    public function getColumnMetadata():Object
    {
        var metadata:Object = {};

        metadata[PartitionDataTransform.PARTITION_COLUMNNAME_META] = columnName;
        metadata[PartitionDataTransform.PARTITION_VALUE_META] = parent.partitionValue;

        return metadata;
    }
}