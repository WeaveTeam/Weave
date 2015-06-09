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
    import weave.api.data.ColumnMetadata;
    import weave.api.data.DataType;
    import weave.api.data.IAttributeColumn;
    import weave.api.data.IColumnReference;
    import weave.api.data.IDataSource;
    import weave.api.data.IDataSource_Service;
    import weave.api.data.IWeaveTreeNode;
    import weave.api.disposeObject;
    import weave.api.newLinkableChild;
    import weave.api.registerLinkableChild;
    import weave.core.LinkableString;
    import weave.data.AttributeColumns.ProxyColumn;
    import weave.data.hierarchy.ColumnTreeNode;
    import weave.services.JsonCache;

    public class FREDDataSource extends AbstractDataSource implements IDataSource_Service
    {
        WeaveAPI.ClassRegistry.registerImplementation(IDataSource, FREDDataSource, "Federal Reserve Economic Data");

		private const jsonCache:JsonCache = newLinkableChild(this, JsonCache);
		
		public const apiKey:LinkableString = registerLinkableChild(this, new LinkableString("fa99c080bdbd1d486a55e7cb6ab7acbb"));
		
		/**
		 * @param method Examples: "category", "category/series"
		 * @param params Example: {category_id: 125}
		 */
		private function getUrl(method:String, params:Object):String
		{
			params['api_key'] = apiKey.value;
			params['file_type'] = 'json';
			return JsonCache.buildURL("http://api.stlouisfed.org/fred/" + method, params);
		}
		/**
		 * @param method Examples: "category", "category/series"
		 * @param params Example: {category_id: 125}
		 */
		private function getJson(method:String, params:Object, resultHandler:Function, faultHandler:Function = null):void
		{
			jsonCache.getJsonObject(getUrl(method, params), resultHandler, faultHandler);
		}
		
		override protected function refreshHierarchy():void
		{
			for each (var csv:CSVDataSource in csvCache)
				disposeObject(csv);
			csvCache = {};
		}
		
		private var csvCache:Object = {};
		public function getObservationsCSV(series_id:String):CSVDataSource
		{
			var csv:CSVDataSource = csvCache[series_id];
			if (!csv)
			{
				csv = newLinkableChild(this, CSVDataSource);
				csvCache[series_id] = csv;
				
				var taskToken:Object = {};
				WeaveAPI.SessionManager.assignBusyTask(taskToken, csv);
				
				getJson('series', {series_id: series_id}, function(result1:Object):void {
					var seriesData:Object = result1.seriess[0];
					getJson('series/observations', {series_id: series_id}, function(result2:Object):void {
						WeaveAPI.SessionManager.unassignBusyTask(taskToken);
						var columnOrder:Array = ['date', 'value', 'realtime_start', 'realtime_end'];
						var rows:Array = WeaveAPI.CSVParser.convertRecordsToRows(result2.observations, columnOrder);
						csv.csvData.setSessionState(rows);
						csv.keyColName.value = 'date';
						csv.keyType.value = DataType.DATE;
						var valueTitle:String = lang("{0} ({1})", seriesData.title, seriesData.units);
						var metadataArray:Array = [
							{title: 'Date', dataType: DataType.DATE},
							{title: valueTitle, dataType: DataType.NUMBER},
							{title: 'realtime_start', dataType: DataType.DATE},
							{title: 'realtime_end', dataType: DataType.DATE},
						];
						csv.metadata.setSessionState(metadataArray);
					}, handleFault);
				}, handleFault);
				
				function handleFault(result:Object):void
				{
					WeaveAPI.SessionManager.unassignBusyTask(taskToken);
				}
			}
			return csv;
		}
		
		override public function getHierarchyRoot():IWeaveTreeNode
		{
			if (!_rootNode)
				_rootNode = createCategoryNode();
			return _rootNode;
		}
		
		public function createCategoryNode(data:Object = null):ColumnTreeNode
		{
			if (!data)
			{
				var name:String = WeaveAPI.globalHashMap.getName(this);
				data = {id: 0, name: name};
			}
			data[META_CATEGORY_ID] = data.id;
			return new ColumnTreeNode({
				dataSource: this,
				data: data,
				idFields: [META_CATEGORY_ID],
				label: data.name,
				hasChildBranches: true,
				children: function(node:ColumnTreeNode):Array {
					var children:Array = [];
					getJson('category/children', {category_id: node.data.id}, function(result:Object):void {
						var nodes:Array = [];
						for each (var item:Object in result.categories)
							nodes.push(createCategoryNode(item));
						// put categories first in the list
						children.splice.apply(null, [0, 0].concat(nodes));
					});
					getJson('category/series', {category_id: node.data.id}, function(result:Object):void {
						for each (var item:Object in result.seriess)
							children.push(createSeriesNode(item));
					});
					return children;
				}
			});
		}
		
		public function createSeriesNode(data:Object):IWeaveTreeNode
		{
			data[META_SERIES_ID] = data.id;
			return new ColumnTreeNode({
				dataSource: this,
				label: data.title,
				data: data,
				idFields: [META_SERIES_ID],
				hasChildBranches: false,
				children: function(node:ColumnTreeNode):Array {
					var csv:CSVDataSource = getObservationsCSV(data.id);
					var csvRoot:IWeaveTreeNode = csv.getHierarchyRoot();
					node.dependency = csv; // refresh children when csv triggers callbacks
					return csvRoot.getChildren().map(function(csvNode:IColumnReference, ..._):IWeaveTreeNode {
						var meta:Object = csvNode.getColumnMetadata();
						meta[META_SERIES_ID] = data.id;
						meta[META_COLUMN_NAME] = meta[CSVDataSource.METADATA_COLUMN_NAME];
						return generateHierarchyNode(meta);
					});
				}
			});
		}
		
		public static const META_CATEGORY_ID:String = 'FRED_category_id';
		public static const META_SERIES_ID:String = 'FRED_series_id';
		public static const META_COLUMN_NAME:String = 'FRED_column_name';
		
		override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			if (!metadata)
				return null;
			
			return new ColumnTreeNode({
				dataSource: this,
				idFields: [META_SERIES_ID, META_COLUMN_NAME],
				data: metadata
			});
		}
		
		//TODO - use http://api.stlouisfed.org/docs/fred/series_categories.html
		
        override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
        {
            var series:String = proxyColumn.getMetadata(META_SERIES_ID);
			//var columnName:String = proxyColumn.getMetadata(META_COLUMN_NAME);
			var csv:CSVDataSource = getObservationsCSV(series);
			var csvColumn:IAttributeColumn = csv.getAttributeColumn(ColumnMetadata.getAllMetadata(proxyColumn));
			proxyColumn.setInternalColumn(csvColumn);
        }
    }
}
