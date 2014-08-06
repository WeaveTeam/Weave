package weave.data.DataSources
{
    import flare.data.converters.GraphMLConverter;
    
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.utils.Dictionary;
    
    import mx.rpc.events.FaultEvent;
    import mx.rpc.events.ResultEvent;
    
    import weave.api.data.ColumnMetadata;
    import weave.api.data.IAttributeColumn;
    import weave.api.data.IColumnReference;
    import weave.api.data.IDataSource;
    import weave.api.data.IQualifiedKey;
    import weave.api.data.IWeaveTreeNode;
    import weave.api.data.DataType;
    import weave.api.newLinkableChild;
    import weave.api.reportError;
    import weave.core.LinkableString;
    import weave.data.AttributeColumns.ProxyColumn;
    import weave.data.AttributeColumns.StringColumn;
    import weave.data.AttributeColumns.NumberColumn;
    import weave.data.QKeyManager;
    import weave.utils.VectorUtils;

    public class GraphMLDataSource extends AbstractDataSource
    {
        WeaveAPI.registerImplementation(IDataSource, GraphMLDataSource, "GraphML file");

        
        public static const GRAPH_ID_META:String = "__GraphElementProperty__";        
        public static const GRAPH_GROUP_META:String = "__GraphGroup__";

        public const sourceUrl:LinkableString = newLinkableChild(this, LinkableString, handleURLChange);

        private var nodeColumnData:Array = null;
        private var edgeColumnData:Array = null;

        public var nodeSchema:Object = null;
        public var nodeProperties:Array = null;

        public var edgeSchema:Object = null;
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
            
            if (metadata[GRAPH_GROUP_META] === undefined)
                return graphNode;

            groupNode = new GraphMLGroupNode(graphNode, metadata[GRAPH_GROUP_META]);

            if (metadata[GRAPH_ID_META] === undefined)
                return groupNode;

            columnNode = new GraphMLColumnNode(groupNode, metadata[GRAPH_ID_META]);
            
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
            
            nodeSchema = result.nodeSchema;
            nodeProperties = result.nodeKeys;

            nodeColumnData = result.nodes;
            handleNodeKeyPropertyChange();

            edgeSchema = result.edgeSchema;
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

        public function getColumnMetadata(group:String, id:String):Object
        {
            var metadata:Object = {};
            var is_node:Boolean = group == GraphMLConverter.NODE;

            var data_type:String = is_node ? nodeSchema[id].type : edgeSchema[id].type;

            var name:String = is_node ? nodeSchema[id].name : edgeSchema[id].name;

            var key_type:String = is_node ? nodeKeyType.value : edgeKeyType.value;

            /* If we're looking at an edge's source or target properties, we want the data_type to be set to the key_type of the nodes. */
            if (!is_node && (id == GraphMLConverter.SOURCE || id == GraphMLConverter.TARGET))
            {
                data_type = nodeKeyType.value;
            }
            else
            {
                if (data_type == GraphMLConverter.ATTRTYPE_DOUBLE || 
                    data_type == GraphMLConverter.ATTRTYPE_INT ||
                    data_type == GraphMLConverter.ATTRTYPE_FLOAT || 
                    data_type == GraphMLConverter.ATTRTYPE_LONG)
                {
                    data_type = DataType.NUMBER;
                }
                else
                {
                    data_type = DataType.STRING;
                }
            }

            metadata[GRAPH_GROUP_META] = group;
            metadata[GRAPH_ID_META] = id;
            metadata[ColumnMetadata.TITLE] = name;
            metadata[ColumnMetadata.DATA_TYPE] = data_type;
            metadata[ColumnMetadata.KEY_TYPE] = key_type;

            return metadata;
        }


        override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void 
        {
            var metadata:Object = proxyColumn.getProxyMetadata();

            metadata = getColumnMetadata(metadata[GRAPH_GROUP_META], metadata[GRAPH_ID_META]);

            var raw_rows:Array;
            var data_remap_src:Object = null;
            var key_remap_src:Object = null;
            var schema:Object = null;

            var id:String = metadata[GRAPH_ID_META];
            var key_type:String = metadata[ColumnMetadata.KEY_TYPE];
            var data_type:String = metadata[ColumnMetadata.DATA_TYPE]
            
            if (metadata[GRAPH_GROUP_META] == GraphMLConverter.NODE)
            {
                raw_rows = nodeColumnData;

                key_remap_src = nodeIdToKey;

                schema = nodeSchema;
            }
            else if (metadata[GRAPH_GROUP_META] == GraphMLConverter.EDGE)
            {
                raw_rows = edgeColumnData;

                data_remap_src = (id == GraphMLConverter.SOURCE ||
                                  id == GraphMLConverter.TARGET) ? nodeIdToKey : null;

                key_remap_src = edgeIdToKey;

                schema = edgeSchema;
            }

            if (!raw_rows) return;

            var data_column:Array = getPropertyArray(raw_rows, id, data_remap_src, schema[id].def);
            var key_column:Array = getPropertyArray(raw_rows, GraphMLConverter.ID, key_remap_src, null);

            var key_vector:Vector.<IQualifiedKey> = new Vector.<IQualifiedKey>(key_column.length);

            function setRecordsNumber():void
            {
                var data_vector:Vector.<Number> = new Vector.<Number>(data_column.length);
                var new_column:IAttributeColumn;
                new_column = new NumberColumn(metadata);

                for (var idx:int = data_vector.length - 1; idx >= 0; idx--)
                {
                    data_vector[idx] = Number(data_column[idx]);
                }

                (new_column as NumberColumn).setRecords(key_vector, data_vector);
                proxyColumn.setInternalColumn(new_column);
            }

            function setRecordsString():void
            {
                var data_vector:Vector.<String> = new Vector.<String>(data_column.length);
                var new_column:IAttributeColumn;
                new_column = new StringColumn(metadata);

                for (var idx:int = data_vector.length - 1; idx >= 0; idx--)
                {
                    data_vector[idx] = data_column[idx];
                }

                (new_column as StringColumn).setRecords(key_vector, data_vector);
                proxyColumn.setInternalColumn(new_column);
            }

            var setRecords:Function = setRecordsString;

            if (data_type == DataType.NUMBER) setRecords = setRecordsNumber;

            (WeaveAPI.QKeyManager as QKeyManager).getQKeysAsync(key_type, key_column, proxyColumn, setRecords, key_vector);
        }

        private static function getPropertyArray(objects:Array, property:String, mapping:Object, def:String):Array
        {
            var output:Array = VectorUtils.pluck(objects, property);

            if (mapping) output = output.map(function(d:String,i:int,a:Array):String {return mapping[d];});
            if (def) output = output.map(function(d:String,i:int,a:Array):String {return d ? d : def;});

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

    public function get columnSchema():Object
    {
        return isNodeGroup() ? graph.source.nodeSchema : graph.source.edgeSchema;
    }
    
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
        if (children == null)
        {
            children = [];

            var columns:Array = isNodeGroup() ? 
                    graph.source.nodeProperties :
                    graph.source.edgeProperties;
			
			for each (var id:String in columns)
                children.push(new GraphMLColumnNode(this, id));
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
    private var _id:String;

    public function get parent():GraphMLGroupNode
    {
        return _parent;
    }

    public function get group():GraphMLGroupNode
    {
        return _parent as GraphMLGroupNode;
    }
    public function get id():String
    {
        return _id;
    }

    public function GraphMLColumnNode(parent:GraphMLGroupNode, id:String)
    {
        this._parent = parent;
        this._id = id;
    }

    public function equals(other:IWeaveTreeNode):Boolean
    {
        var that:GraphMLColumnNode = other as GraphMLColumnNode;
        return !!that &&
                 this.parent.equals(that.parent) &&
                 this.id == that.id;
    }

    public function isBranch():Boolean { return false; }
    public function hasChildBranches():Boolean { return false; }
    public function getChildren():Array { return null; }

    public function getLabel():String
    {
        if (id == GraphMLConverter.ID)
            return "GraphML Element ID";
        else
            return parent.columnSchema[id].name + " (" + id + ")";
    }

    public function getDataSource():IDataSource 
    {
        return parent.graph.source;
    }
    
    public function getColumnMetadata():Object 
    {   
        return parent.graph.source.getColumnMetadata(group.group, id);
    }
}