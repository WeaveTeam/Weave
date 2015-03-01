package weave.data.DataSources
{
    import flare.data.converters.GraphMLConverter;
    
    import flash.net.URLRequest;
    
    import mx.rpc.events.FaultEvent;
    import mx.rpc.events.ResultEvent;
    
    import weave.api.data.ColumnMetadata;
    import weave.api.data.DataType;
    import weave.api.data.IAttributeColumn;
    import weave.api.data.IDataSource;
    import weave.api.data.IDataSource_File;
    import weave.api.data.IQualifiedKey;
    import weave.api.data.IWeaveTreeNode;
    import weave.api.newLinkableChild;
    import weave.api.reportError;
    import weave.core.LinkableString;
    import weave.data.AttributeColumns.NumberColumn;
    import weave.data.AttributeColumns.ProxyColumn;
    import weave.data.AttributeColumns.StringColumn;
    import weave.data.QKeyManager;
    import weave.data.hierarchy.ColumnTreeNode;
    import weave.services.URLRequestUtils;
    import weave.services.addAsyncResponder;
    import weave.utils.VectorUtils;

    public class GraphMLDataSource extends AbstractDataSource implements IDataSource_File
    {
        WeaveAPI.ClassRegistry.registerImplementation(IDataSource, GraphMLDataSource, "GraphML file");

        
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

        [Bindable] public var nodeKeyPropertyValid:Boolean;
        [Bindable] public var edgeKeyPropertyValid:Boolean;

        public function GraphMLDataSource()
        {
        }

        /* Overrides from AbstractDataSource */

        override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
        {
            return new ColumnTreeNode({
                source: this,
                idFields: [GRAPH_GROUP_META, GRAPH_ID_META],
                columnMetadata: metadata
            });
        }

        private function handleURLChange():void
        {
			if (sourceUrl.value)
				addAsyncResponder(
	            	WeaveAPI.URLRequestUtils.getURL(this, new URLRequest(sourceUrl.value), URLRequestUtils.DATA_FORMAT_TEXT),
					handleGraphMLDownload,
					handleGraphMLDownloadError,
					sourceUrl.value
				);
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
            refreshHierarchy(); // this triggers callbacks
        }

        private function handleGraphMLDownloadError(event:FaultEvent, token:Object = null):void
        {
            reportError(event);
        }

        public function getColumnMetadata(group:String, id:String):Object
        {
            var is_node:Boolean = group == GraphMLConverter.NODE;
			var schema:Object = is_node ? nodeSchema : edgeSchema;
			if (!schema.hasOwnProperty(id))
				return null;
			
            var name:String = schema[id].name;
            var data_type:String = schema[id].type;
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

            var metadata:Object = {};
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
			if (!metadata)
			{
				proxyColumn.dataUnavailable();
				return;
			}

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

            (WeaveAPI.QKeyManager as QKeyManager).getQKeysAsync(proxyColumn, key_type, key_column, setRecords, key_vector);
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
            if (!_rootNode)
            {
                var source:GraphMLDataSource = this;

                _rootNode = new ColumnTreeNode({
                    source: source,
                    data: source,
                    label: WeaveAPI.globalHashMap.getName(this),
                    isBranch: true,
                    hasChildBranches: true,
                    children: function():Array {
                        return [GraphMLConverter.NODE, GraphMLConverter.EDGE].map(
                            function(group:String, ..._):Object {
                                return {
                                    source: source,
                                    data: group,
                                    label: group == GraphMLConverter.NODE ? "Nodes" : "Edges",
                                    isBranch: true,
                                    hasChildBranches: false,
                                    children: function ():Array {
                                        var groupProperties:Array = group == GraphMLConverter.NODE ? nodeProperties : edgeProperties;
                                        return groupProperties.map(
                                            function(field:String, ..._):* {
                                                var metadata:Object = {};
                                                metadata[ColumnMetadata.TITLE] = field;
                                                metadata[GRAPH_ID_META] = field;
                                                metadata[GRAPH_GROUP_META] = group;
                                                return generateHierarchyNode(metadata);
                                            }
                                        );
                                    }
                                }
                            }
                        );
                    }
                });
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