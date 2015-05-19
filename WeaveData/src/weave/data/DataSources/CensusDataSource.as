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
		
		public static const CONCEPT_NAME:String = "__CensusDataSource__concept";
		public static const VARIABLE_NAME:String = "__CensusDataSource__variable";
		
		[Embed(source="/weave/resources/county_fips_codes.amf", mimeType="application/octet-stream")]
		private static const CountyFipsDatabase:Class;
		
		public static var CountyFipsLookup:Object = null;
		
		[Embed(source="/weave/resources/state_fips_codes.amf", mimeType="application/octet-stream")]
		private static const StateFipsDatabase:Class;
		
		public static var StateFipsLookup:Object = null;

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
		public const dataSet:LinkableString = registerLinkableChild(this, new LinkableString("2010acs5"));
		public const geographicScope:LinkableString = registerLinkableChild(this, new LinkableString("state"));
		public const geographicFilters:LinkableVariable = registerLinkableChild(this, new LinkableVariable(Object));
		private const api:CensusApi = newLinkableChild(this, CensusApi);

		public function createDataSetNode():ColumnTreeNode
		{
			var _ds:IDataSource = this;
			var name:String = WeaveAPI.globalHashMap.getName(this);
			var data:Object = {id:0, name: name};
			return new ColumnTreeNode({
				dataSource: this,
				data: data,
				label: data.label,
				hasChildBranches: true,
				children: function(node:ColumnTreeNode):Array {
					var children:Array = [];

					api.getVariables(dataSet.value).then(function (result:Object):void
					{
						var concept_nodes:Object = {};
						for (var variableId:String in result)	
						{							
							var variableInfo:Object = result[variableId];
							var concept_node:Object = concept_nodes[variableInfo.concept];
							
							
							if (!concept_node)
							{
								var concept_label:String = variableInfo.concept;
								if (!concept_label) concept_label = lang("No Concept");
								concept_node = {
									dataSource: _ds,
									data: ObjectUtil.copy(data),
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
								data: ObjectUtil.copy(concept_node.data),
								label: variableInfo.label,
								idFields: [CONCEPT_NAME, VARIABLE_NAME],
								children: null
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
		
		private function columnLabelFunc(node:ColumnTreeNode):String
		{
			return null;
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
					var overrides:Object = keyTypeOverride.getSessionState();
					if (overrides && overrides[columnInfo.metadata[ColumnMetadata.KEY_TYPE]])
						columnInfo.metadata[ColumnMetadata.KEY_TYPE] = overrides[columnInfo.metadata[ColumnMetadata.KEY_TYPE]];
					
					proxyColumn.setMetadata(columnInfo.metadata);
					
					DataSourceUtils.initColumn(proxyColumn, columnInfo.keys, columnInfo.data);
				}
			, reportError);
        }
    }
}