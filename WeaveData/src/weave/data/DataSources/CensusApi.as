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
	
	import mx.utils.ObjectUtil;
	
	import weave.api.core.ILinkableObject;
	import weave.api.data.ColumnMetadata;
	import weave.api.getLinkableOwner;
	import weave.api.newLinkableChild;
	import weave.compiler.StandardLib;
	import weave.services.JsonCache;
	import weave.utils.VectorUtils;
	import weave.utils.WeavePromise;
	
	public class CensusApi implements ILinkableObject
	{
		public static const BASE_URL:String = "http://api.census.gov/";
		private const jsonCache:JsonCache = newLinkableChild(this, JsonCache);
		
		[Embed(source="/weave/resources/county_fips_codes.amf", mimeType="application/octet-stream")]
		private static const CountyFipsDatabase:Class;
		
		private static var CountyFipsLookup:Object = null;
		
		[Embed(source="/weave/resources/state_fips_codes.amf", mimeType="application/octet-stream")]
		private static const StateFipsDatabase:Class;
		
		private static var StateFipsLookup:Object = null;
		
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
		
		public static function get state_fips():Object
		{
			if (!StateFipsLookup) 
				initializeStateFipsLookup();
			return StateFipsLookup;
		}
		
		public static function get county_fips():Object
		{
			if (!CountyFipsLookup)
				initializeCountyFipsLookup();
			return CountyFipsLookup;
		}
		
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
			return getDatasets().then(
				function (result:Object):Object
				{
					if (!result || !result.dataset)
					{
						throw new Error("Malformed response from Census API.");
					}
					for each (var tmp_dataset:Object in result.dataset)
					{
						if (tmp_dataset.identifier == dataSetIdentifier)
						{
							return tmp_dataset;
						}
					}
					throw new Error("No such dataset: " + dataSetIdentifier);
				});
		}
		private function getVariablesPromise(dataSetIdentifier:String):WeavePromise
		{
			return getDatasetPromise(dataSetIdentifier).then(
				function (dataset:Object):WeavePromise
				{
					return jsonCache.getJsonPromise(_api, dataset.c_variablesLink);
				});
		}
		private function getGeographiesPromise(dataSetIdentifier:String):WeavePromise
		{
			return getDatasetPromise(dataSetIdentifier).then(
				function (dataset:Object):WeavePromise
				{
					return jsonCache.getJsonPromise(_api, dataset.c_geographyLink);
				});
		}
		
		public function getVariables(dataSetIdentifier:String):WeavePromise
		{
			return getVariablesPromise(dataSetIdentifier).then(
				function (result:Object):Object
				{
					var variablesInfo:Object = ObjectUtil.copy(result.variables);
					delete variablesInfo["for"];
					delete variablesInfo["in"];
					
					for (var key:String in variablesInfo)
					{
						var label:String = variablesInfo[key]['label'];
						var title:String = StandardLib.substitute('{0} ({1})', StandardLib.replace(label, '!!', '\u2014'), key);
						variablesInfo[key]['title'] = title;
					}
					
					return variablesInfo;
				});
		}
		
		public function getGeographies(dataSetIdentifier:String):WeavePromise
		{
			return getGeographiesPromise(dataSetIdentifier).then(
				function (result:Object):Object
				{
					var geo:Object = {};
					for each (var geo_description:Object in result.fips)
					{
						geo[geo_description.geoLevelId] = {
							id: geo_description.geoLevelId,
							name: geo_description.name,
							requires: geo_description.requires,
							optional: geo_description.optionalWithWCFor || []
						};
					}
					
					return geo;
				});
		}
		/**
		 * 
		 * @param metadata
		 * @return An object containing three fields, "keys," "values," and "metadata" 
		 */				
		public function getColumn(metadata:Object):WeavePromise
		{	
			var dataSource:CensusDataSource = getLinkableOwner(this) as CensusDataSource;
			var dataset_name:String;
			var geography_id:String;
			var geography_filters:Object;
			var api_key:String;
			
			var variable_name:String = metadata[CensusDataSource.VARIABLE_NAME];
			
			var params:Object = {};
			var title:String = null;
			var access_url:String = null;
			var filters:Array = [];
			var requires:Array = null;
			
			return new WeavePromise(this)
			.setResult(this)
			.depend(dataSource.dataSet)
			.then(
				function (context:Object):WeavePromise
				{
					dataset_name = dataSource.dataSet.value;
					return getDatasetPromise(dataset_name);
				}
			).then(
				function (datasetInfo:Object):WeavePromise
				{
					if (datasetInfo && 
						datasetInfo.distribution && 
						datasetInfo.distribution[0])
					{
						access_url = datasetInfo.distribution[0].accessURL;
					}

					if (!access_url)
					{
						throw new Error("Dataset distribution information malformed.");
					}

					return getVariables(dataset_name);
				}
			).then(
				function (variableInfo:Object):WeavePromise
				{
					title = variableInfo[variable_name].title;
					return getGeographies(dataset_name);
				}
			).depend(dataSource.geographicScope, dataSource.apiKey, dataSource.geographicFilters)
			.then(
				function (geographyInfo:Object):WeavePromise
				{
					if (geographyInfo == null) return null;
					geography_id = dataSource.geographicScope.value;
					geography_filters = dataSource.geographicFilters.getSessionState();
					api_key = dataSource.apiKey.value;
					requires = VectorUtils.copy(geographyInfo[geography_id].requires || []);
					requires.push(geographyInfo[geography_id].name);
					filters = [];
					for (var key:String in geography_filters)
					{
						filters.push(key + ":" + geography_filters[key]);
					}

					params["get"] = variable_name;
					params["for"] = geographyInfo[geography_id].name + ":*";
					
					if (filters.length != 0)
						params["in"] =  filters.join(",");
					
					if (api_key)
						params['key'] = api_key;

					return jsonCache.getJsonPromise(_api, getUrl(access_url, params));
				}
			).then(
				function (dataResult:Object):Object
				{
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
			);
		}
	}
}