/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell
    
    This file is a part of Weave.
    
    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.
    
    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package weave.data.Transforms
{
    import weave.api.core.ILinkableHashMap;
    import weave.api.data.ColumnMetadata;
    import weave.api.data.IAttributeColumn;
    import weave.api.data.IDataSource;
    import weave.api.data.IQualifiedKey;
    import weave.api.data.IWeaveTreeNode;
    import weave.api.detectLinkableObjectChange;
    import weave.api.newLinkableChild;
    import weave.api.registerLinkableChild;
    import weave.core.LinkableHashMap;
    import weave.data.AttributeColumns.DynamicColumn;
    import weave.data.AttributeColumns.EquationColumn;
    import weave.data.AttributeColumns.ProxyColumn;
    import weave.data.DataSources.AbstractDataSource;
    import weave.data.KeySets.StringDataFilter;
    import weave.data.hierarchy.ColumnTreeNode;
    import weave.utils.VectorUtils;

    public class ForeignDataMappingTransform extends AbstractDataSource
    {
        WeaveAPI.ClassRegistry.registerImplementation(IDataSource, ForeignDataMappingTransform, "Foreign Data Mapping Transform");

        public static const DATA_COLUMNNAME_META:String = "__DataColumnName__";

        public const keyColumn:DynamicColumn = newLinkableChild(this, DynamicColumn);
        public const dataColumns:ILinkableHashMap = registerLinkableChild(this, new LinkableHashMap(IAttributeColumn));
        

        public function ForeignDataMappingTransform()
        {
        }

        override protected function initialize():void
        {
            // recalculate all columns previously requested
            refreshAllProxyColumns();
            
            super.initialize();
        }
        
        override public function getHierarchyRoot():IWeaveTreeNode
        {
            if (!_rootNode)
            {
                var source:ForeignDataMappingTransform = this;
                var dataColumnNames:Array = [];
                
                _rootNode = new ColumnTreeNode({
                    source: source,
                    data: source,
                    label: WeaveAPI.globalHashMap.getName(this),
                    isBranch: true,
                    hasChildBranches: false,
                    children: function():Array {
                        if (detectLinkableObjectChange(_rootNode, dataColumns)) dataColumnNames = dataColumns.getNames();
                        return dataColumnNames.map(
                            function(dataColumnName:String, ..._):* {
                                var column:IAttributeColumn = dataColumns.getObject(dataColumnName) as IAttributeColumn;
                                var columnLabel:String = column.getMetadata(ColumnMetadata.TITLE);
                                var metadata:Object = {};
                                metadata[ColumnMetadata.TITLE] = columnLabel;
                                metadata[DATA_COLUMNNAME_META] = dataColumnName;
                                return generateHierarchyNode(metadata);
                            }
                        );
                    }
                });
            }
            return _rootNode;
        }

        override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
        {
            return new ColumnTreeNode({
                source: this,
                idFields: [DATA_COLUMNNAME_META],
                columnMetadata: metadata
            });
        }
        
        override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
        {

            var metadata:Object = proxyColumn.getProxyMetadata();
            var dataColumnName:String = metadata[DATA_COLUMNNAME_META];
            var dataColumn:IAttributeColumn = dataColumns.getObject(dataColumnName) as IAttributeColumn;
            var equationColumn:EquationColumn = new EquationColumn();

            equationColumn.variables.requestObjectCopy("keyColumn", keyColumn);
            equationColumn.variables.requestObjectCopy("dataColumn", dataColumn);
            equationColumn.metadata.value = metadata;
            equationColumn.filterByKeyType.value = true;
            equationColumn.equation.value = "return getValueFromKey(dataColumn, getKey(keyColumn));"

            proxyColumn.setInternalColumn(equationColumn);
        }
    }
}
