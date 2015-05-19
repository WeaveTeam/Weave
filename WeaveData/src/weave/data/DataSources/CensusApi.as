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
	import mx.utils.ObjectUtil;
	
	import org.apache.flex.promises.interfaces.IThenable;
	
	import weave.api.core.ILinkableObject;
	import weave.api.data.ColumnMetadata;
	import weave.api.getLinkableOwner;
	import weave.api.newLinkableChild;
	import weave.api.reportError;
	import weave.compiler.StandardLib;
	import weave.core.LinkableString;
	import weave.services.JsonCache;
	import weave.utils.VectorUtils;
	import weave.utils.WeavePromise;
	
	public class CensusApi implements ILinkableObject
	{
		public static const BASE_URL:String = "http://api.census.gov/";
		private const jsonCache:JsonCache = newLinkableChild(this, JsonCache);
		
		private function get _api():CensusApi
		{
			return this;
		}
		
		private function getUrl(serviceUrl:String, params:Object):String
		{
			var paramsStr:String = '';
			for (var key:String in params)
				paramsStr += (paramsStr ? '&' : '?') + key + '=' + params[key];
			return serviceUrl + paramsStr;
		}
		
		public function CensusApi():void
		{
		}
		
		public function getDatasets():WeavePromise
		{
			return jsonCache.getJsonPromise(_api, BASE_URL + "data.json");
		}
		
		/* TODO: Add memoized promises for preprocessing steps */
		
		private function getDatasetPromise(dataSetIdentifier:String):WeavePromise
		{
			return getDatasets().thenAgain(
				function (result:Object):Object
				{
					weaveTrace("getDataSetPromise", dataSetIdentifier);
					for each (var tmp_dataset:Object in result)
					{
						if (tmp_dataset.identifier == dataSetIdentifier)
						{
							return tmp_dataset;
						}
					}
					weaveTrace("getDataSetPromise failed, no such dataset:", dataSetIdentifier);
					throw new Error("No such dataset: " + dataSetIdentifier);
				}, reportError
			);
		}
		private function getVariablesPromise(dataSetIdentifier:String):WeavePromise
		{
			return getDatasetPromise(dataSetIdentifier).thenAgain(
				function (dataset:Object):IThenable
				{
					return jsonCache.getJsonPromise(_api, dataset.c_variablesLink);
				}
			, reportError);
		}
		private function getGeographiesPromise(dataSetIdentifier:String):WeavePromise
		{
			return getDatasetPromise(dataSetIdentifier).thenAgain(
				function (dataset:Object):IThenable
				{
					return jsonCache.getJsonPromise(_api, dataset.c_geographyLink);
				}
			, reportError);
		}
		
		public function getVariables(dataSetIdentifier:String):WeavePromise
		{
			return getVariablesPromise(dataSetIdentifier).thenAgain(
				function (result:Object):Object
				{
					var variableInfo:Object = ObjectUtil.copy(result.variables);
					delete variableInfo["for"];
					delete variableInfo["in"];
					
					return variableInfo;
				}
			, reportError);
		}
		
		public function getGeographies(dataSetIdentifier:String):WeavePromise
		{
			return getGeographiesPromise(dataSetIdentifier).thenAgain(
				function (result:Object):Object
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
			, reportError);
		}
		
		/**
		 * 
		 * @param metadata
		 * @return An object containing three fields, "keys," "values," and "metadata" 
		 */				
		public function getColumn(metadata:Object):IThenable
		{	
			var dataSource:CensusDataSource = getLinkableOwner(this) as CensusDataSource;
			var dataset_name:String;
			var geography_name:String;
			var geography_filters:Object;
			var api_key:String;
			
			var variable_name:String = metadata[CensusDataSource.VARIABLE_NAME];
			
			var params:Object = {};
			var title:String = null;
			var service_url:String = null;
			var filters:Array = [];
			var requires:Array = null;
			
			return new WeavePromise(this).depend(dataSource.dataSet, dataSource.geographicScope, dataSource.apiKey, dataSource.geographicFilters)
			.thenAgain(
				function (context:Object):IThenable
				{
					weaveTrace("Calling getDataSetPromise");
					dataset_name = dataSource.dataSet.value;
					return getDatasetPromise(dataset_name);
				}
			, reportError).thenAgain(
				function (datasetInfo:Object):IThenable
				{
					weaveTrace("Calling getVariables", dataset_name);
					service_url = datasetInfo.webService;
					return getVariables(dataset_name);
				}
			, reportError).thenAgain(
				function (variableInfo:Object):IThenable
				{
					weaveTrace("Calling getGeographies", dataset_name);
					title = variableInfo[variable_name].label;
					return getGeographies(dataset_name);	
				}
			, reportError).thenAgain(
				function (geographyInfo:Object):IThenable
				{
					
					geography_name = dataSource.geographicScope.value;
					geography_filters = dataSource.geographicFilters.getSessionState();
					api_key = dataSource.apiKey.value;
					requires = VectorUtils.copy(geographyInfo[geography_name].requires || []);
					requires.push(geography_name);
					
					for (var key:String in geography_filters)
					{
						filters.push(key + ":" + geography_filters[key]);
					}

					params["get"] = variable_name;
					params["for"] = geography_name + ":*"
					
					if (filters.length != 0) params["in"] =  filters.join(",")
					
					if (api_key) params['key'] = api_key;
					
					weaveTrace("Building query and issuing Json request", dataset_name, geography_name);
					
					return jsonCache.getJsonPromise(_api, getUrl(service_url, params));
				}
			, reportError).thenAgain(
				function (dataResult:Object):Object
				{
					weaveTrace("Building column info", dataset_name, geography_name);
					if (dataResult == null)
						return null;
					var idx:int;
					var columns:Array = dataResult[0] as Array;
					var rows:Array = dataResult as Array;
					var data_column:Array = new Array(rows.length - 1);
					var key_column:Array = new Array(rows.length - 1);
					var key_column_indices:Array = new Array(columns.length);
					var data_column_index:int = columns.indexOf(variable_name);
					
					var tmp_key_type:String = WeaveAPI.CSVParser.createCSVRow(requires);
					
					

					metadata[ColumnMetadata.KEY_TYPE] = tmp_key_type;
					metadata[ColumnMetadata.TITLE] = title;
					for (idx = 0; idx < requires.length; idx++)
					{
						key_column_indices[idx] = columns.indexOf(requires[idx]);
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
					
					return {
						keys: key_column,
						data: data_column,
						metadata: metadata
					};
				}
			, reportError);
		}
	}
}