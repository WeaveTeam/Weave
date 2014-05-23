package weave.data.DataSources
{
    import flare.data.converters.GraphMLConverter;
    import weave.api.WeaveAPI;
    import weave.api.data.ColumnMetadata;
    import weave.api.data.DataTypes;
    import weave.api.data.IDataSource;
    import weave.api.data.IWeaveTreeNode;
    import weave.api.data.IColumnReference;
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

    public class GraphMLDataSource extends AbstractDataSource
    {
        WeaveAPI.registerImplementation(IDataSource, GraphMLDataSource, "GraphML file");

        public const nodeColumns:LinkableVariable = newLinkableChild(this, LinkableVariable, handleGraphMLDataChange);
        public const edgeColumns:LinkableVariable = newLinkableChild(this, LinkableVariable, handleGraphMLDataChange);
        public const nodeKeyColumnName:LinkableString = newLinkableChild(this, LinkableString, handleGraphMLDataChange);
        public const edgeLayerColumnName:LinkableString = newLinkableChild(this, LinkableString, handleGraphMLDataChange);

        private var _rootNode:IWeaveTreeNode;

        public function GraphMLDataSource()
        {   

        }

        public function handleGraphMLDataChange():void
        {

        }

        override public function getHierarchyRoot():IWeaveTreeNode
        {
            if (!(_rootNode is GraphMLSourceNode))
            {
                _rootNode = new GraphMLSourceNode(this, GraphMLSourceNode.GRAPH_NODETYPE, "");
            }
        }

        static public function transposeTable(table:Array, keys:Array):Object
        {
            var columns:Object = {};
            var table_length:int = table.length;
            for (var k_idx:int = keys.length;  k_idx >= 0; k_idx--)
            {
                var key:String = keys[k_idx];
                var column:Array = new Array(table_length);

                columns[key] = column;

                for (var idx:int = table_length; idx >= 0; idx--)
                {
                    column[idx] = table[idx][key];
                }
            }
            return columns;
        }

        public function setFile(content):void
        {
            var results:Object = GraphMLConverter.parse(content);

            nodeColumns.setSessionState(transposeTable(results.nodes, results.nodeKeys));
            edgeColumns.setSessionState(transposeTable(results.edges, results.edgeKeys));
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

internal class GraphMLSourceNode implements IWeaveTreeNode, IColumnReference {

    public const GRAPH_NODETYPE:int = 0;
    public const NODETABLE_NODETYPE:int = 1;
    public const NODECOLUMN_NODETYPE:int = 2;
    public const EDGETABLE_NODETYPE:int = 3;
    public const EDGECOLUMN_NODETYPE:int = 4;

    private var source:GraphMLDataSource;
    private var columnId:String;
    private var nodeType:int;

    public function GraphMLSourceNode(source:GraphMLDataSource, nodeType:int, columnId:String)
    {
        this.source = source;
        this.nodeType = nodeType;
        this.columnId = columnId;
    }

    public function equals(other:IWeaveTreeNode):Boolean
    {
        var that:GraphMLSourceNode = other as GraphMLSourceNode;
        return !!that && 
                this.source == that.source &&
                this.columnId == that.columnId;
    }

    public function isBranch():Boolean
    {
        return nodeType == NODETABLE_NODETYPE || nodeType == EDGETABLE_NODETYPE || nodeType == GRAPH_NODETYPE;
    }
    public function hasChildBranches():Boolean 
    {
        return nodeType == GRAPH_NODETYPE;
    }
    public function getChildren():Array 
    { 
        return [];
    }
    public function getLabel():String
    {
        return "";
    }

    public function getDataSource():IDataSource 
    { 
        return source; 
    }
    
    public function getColumnMetadata():Object 
    { 
        return {}; 
    }

}