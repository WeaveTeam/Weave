package weave.data.DataSources
{
    import flare.data.converters.GraphMLConverter;
    
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    
    import mx.rpc.events.FaultEvent;
    import mx.rpc.events.ResultEvent;
    
    import weave.api.data.ColumnMetadata;
    import weave.api.data.IAttributeColumn;
    import weave.api.data.IColumnReference;
    import weave.api.data.IDataSource;
    import weave.api.data.IQualifiedKey;
    import weave.api.data.IWeaveTreeNode;
    import weave.api.newLinkableChild;
    import weave.api.reportError;
    import weave.core.LinkableString;
    import weave.data.AttributeColumns.ProxyColumn;
    import weave.data.AttributeColumns.StringColumn;
    import weave.data.QKeyManager;

    public class GraphMLDataSource extends AbstractDataSource
    {
        WeaveAPI.registerImplementation(IDataSource, GraphMLDataSource, "GraphML file");

        
        public static const COLUMNNAME_META:String = "__GraphElementProperty__";
        public static const FILTERVALUE_META:String = "__GraphFilterValue__";
        public static const FILTERCOLUMN_META:String = "__GraphFilterColumn__";
        public static const GROUP_META:String = "__GraphGroup__";

        public const sourceUrl:LinkableString = newLinkableChild(this, LinkableString, handleURLChange);

        private var nodeColumnData:Array = null;
        private var edgeColumnData:Array = null;

        public var nodeProperties:Array = null;
        public var edgeProperties:Array = null;

        public const nodeKeyType:LinkableString = newLinkableChild(this, LinkableString);
        public const edgeKeyType:LinkableString = newLinkableChild(this, LinkableString);

        public const nodeKeyPropertyName:LinkableString = newLinkableChild(this, LinkableString, handleNodeKeyPropertyChange);
        public const edgeKeyPropertyName:LinkableString = newLinkableChild(this, LinkableString, handleEdgeKeyPropertyChange);

        public var nodeIdToKey:Object = null;
        public var edgeIdToKey:Object = null;

        public var onFinish:Function = null;

        [Bindable] public var nodeKeyPropertyValid:Boolean;
        [Bindable] public var edgeKeyPropertyValid:Boolean;

        public function GraphMLDataSource()
        {
        }






        /* Overrides from AbstractDataSource */

        override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
        {
            var graphNode:GraphMLGraphNode;
            var groupNode:GraphMLGroupNode;
            var columnNode:GraphMLColumnNode;

            graphNode = new GraphMLGraphNode(this);
            
            if (metadata[GROUP_META] === undefined)
                return graphNode;

            groupNode = new GraphMLGroupNode(graphNode, metadata[GROUP_META]);

            if (metadata[COLUMNNAME_META] === undefined)
                return groupNode;

            columnNode = new GraphMLColumnNode(groupNode, metadata[COLUMNNAME_META]);
            
            return columnNode;
        }

        private function handleURLChange():void
        {
            WeaveAPI.URLRequestUtils.getURL(this, new URLRequest(sourceUrl.value), handleGraphMLDownload, handleGraphMLDownloadError, sourceUrl.value, URLLoaderDataFormat.TEXT);
            return;
        }

        private function handleGraphMLDownload(event:ResultEvent, token:Object = null):void
        {
            var result:Object = GraphMLConverter.read(String(event.result));
            
            nodeProperties = result.nodeKeys;
            nodeColumnData = result.nodes;
            handleNodeKeyPropertyChange();

            edgeProperties = result.edgeKeys;
            edgeColumnData = result.edges;
            handleEdgeKeyPropertyChange();

            refreshAllProxyColumns();
            refreshHierarchy();

            if (onFinish != null) 
            {
                onFinish()
                onFinish = null;
            }
        }

        private function handleGraphMLDownloadError(event:FaultEvent, token:Object = null):void
        {
            reportError(event);
        }

        override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void 
        {
            var metadata:Object = proxyColumn.getProxyMetadata();
            var raw_rows:Array;
            var data_remap_src:Object = null;
            var key_remap_src:Object = null;
            var keyType:String;
            var filter_value:String = null;
            
            if (metadata[GROUP_META] == GraphMLConverter.NODE)
            {
                raw_rows = nodeColumnData;

                key_remap_src = nodeIdToKey;

                keyType = nodeKeyType.value;
            }
            else if (metadata[GROUP_META] == GraphMLConverter.EDGE)
            {
                raw_rows = edgeColumnData;

                data_remap_src = (metadata[COLUMNNAME_META] == GraphMLConverter.SOURCE ||
                                 metadata[COLUMNNAME_META] == GraphMLConverter.TARGET) ? nodeIdToKey : null;

                if (data_remap_src)
                    metadata[ColumnMetadata.DATA_TYPE] = nodeKeyType.value;

                key_remap_src = edgeIdToKey;

                keyType = edgeKeyType.value;
            }

            if (!raw_rows) return;

            var data_column:Array = getPropertyArray(raw_rows, metadata[COLUMNNAME_META], data_remap_src);
            var key_column:Array = getPropertyArray(raw_rows, GraphMLConverter.ID, key_remap_src);
            
            if (!metadata[ColumnMetadata.KEY_TYPE])
            {
                metadata[ColumnMetadata.KEY_TYPE] = keyType;
            }

            if (!metadata[ColumnMetadata.TITLE])
            {
                metadata[ColumnMetadata.TITLE] = metadata[COLUMNNAME_META];    
            }
            
            /* TODO: Add type autodetection and proper handling of numeric types. */

            var key_vector:Vector.<IQualifiedKey> = new Vector.<IQualifiedKey>(key_column.length);
            var data_vector:Vector.<String> = new Vector.<String>(data_column.length);

            function setRecords():void
            {
                    var new_column:IAttributeColumn;
                    new_column = new StringColumn(metadata);

                    for (var idx:int = data_vector.length - 1; idx >= 0; idx--)
                    {
                        data_vector[idx] = data_column[idx];
                    }

                    (new_column as StringColumn).setRecords(key_vector, data_vector);
                    proxyColumn.setInternalColumn(new_column);
            }

            (WeaveAPI.QKeyManager as QKeyManager).getQKeysAsync(keyType, key_column, proxyColumn, setRecords, key_vector);
        }

        private static function getPropertyArray(objects:Array, property:String, mapping:Object):Array
        {
            var output:Array = new Array(objects.length);
            for (var idx:int = objects.length - 1; idx >= 0; idx--)
            {
                if (mapping)
                {
                    output[idx] = mapping[objects[idx][property]];
                }
                else
                {
                    output[idx] = objects[idx][property];
                }
            }
            return output;
        }
        
        /* Implements from IDataSource */

        override public function getHierarchyRoot():IWeaveTreeNode
        {
            if (!(_rootNode is GraphMLGraphNode))
            {
                _rootNode = new GraphMLGraphNode(this);
            }

            return _rootNode;
        }

        /* Local logic */

        private function handleNodeKeyPropertyChange():void
        {
            var propertyName:String = nodeKeyPropertyName.value;
            nodeIdToKey = {};

            if (!nodeColumnData || !propertyName || propertyName == "")
            {
                nodeIdToKey = null;
                nodeKeyPropertyValid = true;
                return;
            }
            
            if (!handleKeyPropertyChange(nodeColumnData, propertyName, nodeIdToKey))
            {
                nodeIdToKey = null;
                nodeKeyPropertyValid = false;
            }

            nodeKeyPropertyValid = true;
            
            return;
        }

        private function handleEdgeKeyPropertyChange():void
        {
            var propertyName:String = edgeKeyPropertyName.value;
            edgeIdToKey = {};

            if (!edgeColumnData || !propertyName || propertyName == "")
            {
                edgeIdToKey = null;
                edgeKeyPropertyValid = true;
                return;
            }
            
            if (!handleKeyPropertyChange(edgeColumnData, propertyName, edgeIdToKey))
            {
                edgeIdToKey = null;
                edgeKeyPropertyValid = false;
            }

            edgeKeyPropertyValid = true;

            return;
        }

        private function handleKeyPropertyChange(data:Array, property:String, idToKeyMappings:Object):Boolean
        {
            var idx:int;
            var id:String;
            var value:String;
            var keyToIdMappings:Object = {};

            for (idx = data.length - 1; idx >= 0; idx--)
            {
                value = data[idx][property];
                id = data[idx][GraphMLConverter.ID];
                if (keyToIdMappings[value] !== undefined) 
                {
                    return false;
                    weaveTrace("Duplicate key:", value);
                }
                keyToIdMappings[value] = id;
                idToKeyMappings[id] = value;
            }            
            return true;
        }
    }
}

