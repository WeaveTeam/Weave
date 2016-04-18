/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weavejs.data.source
{
    import weavejs.WeaveAPI;
    import weavejs.api.data.ColumnMetadata;
    import weavejs.api.data.IDataSource;
    import weavejs.api.data.IDataSource_Service;
    import weavejs.api.data.IWeaveTreeNode;
    import weavejs.core.LinkableString;
    import weavejs.core.LinkableVariable;
    import weavejs.data.DataSourceUtils;
    import weavejs.data.column.ProxyColumn;
    import weavejs.data.hierarchy.ColumnTreeNode;
    import weavejs.util.JS;
    import weavejs.util.StandardLib;

    public class CensusDataSource extends AbstractDataSource implements IDataSource_Service
    {
        WeaveAPI.ClassRegistry.registerImplementation(IDataSource, CensusDataSource, "Census.gov");

        private static const baseUrl:String = "http://api.census.gov/";
		
		public static const CONCEPT_NAME:String = "__CensusDataSource__concept";
		public static const VARIABLE_NAME:String = "__CensusDataSource__variable";
		


        public function CensusDataSource()
        {
        }
		
		override protected function initialize(forceRefresh:Boolean = false):void
        {
            // recalculate all columns previously requested
            //forceRefresh = true;
            
            super.initialize(forceRefresh);
        }
		
		public const keyType:LinkableString = Weave.linkableChild(this, LinkableString);
		public const apiKey:LinkableString = Weave.linkableChild(this, new LinkableString(""));
		public const dataSet:LinkableString = Weave.linkableChild(this, new LinkableString("http://api.census.gov/data/id/ACSSF2014"));
		public const geographicScope:LinkableString = Weave.linkableChild(this, new LinkableString("040"));
		public const geographicFilters:LinkableVariable = Weave.linkableChild(this, new LinkableVariable(Object));
		private const api:CensusApi = Weave.linkableChild(this, CensusApi);
		
		public function getAPI():CensusApi {return api;}

		public function createDataSetNode():ColumnTreeNode
		{
			var _ds:IDataSource = this;
			var name:String = getLabel();
			var data:Object = {id:0, name: name};
			var ctn:ColumnTreeNode = new ColumnTreeNode({
				dataSource: this,
				data: data,
				label: function():String { return dataSet.value || name; },
				hasChildBranches: true,
				children: function(node:ColumnTreeNode):Array {
					var children:Array = [];

					api.getVariables(dataSet.value).then(function (result:Object):void
					{
						var concept_nodes:Object = {};
						var concept_node:Object;
						for (var variableId:String in result)	
						{							
							var variableInfo:Object = result[variableId];
							concept_node = concept_nodes[variableInfo.concept];
							
							
							if (!concept_node)
							{
								var concept_label:String = variableInfo.concept;
								if (!concept_label) concept_label = Weave.lang("No Concept");
								concept_node = {
									dataSource: _ds,
									data: JS.copyObject(data),
									label: concept_label,
									idFields: [CONCEPT_NAME],
									hasChildBranches: false,
									children: []
								};
								
								concept_node.data[CONCEPT_NAME] = variableInfo.concept;
								
								children.push(concept_node);
								concept_nodes[variableInfo.concept] = concept_node;
							}
							
							var variable_descriptor:Object = {
								dataSource: _ds,
								data: JS.copyObject(concept_node.data),
								label: variableInfo.title,
								idFields: [CONCEPT_NAME, VARIABLE_NAME],
								children: null
							};
							
							variable_descriptor.data[VARIABLE_NAME] = variableId;
							
							concept_node.children.push(variable_descriptor);
						}
						for each (concept_node in concept_nodes)
						{
							StandardLib.sortOn(concept_node.children, function (obj:Object):String	{return obj.data[VARIABLE_NAME]}); 
						}
						StandardLib.sortOn(children, function (obj:Object):String {return obj.data[CONCEPT_NAME]});
					});
					return children;
				}
			});
			api.getDatasets().then(
				function (datasetsInfo:Object):void
				{
					for each (var dataset:Object in datasetsInfo.dataSet)
					{
						if (dataset.identifier == dataSet.value)
						{
							ctn.label = dataset.title;
							return;
						}
					}
					ctn.label = dataSet.value;
				}
			);
			return ctn;
		}
		
        override public function getHierarchyRoot():IWeaveTreeNode
        {
            if (!_rootNode)
                _rootNode = createDataSetNode();
            return _rootNode;
        }
		
		override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			if (!metadata)
				return null;
			var idFields:Array = [CONCEPT_NAME, VARIABLE_NAME];

			var ctn:ColumnTreeNode = new ColumnTreeNode({dataSource: this, idFields: idFields, data: metadata});
			return ctn; 
		}
		
        override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
        {
        	var metadata:Object = ColumnMetadata.getAllMetadata(proxyColumn);
        	
			api.getColumn(metadata).then(
				function(columnInfo:Object):void
				{
					if (!columnInfo) return;

					if (keyType.value)
						columnInfo.metadata[ColumnMetadata.KEY_TYPE] = keyType.value;
					
					proxyColumn.setMetadata(columnInfo.metadata);
					
					DataSourceUtils.initColumn(proxyColumn, columnInfo.keys, columnInfo.data);
				}
			);
        }
    }
}