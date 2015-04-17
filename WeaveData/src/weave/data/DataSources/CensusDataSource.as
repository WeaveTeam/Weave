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

package weave.data.DataSources
{
    import mx.rpc.events.FaultEvent;
    
    import weave.api.data.ColumnMetadata;
    import weave.api.data.IDataSource;
    import weave.api.data.IDataSource_Service;
    import weave.api.data.IWeaveTreeNode;
    import weave.api.newLinkableChild;
    import weave.api.registerLinkableChild;
    import weave.api.reportError;
    import weave.compiler.Compiler;
    import weave.compiler.StandardLib;
    import weave.core.LinkableString;
    import weave.data.AttributeColumns.ProxyColumn;
    import weave.data.hierarchy.ColumnTreeNode;
    import weave.services.JsonCache;
    import weave.utils.DataSourceUtils;
    import weave.utils.VectorUtils;

    public class CensusDataSource extends AbstractDataSource implements IDataSource_Service
    {
        WeaveAPI.ClassRegistry.registerImplementation(IDataSource, CensusDataSource, "Census.gov Data Source");

        private static const baseUrl:String = "http://api.census.gov/";

        private static const DATA_URL:String = "__CensusDataSource__dataUrl";
        private static const VARIABLES_DATA:String = "__CensusDataSource__variablesData";
        private static const GEOGRAPHY_DATA:String = "__CensusDataSource__geographyData";


        private static const GEOGRAPHY_LINK:String = "__CensusDataSource__geographyLink";
        private static const VARIABLES_LINK:String = "__CensusDataSource__variablesLink";

        private static const GEOGRAPHY_REQUIRES:String = "__CensusDataSource__geographyRequires";
        private static const GEOGRAPHY_NAME:String = "__CensusDataSource__geographyName";
        private static const GEOGRAPHY_LEVEL_ID:String = "__CensusDataSource__geoLevelId";
        private static const VARIABLE_NAME:String = "__CensusDataSource__variableName";

        private static const WEB_SERVICE:String = "__CensusDataSource__webService";

        private static const META_ID_FIELDS:Array = [WEB_SERVICE, GEOGRAPHY_NAME, VARIABLE_NAME, GEOGRAPHY_REQUIRES];

        public function CensusDataSource()
        {
        }

		
		
        override protected function initialize():void
        {
            // recalculate all columns previously requested
            //refreshAllProxyColumns();
            
            super.initialize();
        }
        
		private const jsonCache:JsonCache = newLinkableChild(this, JsonCache);
		
		public const keyTypeOverride:LinkableString = newLinkableChild(this, LinkableString);
		public const apiKey:LinkableString = registerLinkableChild(this, new LinkableString(""));
		private var nodeCache:Object = {};
		
		/**
		 * @param method Examples: "category", "category/series"
		 * @param params Example: {category_id: 125}
		 */
		private function getUrl(serviceUrl:String, params:Object):String
		{
			//params['api_key'] = apiKey.value;
			//params['file_type'] = 'json';
			var paramsStr:String = '';
			for (var key:String in params)
				paramsStr += (paramsStr ? '&' : '?') + key + '=' + params[key];
			return serviceUrl + paramsStr;
		}
		/**
		 * @param method Examples: "category", "category/series"
		 * @param params Example: {category_id: 125}
		 */
		private function getJson(method:String, params:Object, handler:Function):void
		{
			jsonCache.getJsonObject(getUrl(method, params), handler);
		}

		public function createTopLevelNode():ColumnTreeNode
		{
			var name:String = WeaveAPI.globalHashMap.getName(this);
			var data:Object = {id:0, name: name};
			var children:Array = [];
			return new ColumnTreeNode({
				dataSource: this,
				data: data,
				label: data.name,
				isBranch: true,
				hasChildBranches: true,
				children: function(node:ColumnTreeNode):Array {
					jsonCache.getJsonObject(baseUrl+"data.json", function(result:Object):void
						{
							data.result = result;
							for each (var dataSet:Object in result)
							{
								var metadata:Object = {};
								metadata[GEOGRAPHY_LINK] = dataSet.c_geographyLink;
								metadata[VARIABLES_LINK] = dataSet.c_variablesLink;
								metadata[WEB_SERVICE] = dataSet.webService;
								metadata.label = dataSet.title;
								children.push(createDataSetNode(metadata));
							} 
						});
					return children;
				}
			});
		}

		public function createDataSetNode(data:Object):ColumnTreeNode
		{
			return new ColumnTreeNode({
				dataSource: this,
				data: data,
				label: data.label,
				isBranch: true,
				hasChildBranches: true,
				children: function(node:ColumnTreeNode):Array {
					var children:Array = [];

					jsonCache.getJsonObject(data[GEOGRAPHY_LINK], function(result:Object):void
						{
							data.cache = result;
							for each (var geography:Object in result.fips)
							{
								var metadata:Object = {};
								metadata[VARIABLES_LINK] = data[VARIABLES_LINK];
								metadata[WEB_SERVICE] = data[WEB_SERVICE];
								metadata[GEOGRAPHY_REQUIRES] = WeaveAPI.CSVParser.createCSVRow(geography.requires || []);
								metadata[GEOGRAPHY_NAME] = geography.name;
								metadata[GEOGRAPHY_LEVEL_ID] = geography.geoLevelId;
								children.push(createGeographyNode(metadata));
							}
							StandardLib.sortOn(children, function (obj:Object):String { return obj.data[GEOGRAPHY_LEVEL_ID]; });
						}
					);

					
					return children;
				}
			});
		}

		public function createGeographyNode(data:Object):ColumnTreeNode
		{
			return new ColumnTreeNode({
				dataSource: this,
				data: data,
				label: data[GEOGRAPHY_NAME],
				isBranch: true,
				hasChildBranches: true,
				children: function (node:ColumnTreeNode):Array {
					const children:Array = [];
					jsonCache.getJsonObject(data[VARIABLES_LINK], function(result:Object):void
						{
							data.cache = result;
							var key:String;
							var concepts:Object = {};
							/* Build a hierarchy out of 'concepts', roughly speaking, tables. */
							for (key in result.variables)
							{
								if (key == "for" || key == "in") continue;
								var column:Object = result.variables[key];

								var concept_name:String = column.concept || null;

								concepts[concept_name] = concepts[concept_name] || {};

								

								var metadata:Object = {};
								metadata[WEB_SERVICE] = data[WEB_SERVICE];
								metadata[GEOGRAPHY_NAME] = data[GEOGRAPHY_NAME];
								metadata[GEOGRAPHY_REQUIRES] = data[GEOGRAPHY_REQUIRES];
								metadata[VARIABLE_NAME] = key;
								metadata.label = column.label;
								concepts[concept_name][key] = metadata;
							}

							for (key in concepts)
							{
								children.push(createConceptNode({
									variables: concepts[key],
									name: key
								}));
							}
							StandardLib.sortOn(children, "label");
						}
						);
					return children;
				}
			})
		}

		public function createConceptNode(data:Object):ColumnTreeNode
		{
			return new ColumnTreeNode({
				dataSource: this,
				data: data,
				label: data.name || "No Table",
				isBranch: true,
				hasChildBranches: false,
				children: function (node:ColumnTreeNode):Array {
					var children:Array = [];
					for (var key:String in node.data.variables)
					{
						children.push(createVariableNode(node.data.variables[key]));
					}
					//StandardLib.sortOn(children, "label");
					return children;
				}
			});
		}


		public function createVariableNode(data:Object):ColumnTreeNode
		{
			return setIndexedNode(data, new ColumnTreeNode({
				dataSource: this,
				columnMetadata: data,
				label: data.label,
				isBranch: false,
				hasChildBranches: false
			}));
		}

		private function handleFault(event:FaultEvent, token:Object = null):void
		{
			reportError(event);
		}
		
        override public function getHierarchyRoot():IWeaveTreeNode
        {
            if (!_rootNode)
                _rootNode = createTopLevelNode();
            return _rootNode;
        }

        private var _indexedNodes:Object = {};
        private function setIndexedNode(metadata:Object, node:IWeaveTreeNode):ColumnTreeNode
        {
        	var key:String = Compiler.stringify(VectorUtils.getItems(metadata, META_ID_FIELDS));
        	return _indexedNodes[key] = node;
        }
        private function getIndexedNode(metadata:Object):ColumnTreeNode
        {
        	var key:String = Compiler.stringify(VectorUtils.getItems(metadata, META_ID_FIELDS));
        	return _indexedNodes[key];
        }
		
		override public function findHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			return getIndexedNode(metadata);
		}
		
		override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			if (!metadata)
				return null;
			
			return new ColumnTreeNode({
				dataSource: this,
				idFields: META_ID_FIELDS,
				columnMetadata: metadata
			});
		}
        
        override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
        {   
        	var metadata:Object = ColumnMetadata.getAllMetadata(proxyColumn);
        	
        	var web_service:String = metadata[WEB_SERVICE];
        	var geography_name:String = metadata[GEOGRAPHY_NAME];
        	var variable_name:String = metadata[VARIABLE_NAME];
        	var key_column_names:Array = WeaveAPI.CSVParser.parseCSVRow(metadata[GEOGRAPHY_REQUIRES]);

        	if (key_column_names)
        		key_column_names.push(geography_name);
        	else 
        		key_column_names = [geography_name];

        	var params:Object = {
        		get: variable_name,
        		"for": geography_name + ":*"
        	};

        	metadata[ColumnMetadata.KEY_TYPE] =  key_column_names.join(0);

        	proxyColumn.setMetadata(metadata);
        	
        	jsonCache.getJsonObject(getUrl(web_service, params), function(result:Object):void
        	{
				var idx:int;
        		var columns:Array = result[0] as Array;
        		var rows:Array = result as Array;
        		var data_column:Array = new Array(rows.length - 1);
        		var key_column:Array = new Array(rows.length - 1);
        		var key_column_indices:Array = new Array(columns.length);
        		var data_column_index:int = columns.indexOf(variable_name);
        		for (idx = 0; idx < key_column_names.length; idx++)
        		{
        			key_column_indices[idx] = columns.indexOf(key_column_names[idx]);
        		}
        		for (var row_idx:int = 0; row_idx < data_column.length; row_idx++)
        		{
        			var row:Array = rows[row_idx+1];
        			var key_values:Array = new Array(key_column_indices.length);

        			for (idx = 0; idx < key_column_indices.length; idx++)
        			{
        				key_values[idx] = row[key_column_indices[idx]];
        			}
        			key_column[row_idx] = key_values.join("");
        			data_column[row_idx] = row[data_column_index];
        		}
        		DataSourceUtils.initColumn(proxyColumn, key_column, data_column);
        	});
        }
    }
}