import flare.data.converters.GraphMLConverter;

import weave.api.data.ColumnMetadata;
import weave.api.data.IColumnReference;
import weave.api.data.IDataSource;
import weave.api.data.IWeaveTreeNode;
import weave.data.DataSources.GraphMLDataSource;

internal class GraphMLGraphNode implements IWeaveTreeNode
{
    private var _source:GraphMLDataSource;
    private var children:Array = null;

    public function get source():GraphMLDataSource
    {
        return _source;
    }
    public function GraphMLGraphNode(source:GraphMLDataSource)
    {
        this._source = source;
    }

    public function equals(other:IWeaveTreeNode):Boolean
    {
        var that:GraphMLGraphNode = other as GraphMLGraphNode;
        return !!that && this.source == that.source;
    }
    
    public function hasChildBranches():Boolean {return true;}

    public function isBranch():Boolean {return true;}
    
    public function getChildren():Array
    {
        if (children == null)
        {
            children = 
            [
                new GraphMLGroupNode(this, GraphMLConverter.NODE),
                new GraphMLGroupNode(this, GraphMLConverter.EDGE)
            ];
        }
        return children;
    }

    public function getLabel():String
    {
        return WeaveAPI.globalHashMap.getName(source);
    }
}

internal class GraphMLGroupNode implements IWeaveTreeNode 
{
    private var _graph:GraphMLGraphNode;
    private var _group:String;
    private var children:Array = null;
    
