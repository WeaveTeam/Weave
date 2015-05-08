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
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    
    import mx.rpc.events.FaultEvent;
    import mx.utils.ObjectUtil;
    
    import weave.api.data.ColumnMetadata;
    import weave.api.data.IDataSource;
    import weave.api.data.IDataSource_Service;
    import weave.api.data.IWeaveTreeNode;
    import weave.api.newLinkableChild;
    import weave.api.registerLinkableChild;
    import weave.api.reportError;
    import weave.compiler.StandardLib;
    import weave.core.LinkableString;
    import weave.core.LinkableVariable;
    import weave.data.AttributeColumns.ProxyColumn;
    import weave.data.hierarchy.ColumnTreeNode;
    import weave.services.JsonCache;
    import weave.utils.DataSourceUtils;
    import weave.utils.VectorUtils;

    public class CensusDataSource extends AbstractDataSource implements IDataSource_Service
    {
        WeaveAPI.ClassRegistry.registerImplementation(IDataSource, CensusDataSource, "Census.gov");

        private static const baseUrl:String = "http://api.census.gov/";
		
		private static const DATASET:String = "__CensusDataSource__dataSet";
		private static const CONCEPT_NAME:String = "__CensusDataSource__concept";
		private static const VARIABLE_NAME:String = "__CensusDataSource__variable";
		private static const FOR_GEOGRAPHY:String = "__CensusDataSource__geographyFor";
		private static const IN_GEOGRAPHY_PREFIX:String = "__CensusDataSource__inGeo#";
		
		[Embed(source="/weave/resources/county_fips_codes.amf", mimeType="application/octet-stream")]
		private static const CountyFipsDatabase:Class;
		
		private static var CountyFipsLookup:Object = null;
		
		[Embed(source="/weave/resources/state_fips_codes.amf", mimeType="application/octet-stream")]
		private static const StateFipsDatabase:Class;
		
		private static var StateFipsLookup:Object = null;
		private var api:CensusApi = null;

        public function CensusDataSource()
        {
			if (!CountyFipsLookup) initializeCountyFipsLookup();
			if (!StateFipsLookup) initializeStateFipsLookup();
			api = new CensusApi();
        }
		
		private static function initializeStateFipsLookup():void
		{
			var ba:ByteArray = (new StateFipsDatabase()) as ByteArray;
			StateFipsLookup = ba.readObject();
		}
		private static function initializeCountyFipsLookup():void
		{
			var ba:ByteArray = (new CountyFipsDatabase()) as ByteArray;
			CountyFipsLookup = ba.readObject();
		}
		
        override protected function initialize():void
        {
            // recalculate all columns previously requested
            //refreshAllProxyColumns();
            
            super.initialize();
        }
        
		private const jsonCache:JsonCache = newLinkableChild(this, JsonCache);
		
		public const keyTypeOverride:LinkableVariable = newLinkableChild(this, LinkableVariable);
		public const apiKey:LinkableString = registerLinkableChild(this, new LinkableString(""));
		private var nodeCache:Object = {};

		public function createTopLevelNode():ColumnTreeNode
		{
			var name:String = WeaveAPI.globalHashMap.getName(this);
			var data:Object = {id:0, name: name};
			var children:Array = [];
			return new ColumnTreeNode({
				dataSource: this,
				data: data,
				label: data.name,
				hasChildBranches: true,
				children: function(node:ColumnTreeNode):Array {
					var children:Array = [];
					
					api.getDatasets().then(function (result:Object):void
						{
							for each (var dataSet:Object in result)
							{
								var metadata:Object = {};
								metadata[DATASET] = result.identifier;
								metadata.label = result.title;
								children.push(createDataSetNode(metadata));
							}
						}
					);
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
				idFields: [DATASET],
				hasChildBranches: true,
				children: function(node:ColumnTreeNode):Array {
					var children:Array = [];

					api.getVariables(data[DATASET]).then(function (result:Object):void
					{
						var concept_nodes:Object = {};
						for each (var variableInfo:Object in result)	
						{							
							var concept_node:Object = concept_nodes[variableInfo.concept];
							
							if (!concept_node)
							{
								concept_node = {
									dataSource: this,
									data: ObjectUtil.copy(data),
									label: variableInfo.concept,
									idFields: [DATASET, CONCEPT_NAME],
									hasChildBranches: true,
									children: []
								};
								
								concept_node.data[CONCEPT_NAME] = variableInfo.concept;
								
								children.push(concept_node);
								concept_nodes[variableInfo.concept] = concept_node;
							}
							
							var variable_descriptor:Object = {
								dataSource: this,
								data: ObjectUtil.copy(concept_node.data),
								label: variableInfo.label,
								idFields: [DATASET, CONCEPT_NAME, VARIABLE_NAME],
								hasChildBranches: true,
								children: createGeographyForNodes
							}
							
							variable_descriptor.data[VARIABLE_NAME] = variableInfo.id;
							
							concept_node.children.push(variable_descriptor);
						}
						for each (var concept_node:Object in concept_nodes)
						{
							StandardLib.sortOn(concept_node.children, function (obj:Object)	{return obj.data[VARIABLE_NAME]}); 
						}
						StandardLib.sortOn(children, function (obj:Object) {return obj.data[CONCEPT_NAME]});
					});
					return children;
				}
			});
		}
		public function createGeographyForNodes(node:ColumnTreeNode):Array
		{
			var children:Array = [];
			
			api.getGeographies(node.data[DATASET]).then(
				function (result:Object):void
				{
					for (var geo_name:String in result)
					{
						var geography:Object = result[geo_name];
						var descriptor:Object = {
							dataSource: this,
							data: ObjectUtil.copy(node.data),
							label: geo_name,
							children: createGeographyInNodes,
							idFields: [DATASET, CONCEPT_NAME, VARIABLE_NAME, FOR_GEOGRAPHY]
						};
						descriptor.data[FOR_GEOGRAPHY] = geo_name;
						children.push(descriptor);
					}
					/* Sort by GeoLevelId */
					StandardLib.sortOn(children, function (obj:Object) {return result[obj.data[FOR_GEOGRAPHY]].id;});
				}
			);
			
			return children;
		}
		public function createGeographyInNodes(node:ColumnTreeNode):Array
		{
			var children:Array = [];
			api.getGeographies(node.data[DATASET]).then(
				function (result:Object):void
				{
					var for_geo:String = node.data[FOR_GEOGRAPHY];
					var geo_names:String = VectorUtils.pluck(result, "name");
					var requires:Array = result[for_geo].requires;
					for (var idx:int = 0; idx < requires.length; idx++)
					{
						
					}
				}
			);
			return children;
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
		
		override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			if (!metadata)
				return null;
			
			return new ColumnTreeNode({
				dataSource: this,
				idFields: [],
				data: metadata
			});
		}
        
        override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
        {   
        	var metadata:Object = ColumnMetadata.getAllMetadata(proxyColumn);
        	
        	var web_service:String = metadata[null];
        	var geography_name:String = metadata[FOR_GEOGRAPHY];
        	var variable_name:String = metadata[VARIABLE_NAME];
        	var key_column_names:Array = null;
			

        	if (key_column_names)
        		key_column_names.push(geography_name);
        	else 
        		key_column_names = [geography_name];

        	var params:Object = {
        		get: variable_name,
        		"for": geography_name + ":*"
        	};

        	metadata[ColumnMetadata.KEY_TYPE] =  key_column_names.join("");

			jsonCache.getJsonPromise(proxyColumn, CensusApi.getUrl(web_service, params))
				.depend(keyTypeOverride)
				.then(function(result:Object):void {
					if (result == null)
						return;
					var idx:int;
					var columns:Array = result[0] as Array;
					var rows:Array = result as Array;
					var data_column:Array = new Array(rows.length - 1);
					var key_column:Array = new Array(rows.length - 1);
					var key_column_indices:Array = new Array(columns.length);
					var data_column_index:int = columns.indexOf(variable_name);
					
					var tmp_key_type:String = WeaveAPI.CSVParser.createCSVRow(key_column_names);
					var key_overrides:Object = keyTypeOverride.getSessionState();
					if (key_overrides && key_overrides[tmp_key_type])
					{
						tmp_key_type = key_overrides[tmp_key_type];
					}
					metadata[ColumnMetadata.KEY_TYPE] =  tmp_key_type;
					
					proxyColumn.setMetadata(metadata);
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
import org.apache.flex.promises.interfaces.IThenable;

import weave.api.newLinkableChild;
import weave.compiler.StandardLib;
import weave.services.JsonCache;
import weave.utils.VectorUtils;
import weave.utils.WeavePromise;

internal class CensusApi
{
	public static const BASE_URL:String = "http://api.census.gov/";
	private const jsonCache:JsonCache = newLinkableChild(this, JsonCache);
	
	public static function getUrl(serviceUrl:String, params:Object):String
	{
		var paramsStr:String = '';
		for (var key:String in params)
			paramsStr += (paramsStr ? '&' : '?');
		return serviceUrl + paramsStr;
	}
	
	public function CensusApi():void
	{
		
	}
	
	public function getDatasets():WeavePromise
	{
		return jsonCache.getJsonPromise(this, BASE_URL + "data.json");
	}
	
/* TODO: Add memoized promises for preprocessing steps */

	private function getDatasetPromise(dataSetIdentifier:String):IThenable
	{
		return getDatasets().then(
			function (result:Object):Object
			{
				var dataset:Object = null;
				for each (var tmp_dataset:Object in result)
				{
					if (tmp_dataset.identifier == dataSetIdentifier)
					{
						return dataset;
					}
				}
				throw new Error("No such dataset: " + dataSetIdentifier);
			}
		);
	}
	private function getVariablesPromise(dataSetIdentifier:String):IThenable
	{
		return getDatasetPromise(dataSetIdentifier).then(
			function (dataset:Object)
			{
				return jsonCache.getJsonPromise(this, dataset.c_variablesLink);
			}
		);
	}
	private function getGeographiesPromise(dataSetIdentifier:String):IThenable
	{
		return getDatasetPromise(dataSetIdentifier).then(
			function (dataset:Object)
			{
				return jsonCache.getJsonPromise(this, dataset.c_geographyLink);
			}
		);
	}
	
	public function getVariables(dataSetIdentifier:String):IThenable
	{
		return getVariablesPromise(dataSetIdentifier).then(
			function (result:Object)
			{
				delete result.variables["for"];
				delete result.variables["in"];
				
				var variable_list:Array = [];
				
				for (var key:String in result.variables)
				{
					result.variables[key].id = key;
					variable_list.push(result.variables[key]);
				}
				return variable_list;
			}
		);
	}

	public function getGeographies(dataSetIdentifier:String):IThenable
	{
		return getGeographiesPromise(dataSetIdentifier).then(
			function (result:Object)
			{
				var geo:Object = {};
				for each (var geo_description:Object in result.fips)
				{
					geo[geo_description.name] = {
						id: geo_description.geoLevelId,
						requires: geo_description.requires
					};
				}
				
				return geo;
			}
		);
	}
}