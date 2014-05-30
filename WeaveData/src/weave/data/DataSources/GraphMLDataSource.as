package weave.data.DataSources
{
    import flare.data.converters.GraphMLConverter;
    import weave.api.WeaveAPI;
    import weave.api.data.ColumnMetadata;
    import weave.api.data.DataTypes;
    import weave.api.data.IDataSource;
    import weave.api.data.IWeaveTreeNode;
    import weave.api.data.IColumnReference;
    import weave.api.data.IAttributeColumn;    
    import weave.api.data.IQualifiedKey; 
    import weave.api.getCallbackCollection;
    import weave.api.registerLinkableChild;
    import weave.api.newLinkableChild;
    import weave.compiler.Compiler;
    import weave.core.LinkableBoolean;
    import weave.core.LinkableNumber;
    import weave.core.LinkableString;
    import weave.core.LinkableVariable;
    import weave.core.SessionManager;
    import weave.data.AttributeColumns.ProxyColumn;
    import weave.data.AttributeColumns.StringColumn;
    import weave.data.AttributeColumns.NumberColumn;
    import weave.data.AttributeColumns.DateColumn;
    import weave.data.QKeyManager;
    import weave.core.ClassUtils;

    import weave.utils.VectorUtils;

    public class GraphMLDataSource extends AbstractDataSource
    {
        WeaveAPI.registerImplementation(IDataSource, GraphMLDataSource, "GraphML file");

        
        public static const COLUMNNAME_META:String = "__GraphElementProperty__";
        public static const FILTERVALUE_META:String = "__GraphFilterValue__";
        public static const FILTERCOLUMN_META:String = "__GraphFilterColumn__";
        public static const GROUP_META:String = "__GraphGroup__";

        public const sourceUrl:LinkableString = newLinkableChild(this, LinkableString);

        public const nodeColumnData:LinkableVariable = newLinkableChild(this, LinkableVariable, handleGraphMLNodesChange);
        public const edgeColumnData:LinkableVariable = newLinkableChild(this, LinkableVariable, handleGraphMLEdgesChange);

        public const nodeProperties:LinkableVariable = newLinkableChild(this, LinkableVariable, handleGraphMLNodesChange);
        public const edgeProperties:LinkableVariable = newLinkableChild(this, LinkableVariable, handleGraphMLEdgesChange);

        public const nodeKeyType:LinkableString = newLinkableChild(this, LinkableString);
        public const edgeKeyType:LinkableString = newLinkableChild(this, LinkableString);

        public const nodeKeyPropertyName:LinkableString = newLinkableChild(this, LinkableString, handleNodeKeyPropertyChange);
        public const edgeKeyPropertyName:LinkableString = newLinkableChild(this, LinkableString, handleEdgeKeyPropertyChange);

        public const nodeLayerPropertyName:LinkableString = newLinkableChild(this, LinkableString, handleNodeLayeringChange);
        public const edgeLayerPropertyName:LinkableString = newLinkableChild(this, LinkableString, handleEdgeLayeringChange);

        [Bindable] var nodeKeyIsValid:Boolean = false;

        /* Computed values */

        public var nodeLayers:Object = {};
        public var edgeLayers:Object = {};
        public var nodeLayerNames:Array = [];
        public var edgeLayerNames:Array = [];

        private var nodeKeyToId:Object = null;
        private var nodeIdToKey:Object = null;

        private var edgeKeyToId:Object = null;
        private var edgeIdToKey:Object = null;

        public function GraphMLDataSource()
        {

        }




        /* Overrides from AbstractDataSource */

        override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
        {
            var graphNode:GraphMLGraphNode;
            var groupNode:GraphMLGroupNode;
            var layerNode:GraphMLLayerNode;
            var columnNode:GraphMLColumnNode;

            graphNode = new GraphMLGraphNode(this);
            
            if (metadata[GROUP_META] === undefined)
                return graphNode;

            groupNode = new GraphMLGroupNode(graphNode, metadata[GROUP_META],  metadata[FILTERCOLUMN_META]);

            if (metadata[FILTERVALUE_META] === undefined)
                return groupNode; 

            layerNode = new GraphMLLayerNode(groupNode, metadata[FILTERVALUE_META]);

            if (metadata[COLUMNNAME_META] === undefined)
                return layerNode;

            columnNode = new GraphMLColumnNode(layerNode, metadata[COLUMNNAME_META]);

            return columnNode;
            
        }

        

        override protected function requestHierarchyFromSource(subtreeNode:XML = null):void 
        {
            // do nothing, as the hierarchy is known ahead of time much like CSVDataSource
            return;
        }
        override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void 
        {
            var metadata:Object = proxyColumn.getProxyMetadata();
            var raw_rows:Array;
            var data_remap_src:Object = null;
            var key_remap_src:Object = null;
            var keyType:String;
            
            if (metadata[GROUP_META] == GraphMLConverter.NODE)
            {
                raw_rows = (nodeColumnData.getSessionState() as Array);

                key_remap_src = nodeIdToKey;

                keyType = nodeKeyType.value;
            }
            else if (metadata[GROUP_META] == GraphMLConverter.EDGE)
            {
                raw_rows = (edgeColumnData.getSessionState() as Array);

                data_remap_src = (metadata[COLUMNNAME_META] == GraphMLConverter.SOURCE ||
                                 metadata[COLUMNNAME_META] == GraphMLConverter.TARGET) ? nodeIdToKey : null;

                key_remap_src = edgeIdToKey;

                keyType = edgeKeyType.value;
            }

            if (!raw_rows) return;

            var data_column:Array = getPropertyArray(raw_rows, metadata[COLUMNNAME_META], data_remap_src);
            var key_column:Array = getPropertyArray(raw_rows, GraphMLConverter.ID, key_remap_src);

            /* TODO: Add type autodetection and proper handling of numeric types. */

            
            var key_vector:Vector.<IQualifiedKey> = new Vector.<IQualifiedKey>();
            var data_vector:Vector.<String> = new Vector.<String>(data_column);

            function setRecords():void
            {
                    var new_column:IAttributeColumn;
                    new_column = new StringColumn(metadata);
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

        private function handleNodeLayeringChange():void
        {
            var nodes:Array = nodeColumnData.getSessionState() as Array;
            if (!nodes) return;

            nodeLayers = partitionElements(nodes, nodeLayerPropertyName.value);
        }

        private function handleEdgeLayeringChange():void
        {
            var edges:Array = edgeColumnData.getSessionState() as Array;
            if (!edges) return;

            edgeLayers = partitionElements(edges, edgeLayerPropertyName.value);
        }

        private function handleNodeKeyPropertyChange():void
        {
            nodeKeyToId = {};
            nodeIdToKey = {};

            if (!handleKeyPropertyChange(nodeKeyPropertyName, nodeKeyToId, nodeIdToKey))
            {
                nodeKeyToId = null;
                nodeIdToKey = null;
            }

            return;
        }
        private function handleEdgeKeyPropertyChange():void
        {
            edgeKeyToId = {};
            edgeIdToKey = {};

            if (!handleKeyPropertyChange(edgeKeyPropertyName, edgeKeyToId, edgeIdToKey))
            {
                edgeKeyToId = null;
                edgeIdToKey = null;
            }

            return;
        }

        private function handleKeyPropertyChange(keyPropertyName:LinkableString, keyToIdMappings:Object, idToKeyMappings:Object):Boolean
        {
            var idx:int;
            var id:String;
            var value:String;
            var property:String = nodeKeyPropertyName.value;
            var nodes:Array = nodeColumnData.getSessionState() as Array;

            for (idx = nodes.length - 1; idx >= 0; idx--)
            {
                value = nodes[idx][property];
                id = nodes[idx][GraphMLConverter.ID];
                if (keyToIdMappings[value] !== undefined) return false;
                keyToIdMappings[value] = id;
                idToKeyMappings[id] = value;
            }            
            return true;
        }

        private function handleGraphMLNodesChange():void
        {
            handleNodeKeyPropertyChange();
            handleNodeLayeringChange();
        }

        private function handleGraphMLEdgesChange():void
        {
            handleEdgeKeyPropertyChange();
            handleEdgeLayeringChange();
        }

        private function testKeyUniqueness(objects:Array, propertyName:String):Boolean
        {
            var values:Object = {};
            var idx:int;
            for (idx = objects.length - 1; idx >= 0; idx--)
            {
                var value:String = objects[idx][propertyName];
                if (values[value])
                    return false;
                values[value] = true;
            }
            return true;
        }

        private function translateReferences(idToKeyMappings:Object, values:Array):Array
        {
            return values.map(function(item:String, idx:int, arr:Array):String { return idToKeyMappings[item]; });
        }

        private function partitionElements(elements:Array, propertyName:String):Object
        {
            var idx:int;
            var partitions:Object = {};
            var element:Object, partition:Object;

            for (idx = elements.length - 1; idx>=0; idx--)
            {
                element = elements[idx];

                if (partitions[element[propertyName]] === undefined)
                    partitions[element[propertyName]] = new Array();

                partition = partitions[element[propertyName]];
                
                partition.push(element[GraphMLConverter.ID]);
            }
            
            return partitions;
        }

        public function setFile(content:Object):void
        {
            var results:Object = GraphMLConverter.parse(content as XML);

            // Store results.nodeKeys and results.edgeKeys somewhere
            
            nodeProperties.setSessionState(results.nodeKeys);
            nodeColumnData.setSessionState(results.nodes);

            edgeProperties.setSessionState(results.edgeKeys);
            edgeColumnData.setSessionState(results.edges);
        }
    }
}

import weave.api.WeaveAPI;
import weave.api.data.ColumnMetadata;
import weave.api.data.DataTypes;
import weave.api.data.IDataSource;
import weave.api.data.IWeaveTreeNode;
import weave.api.data.IColumnReference;
import weave.data.DataSources.GraphMLDataSource;
import flare.data.converters.GraphMLConverter;

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
                new GraphMLGroupNode(this, GraphMLConverter.NODE, source.nodeLayerPropertyName.value),
                new GraphMLGroupNode(this, GraphMLConverter.NODE, source.edgeLayerPropertyName.value)
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
    private var _filterColumn:String;
    private var children:Array = null;
    
    public function get group():String
    {
        return _group;
    }
    public function get filterColumn():String
    {
        return _filterColumn;
    }
    public function get graph():GraphMLGraphNode
    {
        return _graph;
    }

    public function GraphMLGroupNode(graph:GraphMLGraphNode, group:String, filterColumn:String)
    {
        _graph = graph;
        _group = group;
        _filterColumn = filterColumn;
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
                this.filterColumn == that.filterColumn &&
                this.group == that.group;
    }

    public function isBranch():Boolean { return true; }

    public function hasChildBranches():Boolean { return true; }
    
    public function getChildren():Array 
    {
        if (children == null)
        {
            children = [];
            var layers:Array = isNodeGroup() ? graph.source.nodeLayerNames : graph.source.edgeLayerNames;
            for (var idx:int = layers.length - 1; idx >= 0; idx--)
            {
                children.push(new GraphMLLayerNode(this, layers[idx]));
            }
        }
        return children;
    }
    public function getLabel():String
    {
        return isNodeGroup() ? lang("Nodes") : lang("Edges");
    }
}

internal class GraphMLLayerNode implements IWeaveTreeNode 
{
    private var _group:GraphMLGroupNode;
    private var _filterValue:String;
    private var children:Array;

    public function get filterValue():String
    {
        return _filterValue;
    }
    public function get group():GraphMLGroupNode
    {
        return _group;
    }


    public function GraphMLLayerNode(group:GraphMLGroupNode, filterValue:String)
    {
        _group = group;
        _filterValue = filterValue;
    }

    public function equals(other:IWeaveTreeNode):Boolean
    {
        var that:GraphMLLayerNode = other as GraphMLLayerNode;
        return !!that && 
                this.group.equals(that.group) &&
                this._filterValue == that._filterValue;
    }

    public function isBranch():Boolean { return true; }
    public function hasChildBranches():Boolean { return true; }
    
    public function getChildren():Array 
    { 
        if (children == null)
        {
            children = [];
            var columns:Array = group.isNodeGroup() ? 
                group.graph.source.nodeProperties.getSessionState() as Array :
                group.graph.source.edgeProperties.getSessionState() as Array;

            for (var idx:int = columns.length - 1; idx >= 0; idx--)
            {
                children.push(new GraphMLColumnNode(this, columns[idx]));
            }
        }
        return children;
    }

    public function getLabel():String
    {
        return lang("Layer") + ": " + filterValue;
    }
}


internal class GraphMLColumnNode implements IWeaveTreeNode, IColumnReference {
    private var _layer:GraphMLLayerNode;
    private var _columnName:String;



    public function get layer():GraphMLLayerNode
    {
        return _layer;
    }
    public function get columnName():String
    {
        return _columnName;
    }

    public function GraphMLColumnNode(layer:GraphMLLayerNode, columnName:String)
    {
        this._layer = layer;
        this._columnName = columnName;
    }

    public function equals(other:IWeaveTreeNode):Boolean
    {
        var that:GraphMLColumnNode = other as GraphMLColumnNode;
        return !!that &&
                 this.layer.equals(that.layer) &&
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
        return layer.group.graph.source;
    }
    
    public function getColumnMetadata():Object 
    {
        var metadata:Object = {};

        metadata[GraphMLDataSource.COLUMNNAME_META] = columnName;
        metadata[GraphMLDataSource.FILTERVALUE_META] = layer.filterValue;
        metadata[GraphMLDataSource.FILTERCOLUMN_META] = layer.group.filterColumn;
        metadata[GraphMLDataSource.GROUP_META] = layer.group.group;

        return metadata;
    }
}