    public function get group():String
    {
        return _group;
    }

    public function get graph():GraphMLGraphNode
    {
        return _graph;
    }

    public function GraphMLGroupNode(graph:GraphMLGraphNode, group:String)
    {
        _graph = graph;
        _group = group;
    }

    public function isNodeGroup():Boolean
    {
        return GraphMLConverter.NODE == group; 
    }

    public function equals(other:IWeaveTreeNode):Boolean
    {
        var that:GraphMLGroupNode = other as GraphMLGroupNode;
        return !!that && 
                this.graph.equals(that.graph) &&
                this.group == that.group;
    }

    public function isBranch():Boolean { return true; }

    public function hasChildBranches():Boolean { return false; }

    public function getChildren():Array 
    {
        var idx:int;
        if (children == null)
        {
            children = [];

            var columns:Array = isNodeGroup() ? 
                    graph.source.nodeProperties :
                    graph.source.edgeProperties;

            for (idx = columns.length - 1; idx >= 0; idx--)
            {
                children.push(new GraphMLColumnNode(this, columns[idx]));
            }
        }
        return children;
    }
    public function getLabel():String
    {
        return isNodeGroup() ? lang("Nodes") : lang("Edges");
    }
}

internal class GraphMLColumnNode implements IWeaveTreeNode, IColumnReference {
    private var _parent:GraphMLGroupNode;
    private var _columnName:String;

    public function get parent():GraphMLGroupNode
    {
        return _parent;
    }

    public function get group():GraphMLGroupNode
    {
        return _parent as GraphMLGroupNode;
    }
    public function get columnName():String
    {
        return _columnName;
    }

    public function GraphMLColumnNode(parent:GraphMLGroupNode, columnName:String)
    {
        this._parent = parent;
        this._columnName = columnName;
    }

    public function equals(other:IWeaveTreeNode):Boolean
    {
        var that:GraphMLColumnNode = other as GraphMLColumnNode;
        return !!that &&
                 this.parent.equals(that.parent) &&
                 this.columnName == that.columnName;
    }

    public function isBranch():Boolean { return false; }
    public function hasChildBranches():Boolean { return false; }
    public function getChildren():Array { return null; }

    public function getLabel():String
    {
        return columnName;
    }

    public function getDataSource():IDataSource 
    {
        return parent.graph.source;
    }
    
    public function getColumnMetadata():Object 
    {
        var metadata:Object = {};

        metadata[GraphMLDataSource.COLUMNNAME_META] = columnName;
        metadata[GraphMLDataSource.GROUP_META] = group.group;
        

        return metadata;
    }
}