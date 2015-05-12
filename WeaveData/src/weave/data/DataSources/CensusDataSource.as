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
		
		public static const DATASET:String = "__CensusDataSource__dataSet";
		public static const CONCEPT_NAME:String = "__CensusDataSource__concept";
		public static const VARIABLE_NAME:String = "__CensusDataSource__variable";
		public static const FOR_GEOGRAPHY:String = "__CensusDataSource__geographyFor";
		public static const IN_GEOGRAPHY_PREFIX:String = "__CensusDataSource__inGeo#";
		private static const ALL_GEOGRAPHIES:String = "ALL";
		private static const CUSTOM_FILTER:String = "CUSTOM";
		
		[Embed(source="/weave/resources/county_fips_codes.amf", mimeType="application/octet-stream")]
		private static const CountyFipsDatabase:Class;
		
		public static var CountyFipsLookup:Object = null;
		
		[Embed(source="/weave/resources/state_fips_codes.amf", mimeType="application/octet-stream")]
		private static const StateFipsDatabase:Class;
		
		public static var StateFipsLookup:Object = null;
		private var api:CensusApi = newLinkableChild(this, CensusApi);

        public function CensusDataSource()
        {
			if (!CountyFipsLookup) initializeCountyFipsLookup();
			if (!StateFipsLookup) initializeStateFipsLookup();
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
								metadata[DATASET] = dataSet.identifier;
								metadata.label = dataSet.title;
								children.push(createDataSetNode(metadata));
							}
							//StandardLib.sortOn(children, function (obj:Object):String {return obj.data.label});
						}
					);
					return children;
				}
			});
		}

		public function createDataSetNode(data:Object):ColumnTreeNode
		{
			var _ds:IDataSource = this;
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
						for (var variableId:String in result)	
						{							
							var variableInfo:Object = result[variableId];
							var concept_node:Object = concept_nodes[variableInfo.concept];
							
							if (!concept_node)
							{
								concept_node = {
									dataSource: _ds,
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
								dataSource: _ds,
								data: ObjectUtil.copy(concept_node.data),
								label: variableInfo.label,
								idFields: [DATASET, CONCEPT_NAME, VARIABLE_NAME],
								hasChildBranches: true,
								children: createGeographyForNodes
							};
							
							variable_descriptor.data[VARIABLE_NAME] = variableId;
							
							concept_node.children.push(variable_descriptor);
						}
						for each (var concept_node:Object in concept_nodes)
						{
							StandardLib.sortOn(concept_node.children, function (obj:Object):String	{return obj.data[VARIABLE_NAME]}); 
						}
						StandardLib.sortOn(children, function (obj:Object):String {return obj.data[CONCEPT_NAME]});
					});
					return children;
				}
			});
		}
		public function createGeographyForNodes(node:ColumnTreeNode):Array
		{
			var children:Array = [];
			var _ds:IDataSource = this;
			api.getGeographies(node.data[DATASET]).then(
				function (result:Object):void
				{
					for (var geo_name:String in result)
					{
						var geography:Object = result[geo_name];
						var descriptor:Object = {
							dataSource: _ds, hasChildBranches: result[geo_name].requires,
							data: ObjectUtil.copy(node.data),
							label: geo_name,
							children: result[geo_name].requires && createGeographyInNodes,
							idFields: [DATASET, CONCEPT_NAME, VARIABLE_NAME, FOR_GEOGRAPHY]
						};
						descriptor.data[FOR_GEOGRAPHY] = geo_name;
						children.push(descriptor);
					}
					/* Sort by GeoLevelId */
					StandardLib.sortOn(children, function (obj:Object):String {return result[obj.data[FOR_GEOGRAPHY]].id;});
				}
			);
			
			return children;
		}
		public function createGeographyInNodes(node:ColumnTreeNode):Array
		{

			var children:Array = [];
			var _ds:IDataSource = this;
			api.getGeographies(node.data[DATASET]).then(
				function (result:Object):void
				{
					var for_geo:String = node.data[FOR_GEOGRAPHY];
					var requires:Array = result[for_geo].requires;
					var level:String = null;
					var is_leaf:Boolean = false;
					var descriptor:Object = {};
					var fips:String = null;
					
					
					/* Go to the first of the geometries that haven't been specified */
					if (requires)
					{
						for (var idx:int = 0; idx < requires.length; idx++)
						{
							var in_value:String = node.data[IN_GEOGRAPHY_PREFIX + requires[idx]];
							if (!in_value)
							{
								level = requires[idx];
								is_leaf = (idx + 1 == requires.length);
								break;
							}
						}
					}
					else
					{
						is_leaf = true;
					}
					
					if (level == "state")
					{
						for (fips in StateFipsLookup)
						{
							descriptor = {};
							descriptor.dataSource = _ds;
							descriptor.children = is_leaf ? null : createGeographyInNodes;
							descriptor.idFields = node.idFields.concat([IN_GEOGRAPHY_PREFIX+level]);
							descriptor.data = ObjectUtil.copy(node.data);
							descriptor.data[IN_GEOGRAPHY_PREFIX + level] = fips;
							descriptor.label = StateFipsLookup[fips];
							children.push(descriptor);
						}
					}
					else if (level == "county")
					{
						var state_fips:String = node.data[IN_GEOGRAPHY_PREFIX + "state"];
						for (fips in CountyFipsLookup[state_fips])
						{
							descriptor = {};
							descriptor.dataSource = _ds;
							descriptor.children = is_leaf ? null : createGeographyInNodes;
							descriptor.idFields = node.idFields.concat([IN_GEOGRAPHY_PREFIX+level]);
							descriptor.data = ObjectUtil.copy(node.data);
							descriptor.data[IN_GEOGRAPHY_PREFIX + level] = fips;
							descriptor.label = CountyFipsLookup[state_fips][fips];
							children.push(descriptor);
						}
					}
					descriptor = {};
					descriptor.dataSource = _ds;
					descriptor.children = null;
					descriptor.idFields = node.idFields.concat([IN_GEOGRAPHY_PREFIX+level]);
					descriptor.data = ObjectUtil.copy(node.data);
					descriptor.label = lang("All");
					children.push(descriptor);
					
					StandardLib.sortOn(children, function (obj:Object):String {return obj.data[IN_GEOGRAPHY_PREFIX+level];});
				}
			).then(null, reportError);
			return children;
		}
		
		private function columnLabelFunc(node:ColumnTreeNode):String
		{
			return null;	
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
			
			return new ColumnTreeNode({dataSource: this, idFields: [], data: metadata});
		}
        override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
        {   		
        	var metadata:Object = ColumnMetadata.getAllMetadata(proxyColumn);
        	
			api.getColumn(metadata, keyTypeOverride).then(
				function(columnInfo:Object):void
				{
					if (!columnInfo) return;
					var overrides:Object = keyTypeOverride.getSessionState();
					if (overrides && overrides[columnInfo.metadata[ColumnMetadata.KEY_TYPE]])
						columnInfo.metadata[ColumnMetadata.KEY_TYPE] = overrides[columnInfo.metadata[ColumnMetadata.KEY_TYPE]];
					
					proxyColumn.setMetadata(columnInfo.metadata);
					
					DataSourceUtils.initColumn(proxyColumn, columnInfo.keys, columnInfo.data);
				}
			);
        }
    }
}